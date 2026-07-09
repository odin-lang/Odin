// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#include "parallel_for.h"

#include "core.h"
#include "physics_world.h"
#include "platform.h"

#include "box3d/base.h"
#include "box3d/constants.h"

#include <stddef.h>

// Shared state for one b3ParallelFor invocation. Workers race on nextBlock to
// claim work, so a slow chunk can't strand the other threads.
typedef struct b3ParallelForShared
{
	b3AtomicInt nextBlock;
	int blockCount;
	int blockSize;
	int itemCount;
	b3ParallelForCallback* callback;
	void* context;
} b3ParallelForShared;

typedef struct b3ParallelForTask
{
	b3ParallelForShared* shared;
	int workerIndex;
} b3ParallelForTask;

static void b3ParallelForTrampoline( void* taskContext )
{
	b3ParallelForTask* task = (b3ParallelForTask*)taskContext;
	b3ParallelForShared* shared = task->shared;
	int workerIndex = task->workerIndex;
	void* context = shared->context;
	b3ParallelForCallback* callback = shared->callback;

	int blockCount = shared->blockCount;
	int blockSize = shared->blockSize;
	int itemCount = shared->itemCount;

	for ( ;; )
	{
		int blockIndex = b3AtomicFetchAddInt( &shared->nextBlock, 1 );
		if ( blockIndex >= blockCount )
		{
			break;
		}

		int start = blockIndex * blockSize;
		int end = start + blockSize;
		if ( end > itemCount )
		{
			end = itemCount;
		}

		callback( start, end, workerIndex, context );
	}
}

void b3ParallelFor( b3World* world, b3ParallelForCallback* callback, int itemCount, int minRange, void* context,
					const char* name )
{
	if ( itemCount <= 0 )
	{
		return;
	}

	B3_ASSERT( minRange > 0 );

	int workerCount = world->workerCount;
	B3_ASSERT( 0 < workerCount && workerCount <= B3_MAX_WORKERS );

	// Target multiple blocks per worker to reduce thread stalls.
	// block size grows once items exceed maxBlockCount * minRange
	// so the block count stays bounded and per-block sync overhead stays low.
	int blocksPerWorker = 4;
	int maxBlockCount = blocksPerWorker * workerCount;

	int blockSize;
	int blockCount;
	if ( itemCount <= minRange * maxBlockCount )
	{
		blockSize = minRange;
		blockCount = ( itemCount + blockSize - 1 ) / blockSize;
	}
	else
	{
		blockSize = ( itemCount + maxBlockCount - 1 ) / maxBlockCount;
		blockCount = ( itemCount + blockSize - 1 ) / blockSize;
	}
	B3_ASSERT( blockCount >= 1 );
	B3_ASSERT( blockSize * blockCount >= itemCount );

	// No point enqueueing more tasks than blocks.
	int taskCount = workerCount < blockCount ? workerCount : blockCount;

	b3ParallelForShared shared;
	shared.blockCount = blockCount;
	shared.blockSize = blockSize;
	shared.itemCount = itemCount;
	shared.callback = callback;
	shared.context = context;
	b3AtomicStoreInt( &shared.nextBlock, 0 );

	b3ParallelForTask tasks[B3_MAX_WORKERS];
	void* handles[B3_MAX_WORKERS];
	for ( int i = 0; i < taskCount; ++i )
	{
		tasks[i].shared = &shared;
		tasks[i].workerIndex = i;

		if (world->taskCount < B3_MAX_TASKS)
		{
			handles[i] = world->enqueueTaskFcn( &b3ParallelForTrampoline, tasks + i, world->userTaskContext, name );
			world->taskCount += 1;
		}
		else
		{
			handles[i] = NULL;
			b3ParallelForTrampoline( tasks + i );
		}
	}

	for ( int i = 0; i < taskCount; ++i )
	{
		if ( handles[i] != NULL )
		{
			world->finishTaskFcn( handles[i], world->userTaskContext );
		}
	}
}
