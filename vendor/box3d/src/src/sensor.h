// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "bitset.h"
#include "container.h"

typedef struct b3Shape b3Shape;
typedef struct b3World b3World;

// Used to track shapes that hit sensors using time of impact
typedef struct b3SensorHit
{
	int sensorId;
	int visitorId;
} b3SensorHit;

typedef struct b3Visitor
{
	int shapeId;
	uint16_t generation;
} b3Visitor;

b3DeclareArray( b3Visitor );

typedef struct b3Sensor
{
	b3Array( b3Visitor ) hits;
	b3Array( b3Visitor ) overlaps1;
	b3Array( b3Visitor ) overlaps2;
	int shapeId;
} b3Sensor;

typedef struct b3SensorTaskContext
{
	b3BitSet eventBits;
} b3SensorTaskContext;

void b3OverlapSensors( b3World* world );
void b3DestroySensor( b3World* world, b3Shape* sensorShape );
