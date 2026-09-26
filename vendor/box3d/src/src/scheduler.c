// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#include "platform.h"
#include "core.h"
#include "scheduler.h"

#include "box3d/base.h"
#include "box3d/constants.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

enum b3SchedulerTaskStatus
{
	b3_schedulerFree = 0,
	b3_schedulerPending = 1,
	b3_schedulerClaimed = 2,
	b3_schedulerComplete = 3,
};

typedef struct b3SchedulerTask
{
	b3TaskCallback* callback;
	void* taskContext;
	b3AtomicInt status;
} b3SchedulerTask;

typedef struct b3SchedulerWorkerContext
{
	struct b3Scheduler* scheduler;
	int threadIndex;
} b3SchedulerWorkerContext;

typedef struct b3Scheduler
{
	b3Thread* threads[B3_MAX_WORKERS];
	b3SchedulerWorkerContext workerContexts[B3_MAX_WORKERS];

	// total workers including main thread
	int workerCount;

	// threads created = workerCount - 1
	int threadCount;

	b3SchedulerTask tasks[B3_MAX_TASKS];
	b3AtomicInt nextSlot;

	b3Semaphore* taskSemaphore;
	b3AtomicInt shutdown;
} b3Scheduler;

// Try to claim and execute one pending task.
// Returns true if work was performed, false otherwise.
static bool b3SchedulerExecuteOne( b3Scheduler* scheduler )
{
	int taskCount = b3AtomicLoadInt( &scheduler->nextSlot );
	for ( int t = 0; t < taskCount; ++t )
	{
		b3SchedulerTask* task = scheduler->tasks + t;
		if ( b3AtomicLoadInt( &task->status ) != b3_schedulerPending )
		{
			continue;
		}

		if ( b3AtomicCompareExchangeInt( &task->status, b3_schedulerPending, b3_schedulerClaimed ) == false )
		{
			continue;
		}

		task->callback( task->taskContext );

		b3AtomicStoreInt( &task->status, b3_schedulerComplete );
		return true;
	}

	return false;
}

// Background worker thread entry point.
static void b3SchedulerWorkerMain( void* context )
{
	b3SchedulerWorkerContext* workerContext = context;
	b3Scheduler* scheduler = workerContext->scheduler;

	while ( true )
	{
		b3WaitSemaphore( scheduler->taskSemaphore );

		if ( b3AtomicLoadInt( &scheduler->shutdown ) != 0 )
		{
			break;
		}

		// Claim and execute all available work
		while ( b3SchedulerExecuteOne( scheduler ) )
		{
		}
	}
}

b3Scheduler* b3CreateScheduler( int workerCount )
{
	B3_ASSERT( 0 < workerCount && workerCount <= B3_MAX_WORKERS );

	b3Scheduler* scheduler = b3Alloc( sizeof( b3Scheduler ) );
	memset( scheduler, 0, sizeof( b3Scheduler ) );

	scheduler->workerCount = workerCount;
	int threadCount = workerCount - 1;
	scheduler->threadCount = threadCount;
	scheduler->taskSemaphore = b3CreateSemaphore( 0 );
	b3AtomicStoreInt( &scheduler->shutdown, 0 );
	b3AtomicStoreInt( &scheduler->nextSlot, 0 );

	// Background threads use indices 1..workerCount-1.
	// Main thread uses index 0.
	for ( int i = 0; i < threadCount; ++i )
	{
		scheduler->workerContexts[i].scheduler = scheduler;
		scheduler->workerContexts[i].threadIndex = i + 1;

		char name[16];
		snprintf( name, sizeof( name ), "box2d_worker_%02d", i + 1 );
		scheduler->threads[i] = b3CreateThread( b3SchedulerWorkerMain, scheduler->workerContexts + i, name );
	}

	return scheduler;
}

void b3DestroyScheduler( b3Scheduler* scheduler )
{
	b3AtomicStoreInt( &scheduler->shutdown, 1 );

	// Wake all background threads so they see the shutdown flag
	for ( int i = 0; i < scheduler->threadCount; ++i )
	{
		b3SignalSemaphore( scheduler->taskSemaphore );
	}

	for ( int i = 0; i < scheduler->threadCount; ++i )
	{
		b3JoinThread( scheduler->threads[i] );
		scheduler->threads[i] = NULL;
	}

	b3DestroySemaphore( scheduler->taskSemaphore );
	b3Free( scheduler, sizeof( b3Scheduler ) );
}

void b3ResetScheduler( b3Scheduler* scheduler )
{
	b3AtomicStoreInt( &scheduler->nextSlot, 0 );
}

void* b3SchedulerEnqueueTask( b3TaskCallback* task, void* taskContext, void* userContext, const char* name )
{
	B3_UNUSED( name );
	b3Scheduler* scheduler = userContext;

	int slot = b3AtomicFetchAddInt( &scheduler->nextSlot, 1 );
	B3_ASSERT( slot < B3_MAX_TASKS );

	b3SchedulerTask* schedulerTask = scheduler->tasks + slot;
	schedulerTask->callback = task;
	schedulerTask->taskContext = taskContext;

	// Memory fence: status must be published after callback and context are written
	b3AtomicStoreInt( &schedulerTask->status, b3_schedulerPending );

	// One wake per enqueue is enough: at most one worker picks up each task.
	b3SignalSemaphore( scheduler->taskSemaphore );

	return schedulerTask;
}

void b3SchedulerFinishTask( void* userTask, void* userContext )
{
	if ( userTask == NULL )
	{
		return;
	}

	b3Scheduler* scheduler = userContext;
	b3SchedulerTask* waitTask = userTask;

	// Main thread helps execute any available work while waiting for the
	// target task to complete. This keeps the main thread from idling when
	// background threads are busy on other tasks from the same phase.
	while ( b3AtomicLoadInt( &waitTask->status ) != b3_schedulerComplete )
	{
		if ( b3SchedulerExecuteOne( scheduler ) == false )
		{
			b3Yield();
		}
	}
}
