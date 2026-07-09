// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

typedef void b3TaskCallback( void* taskContext );
typedef struct b3Scheduler b3Scheduler;

b3Scheduler* b3CreateScheduler( int workerCount );
void b3DestroyScheduler( b3Scheduler* scheduler );
void b3ResetScheduler( b3Scheduler* scheduler );

// See b3EnqueueTaskCallback and b3FinishTaskCallback
void* b3SchedulerEnqueueTask( b3TaskCallback* task, void* taskContext, void* userContext, const char* name );
void b3SchedulerFinishTask( void* userTask, void* userContext );
