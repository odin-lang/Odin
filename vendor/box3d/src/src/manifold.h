// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/collision.h"
#include "box3d/math_functions.h"

#define B3_MAX_CLIP_POINTS 64

typedef struct b3SeparatingAxis
{
	b3Vec3 normal;
	float separation;
	int indexA;
	int indexB;
	b3SeparatingFeature type;
} b3SeparatingAxis;

typedef struct b3AxisQuery
{
	b3SeparatingAxis faceA;
	b3SeparatingAxis faceB;
	b3SeparatingAxis edge;
	b3SeparatingFeature separatedFeature;
} b3AxisQuery;

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

int b3FindIncidentFace( const b3HullData* hull, b3Vec3 refNormal, int vertexIndex );
b3FeaturePair b3MakeFeaturePair( b3FeatureOwner owner1, int index1, b3FeatureOwner owner2, int index2 );

b3FeaturePair b3FlipPair( b3FeaturePair pair );

int b3ClipPolygon( b3ClipVertex* out, b3ClipVertex* polygon, int count, b3Plane clipPlane, int edge, b3Plane refPlane );

b3AxisQuery b3ComputeSeparatingAxis( const b3HullData* hullA, const b3HullData* hullB, b3Transform xfB, bool earlyReturn );

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

static inline b3SeparatingAxis b3GetBestAxis( const b3AxisQuery* query )
{
	B3_VALIDATE( query->faceA.type == b3_faceAxisA );
	B3_VALIDATE( query->edge.type == b3_edgePairAxis );
	B3_VALIDATE( query->faceB.type == b3_faceAxisB );

	if ( query->faceA.separation > query->faceB.separation )
	{
		if ( query->edge.separation > query->faceA.separation )
		{
			return query->edge;
		}

		return query->faceA;
	}

	if ( query->edge.separation > query->faceB.separation )
	{
		return query->edge;
	}

	return query->faceB;
}
