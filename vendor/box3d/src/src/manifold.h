// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/collision.h"
#include "box3d/math_functions.h"

#define B3_MAX_CLIP_POINTS 64

typedef struct b3FaceQuery
{
	float separation;
	int faceIndex;
	int vertexIndex;
} b3FaceQuery;

typedef struct b3EdgeQuery
{
	float separation;
	int indexA;
	int indexB;
} b3EdgeQuery;

typedef struct b3ClipVertex
{
	b3Vec3 position;
	float separation;
	b3FeaturePair pair;
} b3ClipVertex;

typedef enum b3FeatureOwner
{
	b3_featureShapeA = 0,
	b3_featureShapeB = 1
} b3FeatureOwner;

float b3EdgeEdgeSeparation( b3Vec3 p1, b3Vec3 e1, b3Vec3 c1, b3Vec3 p2, b3Vec3 e2, b3Vec3 c2 );
int b3FindIncidentFace( const b3HullData* hull, b3Vec3 refNormal, int vertexIndex );
b3FeaturePair b3MakeFeaturePair( b3FeatureOwner owner1, int index1, b3FeatureOwner owner2, int index2 );

b3FeaturePair b3FlipPair( b3FeaturePair pair );

int b3ClipPolygon( b3ClipVertex* out, b3ClipVertex* polygon, int count, b3Plane clipPlane, int edge, b3Plane refPlane );

#if B3_ENABLE_VALIDATION
bool b3ValidatePolygon( b3ClipVertex* polygon, int count );
#endif

// For single point contact, such as sphere-sphere, sphere-capsule, sphere-triangle
static const b3FeaturePair b3FeaturePair_single = { 0 };

static inline uint32_t b3MakeFeatureId( b3FeaturePair pair )
{
	return ( (uint32_t)pair.owner1 << 24 ) | ( (uint32_t)pair.index1 << 16 ) | ( (uint32_t)pair.owner2 << 8 ) |
		   (uint32_t)pair.index2;
}
