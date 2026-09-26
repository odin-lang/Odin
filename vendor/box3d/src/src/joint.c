// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "joint.h"

#include "body.h"
#include "contact.h"
#include "core.h"
#include "island.h"
#include "physics_world.h"
#include "recording.h"
#include "shape.h"
#include "solver.h"
#include "solver_set.h"

// needed for dll export
#include "box3d/box3d.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

static b3JointDef b3DefaultJointDef( void )
{
	b3JointDef def = { 0 };
	def.localFrameA.q = b3Quat_identity;
	def.localFrameB.q = b3Quat_identity;
	def.forceThreshold = FLT_MAX;
	def.torqueThreshold = FLT_MAX;
	def.constraintHertz = 60.0f;
	def.constraintDampingRatio = 2.0f;
	def.drawScale = b3GetLengthUnitsPerMeter();
	def.internalValue = B3_SECRET_COOKIE;
	return def;
}

b3ParallelJointDef b3DefaultParallelJointDef( void )
{
	b3ParallelJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	def.hertz = 1.0f;
	def.dampingRatio = 1.0f;
	def.maxTorque = FLT_MAX;
	return def;
}

b3DistanceJointDef b3DefaultDistanceJointDef( void )
{
	b3DistanceJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	def.lowerSpringForce = -FLT_MAX;
	def.upperSpringForce = FLT_MAX;
	def.length = 1.0f;
	def.maxLength = B3_HUGE;
	return def;
}

b3MotorJointDef b3DefaultMotorJointDef( void )
{
	b3MotorJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	return def;
}

b3FilterJointDef b3DefaultFilterJointDef( void )
{
	b3FilterJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	return def;
}

b3PrismaticJointDef b3DefaultPrismaticJointDef( void )
{
	b3PrismaticJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	return def;
}

b3RevoluteJointDef b3DefaultRevoluteJointDef( void )
{
	b3RevoluteJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	return def;
}

b3SphericalJointDef b3DefaultSphericalJointDef( void )
{
	b3SphericalJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	def.targetRotation = b3Quat_identity;
	return def;
}

b3WeldJointDef b3DefaultWeldJointDef( void )
{
	b3WeldJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	return def;
}

b3WheelJointDef b3DefaultWheelJointDef( void )
{
	b3WheelJointDef def = { 0 };
	def.base = b3DefaultJointDef();
	def.enableSuspensionSpring = true;
	def.suspensionHertz = 1.0f;
	def.suspensionDampingRatio = 0.7f;
	def.steeringHertz = 1.0f;
	def.steeringDampingRatio = 0.7f;
	return def;
}

b3ExplosionDef b3DefaultExplosionDef( void )
{
	b3ExplosionDef def = { 0 };
	def.maskBits = B3_DEFAULT_MASK_BITS;
	return def;
}

b3Joint* b3GetJointFullId( b3World* world, b3JointId jointId )
{
	int id = jointId.index1 - 1;
	b3Joint* joint = b3Array_Get( world->joints, id  );
	B3_ASSERT( joint->jointId == id && joint->generation == jointId.generation );
	return joint;
}

b3JointSim* b3GetJointSim( b3World* world, b3Joint* joint )
{
	if ( joint->setIndex == b3_awakeSet )
	{
		B3_ASSERT( 0 <= joint->colorIndex && joint->colorIndex < B3_GRAPH_COLOR_COUNT );
		b3GraphColor* color = world->constraintGraph.colors + joint->colorIndex;
		return b3Array_Get( color->jointSims, joint->localIndex  );
	}

	b3SolverSet* set = b3Array_Get( world->solverSets, joint->setIndex  );
	return b3Array_Get( set->jointSims, joint->localIndex  );
}

b3JointSim* b3GetJointSimCheckType( b3JointId jointId, b3JointType type )
{
	B3_UNUSED( type );
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	B3_ASSERT( joint->type == type );
	b3JointSim* jointSim = b3GetJointSim( world, joint );
	B3_ASSERT( jointSim->type == type );
	return jointSim;
}

typedef struct b3JointPair
{
	b3Joint* joint;
	b3JointSim* jointSim;
} b3JointPair;

static b3JointPair b3CreateJoint( b3World* world, const b3JointDef* def, b3JointType type )
{
	B3_ASSERT( b3IsValidTransform( def->localFrameA ) );
	B3_ASSERT( b3IsValidTransform( def->localFrameB ) );

	b3Body* bodyA = b3GetBodyFullId( world, def->bodyIdA );
	b3Body* bodyB = b3GetBodyFullId( world, def->bodyIdB );

	int bodyIdA = bodyA->id;
	int bodyIdB = bodyB->id;
	int maxSetIndex = b3MaxInt( bodyA->setIndex, bodyB->setIndex );

	// Create joint id and joint
	int jointId = b3AllocId( &world->jointIdPool );
	if ( jointId == world->joints.count )
	{
		b3Array_Push( world->joints, (b3Joint){ 0 }  );
	}

	b3Joint* joint = b3Array_Get( world->joints, jointId  );
	joint->jointId = jointId;
	joint->userData = def->userData;
	joint->generation += 1;
	joint->setIndex = B3_NULL_INDEX;
	joint->colorIndex = B3_NULL_INDEX;
	joint->localIndex = B3_NULL_INDEX;
	joint->islandId = B3_NULL_INDEX;
	joint->islandIndex = B3_NULL_INDEX;
	joint->drawScale = def->drawScale;
	joint->type = type;
	joint->collideConnected = def->collideConnected;

	// Doubly linked list on bodyA
	joint->edges[0].bodyId = bodyIdA;
	joint->edges[0].prevKey = B3_NULL_INDEX;
	joint->edges[0].nextKey = bodyA->headJointKey;

	int keyA = ( jointId << 1 ) | 0;
	if ( bodyA->headJointKey != B3_NULL_INDEX )
	{
		b3Joint* jointA = b3Array_Get( world->joints, bodyA->headJointKey >> 1  );
		b3JointEdge* edgeA = jointA->edges + ( bodyA->headJointKey & 1 );
		edgeA->prevKey = keyA;
	}
	bodyA->headJointKey = keyA;
	bodyA->jointCount += 1;

	// Doubly linked list on bodyB
	joint->edges[1].bodyId = bodyIdB;
	joint->edges[1].prevKey = B3_NULL_INDEX;
	joint->edges[1].nextKey = bodyB->headJointKey;

	int keyB = ( jointId << 1 ) | 1;
	if ( bodyB->headJointKey != B3_NULL_INDEX )
	{
		b3Joint* jointB = b3Array_Get( world->joints, bodyB->headJointKey >> 1  );
		b3JointEdge* edgeB = jointB->edges + ( bodyB->headJointKey & 1 );
		edgeB->prevKey = keyB;
	}
	bodyB->headJointKey = keyB;
	bodyB->jointCount += 1;

	b3JointSim* jointSim;

	if ( bodyA->setIndex == b3_disabledSet || bodyB->setIndex == b3_disabledSet )
	{
		// if either body is disabled, create in disabled set
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_disabledSet  );
		joint->setIndex = b3_disabledSet;
		joint->localIndex = set->jointSims.count;

		jointSim = b3Array_Emplace( set->jointSims );
		memset( jointSim, 0, sizeof( b3JointSim ) );

		jointSim->jointId = jointId;
		jointSim->bodyIdA = bodyIdA;
		jointSim->bodyIdB = bodyIdB;
	}
	else if ( bodyA->type != b3_dynamicBody && bodyB->type != b3_dynamicBody )
	{
		// joint is not attached to a dynamic body
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_staticSet  );
		joint->setIndex = b3_staticSet;
		joint->localIndex = set->jointSims.count;

		jointSim = b3Array_Emplace( set->jointSims );
		memset( jointSim, 0, sizeof( b3JointSim ) );

		jointSim->jointId = jointId;
		jointSim->bodyIdA = bodyIdA;
		jointSim->bodyIdB = bodyIdB;
	}
	else if ( bodyA->setIndex == b3_awakeSet || bodyB->setIndex == b3_awakeSet )
	{
		// if either body is sleeping, wake it
		if ( maxSetIndex >= b3_firstSleepingSet )
		{
			b3WakeSolverSet( world, maxSetIndex );
		}

		joint->setIndex = b3_awakeSet;

		jointSim = b3CreateJointInGraph( world, joint );
		jointSim->jointId = jointId;
		jointSim->bodyIdA = bodyIdA;
		jointSim->bodyIdB = bodyIdB;
	}
	else
	{
		// joint connected between sleeping and/or static bodies
		B3_ASSERT( bodyA->setIndex >= b3_firstSleepingSet || bodyB->setIndex >= b3_firstSleepingSet );
		B3_ASSERT( bodyA->setIndex != b3_staticSet || bodyB->setIndex != b3_staticSet );

		// joint should go into the sleeping set (not static set)
		int setIndex = maxSetIndex;

		b3SolverSet* set = b3Array_Get( world->solverSets, setIndex  );
		joint->setIndex = setIndex;
		joint->localIndex = set->jointSims.count;

		jointSim = b3Array_Emplace( set->jointSims );
		memset( jointSim, 0, sizeof( b3JointSim ) );

		jointSim->jointId = jointId;
		jointSim->bodyIdA = bodyIdA;
		jointSim->bodyIdB = bodyIdB;

		if ( bodyA->setIndex != bodyB->setIndex && bodyA->setIndex >= b3_firstSleepingSet &&
			 bodyB->setIndex >= b3_firstSleepingSet )
		{
			// merge sleeping sets
			b3MergeSolverSets( world, bodyA->setIndex, bodyB->setIndex );
			B3_ASSERT( bodyA->setIndex == bodyB->setIndex );

			// fix potentially invalid set index
			setIndex = bodyA->setIndex;

			b3SolverSet* mergedSet = b3Array_Get( world->solverSets, setIndex  );

			// Careful! The joint sim pointer was orphaned by the set merge.
			jointSim = b3Array_Get( mergedSet->jointSims, joint->localIndex  );
		}

		B3_ASSERT( joint->setIndex == setIndex );
	}

	jointSim->localFrameA = def->localFrameA;
	jointSim->localFrameB = def->localFrameB;
	jointSim->type = type;
	jointSim->constraintHertz = def->constraintHertz;
	jointSim->constraintDampingRatio = def->constraintDampingRatio;
	jointSim->constraintSoftness = (b3Softness){
		.biasRate = 0.0f,
		.massScale = 1.0f,
		.impulseScale = 0.0f,
	};

	B3_ASSERT( b3IsValidFloat( def->forceThreshold ) && def->forceThreshold >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->torqueThreshold ) && def->torqueThreshold >= 0.0f );

	jointSim->forceThreshold = def->forceThreshold;
	jointSim->torqueThreshold = def->torqueThreshold;

	B3_ASSERT( jointSim->jointId == jointId );
	B3_ASSERT( jointSim->bodyIdA == bodyIdA );
	B3_ASSERT( jointSim->bodyIdB == bodyIdB );

	if ( joint->setIndex > b3_disabledSet )
	{
		// Add edge to island graph
		b3LinkJoint( world, joint );
	}

	b3ValidateSolverSets( world );

	return (b3JointPair){ joint, jointSim };
}

static void b3DestroyContactsBetweenBodies( b3World* world, b3Body* bodyA, b3Body* bodyB )
{
	int contactKey;
	int otherBodyId;

	// use the smaller of the two contact lists
	if ( bodyA->contactCount < bodyB->contactCount )
	{
		contactKey = bodyA->headContactKey;
		otherBodyId = bodyB->id;
	}
	else
	{
		contactKey = bodyB->headContactKey;
		otherBodyId = bodyA->id;
	}

	// no need to wake bodies when a joint removes collision between them
	bool wakeBodies = false;

	// destroy the contacts
	while ( contactKey != B3_NULL_INDEX )
	{
		int contactId = contactKey >> 1;
		int edgeIndex = contactKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId  );
		contactKey = contact->edges[edgeIndex].nextKey;

		int otherEdgeIndex = edgeIndex ^ 1;
		if ( contact->edges[otherEdgeIndex].bodyId == otherBodyId )
		{
			// Careful, this removes the contact from the current doubly linked list
			b3DestroyContact( world, contact, wakeBodies );
		}
	}

	b3ValidateSolverSets( world );
}

void b3Joint_SetConstraintTuning( b3JointId jointId, float hertz, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );

	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, JointSetConstraintTuning, jointId, hertz, dampingRatio );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	base->constraintHertz = hertz;
	base->constraintDampingRatio = dampingRatio;
}

void b3Joint_GetConstraintTuning( b3JointId jointId, float* hertz, float* dampingRatio )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	*hertz = base->constraintHertz;
	*dampingRatio = base->constraintDampingRatio;
}

void b3Joint_SetForceThreshold( b3JointId jointId, float threshold )
{
	B3_ASSERT( b3IsValidFloat( threshold ) && threshold >= 0.0f );

	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, JointSetForceThreshold, jointId, threshold );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	base->forceThreshold = threshold;
}

float b3Joint_GetForceThreshold( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	return base->forceThreshold;
}

void b3Joint_SetTorqueThreshold( b3JointId jointId, float threshold )
{
	B3_ASSERT( b3IsValidFloat( threshold ) && threshold >= 0.0f );

	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, JointSetTorqueThreshold, jointId, threshold );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	base->torqueThreshold = threshold;
}

float b3Joint_GetTorqueThreshold( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );
	return base->torqueThreshold;
}

b3JointId b3CreateDistanceJoint( b3WorldId worldId, const b3DistanceJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	B3_ASSERT( b3IsValidFloat( def->length ) && def->length > 0.0f );
	B3_ASSERT( def->lowerSpringForce <= def->upperSpringForce );

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_distanceJoint );

	b3JointSim* joint = pair.jointSim;

	joint->distanceJoint = (b3DistanceJoint){ 0 };
	joint->distanceJoint.length = b3MaxFloat( def->length, B3_LINEAR_SLOP );
	joint->distanceJoint.hertz = def->hertz;
	joint->distanceJoint.dampingRatio = def->dampingRatio;
	joint->distanceJoint.lowerSpringForce = def->lowerSpringForce;
	joint->distanceJoint.upperSpringForce = def->upperSpringForce;
	joint->distanceJoint.minLength = b3MaxFloat( def->minLength, B3_LINEAR_SLOP );
	joint->distanceJoint.maxLength = b3MaxFloat( def->minLength, def->maxLength );
	joint->distanceJoint.maxMotorForce = def->maxMotorForce;
	joint->distanceJoint.motorSpeed = def->motorSpeed;
	joint->distanceJoint.enableSpring = def->enableSpring;
	joint->distanceJoint.enableLimit = def->enableLimit;
	joint->distanceJoint.enableMotor = def->enableMotor;
	joint->distanceJoint.impulse = 0.0f;
	joint->distanceJoint.lowerImpulse = 0.0f;
	joint->distanceJoint.upperImpulse = 0.0f;
	joint->distanceJoint.motorImpulse = 0.0f;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateDistanceJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateMotorJoint( b3WorldId worldId, const b3MotorJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_motorJoint );
	b3JointSim* joint = pair.jointSim;

	joint->motorJoint = (b3MotorJoint){ 0 };
	joint->motorJoint.linearVelocity = def->linearVelocity;
	joint->motorJoint.maxVelocityForce = def->maxVelocityForce;
	joint->motorJoint.angularVelocity = def->angularVelocity;
	joint->motorJoint.maxVelocityTorque = def->maxVelocityTorque;
	joint->motorJoint.linearHertz = def->linearHertz;
	joint->motorJoint.linearDampingRatio = def->linearDampingRatio;
	joint->motorJoint.maxSpringForce = def->maxSpringForce;
	joint->motorJoint.angularHertz = def->angularHertz;
	joint->motorJoint.angularDampingRatio = def->angularDampingRatio;
	joint->motorJoint.maxSpringTorque = def->maxSpringTorque;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateMotorJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateFilterJoint( b3WorldId worldId, const b3FilterJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_filterJoint );

	b3JointSim* joint = pair.jointSim;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateFilterJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateParallelJoint( b3WorldId worldId, const b3ParallelJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	B3_ASSERT( b3IsValidFloat( def->hertz ) && def->hertz >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->dampingRatio ) && def->dampingRatio >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->maxTorque ) && def->maxTorque >= 0.0f );

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_parallelJoint );

	b3JointSim* joint = pair.jointSim;

	joint->parallelJoint = (b3ParallelJoint){ 0 };
	joint->parallelJoint.hertz = def->hertz;
	joint->parallelJoint.dampingRatio = def->dampingRatio;
	joint->parallelJoint.maxTorque = def->maxTorque;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateParallelJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreatePrismaticJoint( b3WorldId worldId, const b3PrismaticJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	B3_ASSERT( def->lowerTranslation <= def->upperTranslation );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_prismaticJoint );

	b3JointSim* joint = pair.jointSim;

	joint->prismaticJoint = (b3PrismaticJoint){ 0 };
	joint->prismaticJoint.hertz = def->hertz;
	joint->prismaticJoint.dampingRatio = def->dampingRatio;
	joint->prismaticJoint.targetTranslation = def->targetTranslation;
	joint->prismaticJoint.lowerTranslation = def->lowerTranslation;
	joint->prismaticJoint.upperTranslation = def->upperTranslation;
	joint->prismaticJoint.maxMotorForce = def->maxMotorForce;
	joint->prismaticJoint.motorSpeed = def->motorSpeed;
	joint->prismaticJoint.enableSpring = def->enableSpring;
	joint->prismaticJoint.enableLimit = def->enableLimit;
	joint->prismaticJoint.enableMotor = def->enableMotor;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreatePrismaticJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateRevoluteJoint( b3WorldId worldId, const b3RevoluteJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_revoluteJoint );

	b3JointSim* joint = pair.jointSim;

	joint->revoluteJoint = (b3RevoluteJoint){ 0 };
	joint->revoluteJoint.hertz = def->hertz;
	joint->revoluteJoint.dampingRatio = def->dampingRatio;
	joint->revoluteJoint.targetAngle = b3ClampFloat( def->targetAngle, -B3_PI, B3_PI );

	float lowerAngle = b3MinFloat( def->lowerAngle, def->upperAngle );
	float upperAngle = b3MaxFloat( def->lowerAngle, def->upperAngle );
	joint->revoluteJoint.lowerAngle = b3ClampFloat( lowerAngle, -0.99f * B3_PI, 0.99f * B3_PI );
	joint->revoluteJoint.upperAngle = b3ClampFloat( upperAngle, -0.99f * B3_PI, 0.99f * B3_PI );

	joint->revoluteJoint.maxMotorTorque = def->maxMotorTorque;
	joint->revoluteJoint.motorSpeed = def->motorSpeed;
	joint->revoluteJoint.enableSpring = def->enableSpring;
	joint->revoluteJoint.enableLimit = def->enableLimit;
	joint->revoluteJoint.enableMotor = def->enableMotor;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateRevoluteJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateSphericalJoint( b3WorldId worldId, const b3SphericalJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	B3_ASSERT( 0.0f <= def->coneAngle && def->coneAngle <= 0.99f * B3_PI );
	B3_ASSERT( b3IsValidQuat( def->targetRotation ) );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_sphericalJoint );

	b3JointSim* joint = pair.jointSim;

	joint->sphericalJoint = (b3SphericalJoint){ 0 };
	joint->sphericalJoint.hertz = def->hertz;
	joint->sphericalJoint.dampingRatio = def->dampingRatio;
	joint->sphericalJoint.targetRotation = def->targetRotation;
	joint->sphericalJoint.coneAngle = b3ClampFloat( def->coneAngle, 0.0f, 0.5f * B3_PI );

	float lowerAngle = b3MinFloat( def->lowerTwistAngle, def->upperTwistAngle );
	float upperAngle = b3MaxFloat( def->lowerTwistAngle, def->upperTwistAngle );
	joint->sphericalJoint.lowerTwistAngle = b3ClampFloat( lowerAngle, -0.99f * B3_PI, 0.99f * B3_PI );
	joint->sphericalJoint.upperTwistAngle = b3ClampFloat( upperAngle, -0.99f * B3_PI, 0.99f * B3_PI );

	joint->sphericalJoint.maxMotorTorque = def->maxMotorTorque;
	joint->sphericalJoint.motorVelocity = def->motorVelocity;
	joint->sphericalJoint.enableSpring = def->enableSpring;
	joint->sphericalJoint.enableConeLimit = def->enableConeLimit;
	joint->sphericalJoint.enableTwistLimit = def->enableTwistLimit;
	joint->sphericalJoint.enableMotor = def->enableMotor;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateSphericalJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateWeldJoint( b3WorldId worldId, const b3WeldJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	B3_ASSERT( 0.0f <= def->angularHertz );
	B3_ASSERT( 0.0f <= def->angularDampingRatio );
	B3_ASSERT( 0.0f <= def->linearHertz );
	B3_ASSERT( 0.0f <= def->linearDampingRatio );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_weldJoint );

	b3JointSim* joint = pair.jointSim;

	joint->weldJoint = (b3WeldJoint){ 0 };
	joint->weldJoint.linearHertz = def->linearHertz;
	joint->weldJoint.linearDampingRatio = def->linearDampingRatio;
	joint->weldJoint.angularHertz = def->angularHertz;
	joint->weldJoint.angularDampingRatio = def->angularDampingRatio;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateWeldJoint, jointId, worldId, *def );
	return jointId;
}

b3JointId b3CreateWheelJoint( b3WorldId worldId, const b3WheelJointDef* def )
{
	B3_CHECK_JOINT_DEF( def );
	B3_ASSERT( def->lowerSuspensionLimit <= def->upperSuspensionLimit );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if (world == NULL)
	{
		return (b3JointId){ 0 };
	}

	b3JointPair pair = b3CreateJoint( world, &def->base, b3_wheelJoint );

	b3JointSim* joint = pair.jointSim;

	joint->wheelJoint = (b3WheelJoint){ 0 };
	joint->wheelJoint.enableSuspensionSpring = def->enableSuspensionSpring;
	joint->wheelJoint.suspensionHertz = def->suspensionHertz;
	joint->wheelJoint.suspensionDampingRatio = def->suspensionDampingRatio;
	joint->wheelJoint.enableSuspensionLimit = def->enableSuspensionLimit;
	joint->wheelJoint.lowerSuspensionLimit = def->lowerSuspensionLimit;
	joint->wheelJoint.upperSuspensionLimit = def->upperSuspensionLimit;
	joint->wheelJoint.enableSpinMotor = def->enableSpinMotor;
	joint->wheelJoint.maxSpinTorque = def->maxSpinTorque;
	joint->wheelJoint.spinSpeed = def->spinSpeed;

	joint->wheelJoint.enableSteering = def->enableSteering;
	joint->wheelJoint.steeringHertz = def->steeringHertz;
	joint->wheelJoint.steeringDampingRatio = def->steeringDampingRatio;
	joint->wheelJoint.targetSteeringAngle = def->targetSteeringAngle;
	joint->wheelJoint.maxSteeringTorque = def->maxSteeringTorque;
	joint->wheelJoint.enableSteeringLimit = def->enableSteeringLimit;
	joint->wheelJoint.lowerSteeringLimit = def->lowerSteeringLimit;
	joint->wheelJoint.upperSteeringLimit = def->upperSteeringLimit;

	b3JointId jointId = { joint->jointId + 1, world->worldId, pair.joint->generation };
	B3_REC_CREATE( world, CreateWheelJoint, jointId, worldId, *def );
	return jointId;
}

void b3DestroyJointInternal( b3World* world, b3Joint* joint, bool wakeBodies )
{
	int jointId = joint->jointId;

	b3JointEdge* edgeA = joint->edges + 0;
	b3JointEdge* edgeB = joint->edges + 1;

	int idA = edgeA->bodyId;
	int idB = edgeB->bodyId;
	b3Body* bodyA = b3Array_Get( world->bodies, idA  );
	b3Body* bodyB = b3Array_Get( world->bodies, idB  );

	// Remove from body A
	if ( edgeA->prevKey != B3_NULL_INDEX )
	{
		b3Joint* prevJoint = b3Array_Get( world->joints, edgeA->prevKey >> 1  );
		b3JointEdge* prevEdge = prevJoint->edges + ( edgeA->prevKey & 1 );
		prevEdge->nextKey = edgeA->nextKey;
	}

	if ( edgeA->nextKey != B3_NULL_INDEX )
	{
		b3Joint* nextJoint = b3Array_Get( world->joints, edgeA->nextKey >> 1  );
		b3JointEdge* nextEdge = nextJoint->edges + ( edgeA->nextKey & 1 );
		nextEdge->prevKey = edgeA->prevKey;
	}

	int edgeKeyA = ( jointId << 1 ) | 0;
	if ( bodyA->headJointKey == edgeKeyA )
	{
		bodyA->headJointKey = edgeA->nextKey;
	}

	bodyA->jointCount -= 1;

	// Remove from body B
	if ( edgeB->prevKey != B3_NULL_INDEX )
	{
		b3Joint* prevJoint = b3Array_Get( world->joints, edgeB->prevKey >> 1  );
		b3JointEdge* prevEdge = prevJoint->edges + ( edgeB->prevKey & 1 );
		prevEdge->nextKey = edgeB->nextKey;
	}

	if ( edgeB->nextKey != B3_NULL_INDEX )
	{
		b3Joint* nextJoint = b3Array_Get( world->joints, edgeB->nextKey >> 1  );
		b3JointEdge* nextEdge = nextJoint->edges + ( edgeB->nextKey & 1 );
		nextEdge->prevKey = edgeB->prevKey;
	}

	int edgeKeyB = ( jointId << 1 ) | 1;
	if ( bodyB->headJointKey == edgeKeyB )
	{
		bodyB->headJointKey = edgeB->nextKey;
	}

	bodyB->jointCount -= 1;

	if ( joint->islandId != B3_NULL_INDEX )
	{
		B3_ASSERT( joint->setIndex > b3_disabledSet );
		b3UnlinkJoint( world, joint );
	}
	else
	{
		B3_ASSERT( joint->setIndex <= b3_disabledSet );
	}

	// Remove joint from solver set that owns it
	int setIndex = joint->setIndex;
	int localIndex = joint->localIndex;

	if ( setIndex == b3_awakeSet )
	{
		b3RemoveJointFromGraph( world, joint->edges[0].bodyId, joint->edges[1].bodyId, joint->colorIndex, localIndex );
	}
	else
	{
		b3SolverSet* set = b3Array_Get( world->solverSets, setIndex  );
		int movedIndex = b3Array_RemoveSwap( set->jointSims, localIndex  );
		if ( movedIndex != B3_NULL_INDEX )
		{
			// Fix moved joint
			b3JointSim* movedJointSim = set->jointSims.data + localIndex;
			int movedId = movedJointSim->jointId;
			b3Joint* movedJoint = b3Array_Get( world->joints, movedId  );
			B3_ASSERT( movedJoint->localIndex == movedIndex );
			movedJoint->localIndex = localIndex;
		}
	}

	// Free joint and id (preserve joint revision)
	joint->setIndex = B3_NULL_INDEX;
	joint->localIndex = B3_NULL_INDEX;
	joint->colorIndex = B3_NULL_INDEX;
	joint->jointId = B3_NULL_INDEX;
	b3FreeId( &world->jointIdPool, jointId );

	if ( wakeBodies )
	{
		b3WakeBody( world, bodyA );
		b3WakeBody( world, bodyB );
	}

	b3ValidateSolverSets( world );
}

void b3DestroyJoint( b3JointId jointId, bool wakeAttached )
{
	b3World* world = b3GetWorld( jointId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, DestroyJoint, jointId, wakeAttached );

	b3Joint* joint = b3GetJointFullId( world, jointId );

	b3DestroyJointInternal( world, joint, wakeAttached );
}

b3JointType b3Joint_GetType( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return joint->type;
}

b3BodyId b3Joint_GetBodyA( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return b3MakeBodyId( world, joint->edges[0].bodyId );
}

b3BodyId b3Joint_GetBodyB( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return b3MakeBodyId( world, joint->edges[1].bodyId );
}

b3WorldId b3Joint_GetWorld( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	return (b3WorldId){ (uint16_t)( jointId.world0 + 1 ), world->generation };
}

void b3Joint_SetLocalFrameA( b3JointId jointId, b3Transform localFrame )
{
	B3_ASSERT( b3IsValidTransform( localFrame ) );

	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, JointSetLocalFrameA, jointId, localFrame );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* jointSim = b3GetJointSim( world, joint );
	jointSim->localFrameA = localFrame;
}

b3Transform b3Joint_GetLocalFrameA( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* jointSim = b3GetJointSim( world, joint );
	return jointSim->localFrameA;
}

void b3Joint_SetLocalFrameB( b3JointId jointId, b3Transform localFrame )
{
	B3_ASSERT( b3IsValidTransform( localFrame ) );

	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, JointSetLocalFrameB, jointId, localFrame );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* jointSim = b3GetJointSim( world, joint );
	jointSim->localFrameB = localFrame;
}

b3Transform b3Joint_GetLocalFrameB( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* jointSim = b3GetJointSim( world, joint );
	return jointSim->localFrameB;
}

void b3Joint_SetCollideConnected( b3JointId jointId, bool shouldCollide )
{
	b3World* world = b3GetUnlockedWorld( jointId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, JointSetCollideConnected, jointId, shouldCollide );

	b3Joint* joint = b3GetJointFullId( world, jointId );
	if ( joint->collideConnected == shouldCollide )
	{
		return;
	}

	joint->collideConnected = shouldCollide;

	b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId  );
	b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId  );

	if ( shouldCollide )
	{
		// need to tell the broad-phase to look for new pairs for one of the
		// two bodies. Pick the one with the fewest shapes.
		int shapeCountA = bodyA->shapeCount;
		int shapeCountB = bodyB->shapeCount;

		int shapeId = shapeCountA < shapeCountB ? bodyA->headShapeId : bodyB->headShapeId;
		while ( shapeId != B3_NULL_INDEX )
		{
			b3Shape* shape = b3Array_Get( world->shapes, shapeId  );

			if ( shape->proxyKey != B3_NULL_INDEX )
			{
				b3BufferMove( &world->broadPhase, shape->proxyKey );
			}

			shapeId = shape->nextShapeId;
		}
	}
	else
	{
		b3DestroyContactsBetweenBodies( world, bodyA, bodyB );
	}
}

bool b3Joint_GetCollideConnected( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return joint->collideConnected;
}

void b3Joint_SetUserData( b3JointId jointId, void* userData )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	joint->userData = userData;
}

void* b3Joint_GetUserData( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return joint->userData;
}

void b3Joint_WakeBodies( b3JointId jointId )
{
	b3World* world = b3GetUnlockedWorld( jointId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, JointWakeBodies, jointId );

	world->locked = true;

	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId  );
	b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId  );

	b3WakeBody( world, bodyA );
	b3WakeBody( world, bodyB );

	world->locked = false;
}

void b3GetJointReaction( b3World* world, b3JointSim* sim, float invTimeStep, float* force, float* torque )
{
	float linearImpulse = 0.0f;
	float angularImpulse = 0.0f;

	switch ( sim->type )
	{
		case b3_parallelJoint:
		{
			b3ParallelJoint* joint = &sim->parallelJoint;
			b3Vec3 impulse = {
				.x = joint->perpImpulse.x,
				.y = joint->perpImpulse.y,
				.z = 0.0f,
			};
			angularImpulse = b3Length( impulse );
		}
		break;

		case b3_distanceJoint:
		{
			b3DistanceJoint* joint = &sim->distanceJoint;
			linearImpulse = b3AbsFloat( joint->impulse + joint->lowerImpulse - joint->upperImpulse + joint->motorImpulse );
		}
		break;

		case b3_motorJoint:
		{
			b3MotorJoint* joint = &sim->motorJoint;
			linearImpulse = b3Length( b3Add( joint->linearVelocityImpulse, joint->linearSpringImpulse ) );
			angularImpulse = b3Length( b3Add( joint->angularVelocityImpulse, joint->angularSpringImpulse ) );
		}
		break;

		case b3_prismaticJoint:
		{
			b3PrismaticJoint* joint = &sim->prismaticJoint;
			b3Vec3 impulse = {
				.x = joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse,
				.y = joint->perpImpulse.x,
				.z = joint->perpImpulse.y,
			};
			linearImpulse = b3Length( impulse );
			angularImpulse = b3Length( joint->angularImpulse );
		}
		break;

		case b3_revoluteJoint:
		{
			b3RevoluteJoint* joint = &sim->revoluteJoint;
			linearImpulse = b3Length( joint->linearImpulse );
			b3Vec3 impulse = {
				.x = joint->perpImpulse.x,
				.y = joint->perpImpulse.y,
				.z = joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse,
			};
			angularImpulse = b3Length( impulse );
		}
		break;

		case b3_sphericalJoint:
		{
			// todo improve performance
			b3SphericalJoint* joint = &sim->sphericalJoint;
			linearImpulse = b3Length( joint->linearImpulse );

			b3WorldTransform xfA = b3GetBodyTransform( world, sim->bodyIdA );
			b3WorldTransform xfB = b3GetBodyTransform( world, sim->bodyIdB );
			b3Quat qA = b3MulQuat( xfA.q, sim->localFrameA.q );
			b3Quat qB = b3MulQuat( xfB.q, sim->localFrameB.q );

			// Cone axis is the z-axis of body A.
			b3Vec3 coneAxis = b3RotateVector( qA, b3Vec3_axisZ );
			b3Vec3 twistAxis = b3RotateVector( qB, b3Vec3_axisZ );
			b3Vec3 swingAxis = b3Normalize( b3Cross( coneAxis, twistAxis ) );

			b3Vec3 impulse = b3Add( joint->springImpulse, joint->motorImpulse );
			impulse = b3MulAdd( impulse, joint->lowerTwistImpulse - joint->upperTwistImpulse, twistAxis );
			impulse = b3MulAdd( impulse, joint->swingImpulse, swingAxis );

			angularImpulse = b3Length( impulse );
		}
		break;

		case b3_weldJoint:
		{
			b3WeldJoint* joint = &sim->weldJoint;
			linearImpulse = b3Length( joint->linearImpulse );
			angularImpulse = b3Length( joint->angularImpulse );
		}
		break;

		case b3_wheelJoint:
		{
			// todo probably wrong
			b3WheelJoint* joint = &sim->wheelJoint;
			b3Vec2 perpImpulse = joint->linearImpulse;
			float axialImpulse = joint->suspensionSpringImpulse + joint->lowerSuspensionImpulse - joint->upperSuspensionImpulse;
			linearImpulse = sqrtf( perpImpulse.x * perpImpulse.x + perpImpulse.y * perpImpulse.y + axialImpulse * axialImpulse );
			angularImpulse = b3AbsFloat( joint->spinImpulse );
		}
		break;

		default:
			break;
	}

	*force = linearImpulse * invTimeStep;
	*torque = angularImpulse * invTimeStep;
}

static b3Vec3 b3GetJointConstraintForce( b3World* world, b3Joint* joint )
{
	b3JointSim* base = b3GetJointSim( world, joint );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			return b3Vec3_zero;

		case b3_distanceJoint:
			return b3GetDistanceJointForce( world, base );

		case b3_filterJoint:
			return b3Vec3_zero;

		case b3_motorJoint:
			return b3GetMotorJointForce( world, base );

		case b3_prismaticJoint:
			return b3GetPrismaticJointForce( world, base );

		case b3_revoluteJoint:
			return b3GetRevoluteJointForce( world, base );

		case b3_sphericalJoint:
			return b3GetSphericalJointForce( world, base );

		case b3_weldJoint:
			return b3GetWeldJointForce( world, base );

		case b3_wheelJoint:
			return b3GetWheelJointForce( world, base );

		default:
			B3_ASSERT( false );
			return b3Vec3_zero;
	}
}

static b3Vec3 b3GetJointConstraintTorque( b3World* world, b3Joint* joint )
{
	b3JointSim* base = b3GetJointSim( world, joint );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			return b3GetParallelJointTorque( world, base );

		case b3_distanceJoint:
			return b3Vec3_zero;

		case b3_filterJoint:
			return b3Vec3_zero;

		case b3_motorJoint:
			return b3GetMotorJointTorque( world, base );

		case b3_prismaticJoint:
			return b3GetPrismaticJointTorque( world, base );

		case b3_revoluteJoint:
			return b3GetRevoluteJointTorque( world, base );

		case b3_sphericalJoint:
			return b3GetSphericalJointTorque( world, base );

		case b3_weldJoint:
			return b3GetWeldJointTorque( world, base );

		case b3_wheelJoint:
			return b3GetWheelJointTorque( world, base );

		default:
			B3_ASSERT( false );
			return b3Vec3_zero;
	}
}

b3Vec3 b3Joint_GetConstraintForce( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return b3GetJointConstraintForce( world, joint );
}

b3Vec3 b3Joint_GetConstraintTorque( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	return b3GetJointConstraintTorque( world, joint );
}

float b3Joint_GetLinearSeparation( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );

	b3WorldTransform xfA = b3GetBodyTransform( world, joint->edges[0].bodyId );
	b3WorldTransform xfB = b3GetBodyTransform( world, joint->edges[1].bodyId );

	b3Pos pA = b3TransformWorldPoint( xfA, base->localFrameA.p );
	b3Pos pB = b3TransformWorldPoint( xfB, base->localFrameB.p );
	b3Vec3 dp = b3SubPos( pB, pA );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			return 0.0f;

		case b3_distanceJoint:
		{
			b3DistanceJoint* distanceJoint = &base->distanceJoint;
			float length = b3Length( dp );
			if ( distanceJoint->enableSpring )
			{
				if ( distanceJoint->enableLimit )
				{
					if ( length < distanceJoint->minLength )
					{
						return distanceJoint->minLength - length;
					}

					if ( length > distanceJoint->maxLength )
					{
						return length - distanceJoint->maxLength;
					}

					return 0.0f;
				}

				return 0.0f;
			}

			return b3AbsFloat( length - distanceJoint->length );
		}

		case b3_motorJoint:
			return 0.0f;

		case b3_filterJoint:
			return 0.0f;

		case b3_prismaticJoint:
		{
			b3PrismaticJoint* prismaticJoint = &base->prismaticJoint;
			b3Vec3 axisA = b3RotateVector( xfA.q, b3Vec3_axisX );
			b3Vec3 perpA = b3Perp( axisA );
			float perpendicularSeparation = b3AbsFloat( b3Dot( perpA, dp ) );
			float limitSeparation = 0.0f;

			if ( prismaticJoint->enableLimit )
			{
				float translation = b3Dot( axisA, dp );
				if ( translation < prismaticJoint->lowerTranslation )
				{
					limitSeparation = prismaticJoint->lowerTranslation - translation;
				}

				if ( prismaticJoint->upperTranslation < translation )
				{
					limitSeparation = translation - prismaticJoint->upperTranslation;
				}
			}

			return sqrtf( perpendicularSeparation * perpendicularSeparation + limitSeparation * limitSeparation );
		}

		case b3_revoluteJoint:
			return b3Length( dp );

		case b3_sphericalJoint:
			return b3Length( dp );

		case b3_weldJoint:
		{
			b3WeldJoint* weldJoint = &base->weldJoint;
			if ( weldJoint->linearHertz == 0.0f )
			{
				return b3Length( dp );
			}

			return 0.0f;
		}

		case b3_wheelJoint:
		{
			b3WheelJoint* wheelJoint = &base->wheelJoint;
			b3Vec3 axisA = b3RotateVector( xfA.q, b3Vec3_axisX );
			b3Vec3 perpA = b3Perp( axisA );
			float perpendicularSeparation = b3AbsFloat( b3Dot( perpA, dp ) );
			float limitSeparation = 0.0f;

			if ( wheelJoint->enableSuspensionLimit )
			{
				float translation = b3Dot( axisA, dp );
				if ( translation < wheelJoint->lowerSuspensionLimit )
				{
					limitSeparation = wheelJoint->lowerSuspensionLimit - translation;
				}

				if ( wheelJoint->upperSuspensionLimit < translation )
				{
					limitSeparation = translation - wheelJoint->upperSuspensionLimit;
				}
			}

			return sqrtf( perpendicularSeparation * perpendicularSeparation + limitSeparation * limitSeparation );
		}

		default:
			B3_ASSERT( false );
			return 0.0f;
	}
}

float b3Joint_GetAngularSeparation( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );

	b3WorldTransform xfA = b3GetBodyTransform( world, joint->edges[0].bodyId );
	b3WorldTransform xfB = b3GetBodyTransform( world, joint->edges[1].bodyId );

	b3Quat relQ = b3InvMulQuat( xfA.q, xfB.q );

	switch ( joint->type )
	{
		case b3_parallelJoint:
		{
			// Remove hinge angle
			relQ.v.z = 0.0f;
			return b3GetQuatAngle( relQ );
		}

		case b3_distanceJoint:
			return 0.0f;

		case b3_motorJoint:
			return 0.0f;

		case b3_filterJoint:
			return 0.0f;

		case b3_prismaticJoint:
			return b3GetQuatAngle( relQ );

		case b3_revoluteJoint:
		{
			b3RevoluteJoint* revoluteJoint = &base->revoluteJoint;
			if ( revoluteJoint->enableLimit )
			{
				float angle = b3GetTwistAngle( relQ );
				if ( angle < revoluteJoint->lowerAngle )
				{
					return b3GetQuatAngle( relQ );
				}

				if ( revoluteJoint->upperAngle < angle )
				{
					return b3GetQuatAngle( relQ );
				}
			}

			// Remove hinge angle
			relQ.v.z = 0.0f;
			return b3GetQuatAngle( relQ );
		}

		case b3_sphericalJoint:
		{
			b3SphericalJoint* sphericalJoint = &base->sphericalJoint;
			float sum = 0.0f;
			if ( sphericalJoint->enableConeLimit )
			{
				float swingAngle = b3GetSwingAngle( relQ );
				sum += b3MaxFloat( 0.0f, swingAngle - sphericalJoint->coneAngle );
			}

			if ( sphericalJoint->enableTwistLimit )
			{
				float twistAngle = b3GetTwistAngle( relQ );
				sum += b3MaxFloat( 0.0f, sphericalJoint->lowerTwistAngle - twistAngle );
				sum += b3MaxFloat( 0.0f, twistAngle - sphericalJoint->upperTwistAngle );
			}

			return sum;
		}

		case b3_weldJoint:
		{
			b3WeldJoint* weldJoint = &base->weldJoint;
			if ( weldJoint->angularHertz == 0.0f )
			{
				return b3GetQuatAngle( relQ );
			}

			return 0.0f;
		}

		case b3_wheelJoint:
			// todo
			B3_ASSERT( false );
			return 0.0f;

		default:
			B3_ASSERT( false );
			return 0.0f;
	}
}

#if 0
void b3Joint_SetSpringRotationTarget( b3JointId jointId, b3Quat relativeBodyRotation, float hertz )
{
	B3_ASSERT( b3IsValidQuat( relativeBodyRotation ) );
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz > 0.0f );

	b3World* world = b3GetWorld( jointId.world0 );
	b3Joint* joint = b3GetJointFullId( world, jointId );
	b3JointSim* base = b3GetJointSim( world, joint );

	b3Quat qA = base->localFrameA.q;
	b3Quat qB = b3MulQuat( relativeBodyRotation, base->localFrameB.q );

	// This keeps the twist angle in the range [-pi, pi]
	if ( b3DotQuat( qA, qB ) < 0.0f )
	{
		qA = -qA;
	}

	b3Quat relQ = b3InvMulQuat( qA, qB );

	switch ( joint->type )
	{
		case b3_revoluteJoint:
			base->revoluteJoint.targetAngle = b3GetTwistAngle( relQ );
			base->revoluteJoint.hertz = hertz;
			break;

		case b3_sphericalJoint:
			base->sphericalJoint.targetRotation = relQ;
			base->sphericalJoint.hertz = hertz;
			break;

		default:
			break;
	}
}
#endif

void b3PrepareJoint( b3JointSim* joint, b3StepContext* context )
{
	// Clamp joint hertz based on the time step to reduce jitter.
	float hertz = b3MinFloat( joint->constraintHertz, 0.25f * context->inv_h );
	joint->constraintSoftness = b3MakeSoft( hertz, joint->constraintDampingRatio, context->h );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			b3PrepareParallelJoint( joint, context );
			break;

		case b3_distanceJoint:
			b3PrepareDistanceJoint( joint, context );
			break;

		case b3_filterJoint:
			break;

		case b3_motorJoint:
			b3PrepareMotorJoint( joint, context );
			break;

		case b3_prismaticJoint:
			b3PreparePrismaticJoint( joint, context );
			break;

		case b3_revoluteJoint:
			b3PrepareRevoluteJoint( joint, context );
			break;

		case b3_sphericalJoint:
			b3PrepareSphericalJoint( joint, context );
			break;

		case b3_weldJoint:
			b3PrepareWeldJoint( joint, context );
			break;

		case b3_wheelJoint:
			b3PrepareWheelJoint( joint, context );
			break;

		default:
			B3_ASSERT( false );
	}
}

void b3WarmStartJoint( b3JointSim* joint, b3StepContext* context )
{
	switch ( joint->type )
	{
		case b3_parallelJoint:
			b3WarmStartParallelJoint( joint, context );
			break;

		case b3_distanceJoint:
			b3WarmStartDistanceJoint( joint, context );
			break;

		case b3_filterJoint:
			break;

		case b3_motorJoint:
			b3WarmStartMotorJoint( joint, context );
			break;

		case b3_prismaticJoint:
			b3WarmStartPrismaticJoint( joint, context );
			break;

		case b3_revoluteJoint:
			b3WarmStartRevoluteJoint( joint, context );
			break;

		case b3_sphericalJoint:
			b3WarmStartSphericalJoint( joint, context );
			break;

		case b3_weldJoint:
			b3WarmStartWeldJoint( joint, context );
			break;

		case b3_wheelJoint:
			b3WarmStartWheelJoint( joint, context );
			break;

		default:
			B3_ASSERT( false );
	}
}

void b3SolveJoint( b3JointSim* joint, b3StepContext* context, bool useBias )
{
	B3_UNUSED( useBias );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			b3SolveParallelJoint( joint, context );
			break;

		case b3_distanceJoint:
			b3SolveDistanceJoint( joint, context, useBias );
			break;

		case b3_filterJoint:
			break;

		case b3_motorJoint:
			b3SolveMotorJoint( joint, context );
			break;

		case b3_prismaticJoint:
			b3SolvePrismaticJoint( joint, context, useBias );
			break;

		case b3_revoluteJoint:
			b3SolveRevoluteJoint( joint, context, useBias );
			break;

		case b3_sphericalJoint:
			b3SolveSphericalJoint( joint, context, useBias );
			break;

		case b3_weldJoint:
			b3SolveWeldJoint( joint, context, useBias );
			break;

		case b3_wheelJoint:
			b3SolveWheelJoint( joint, context, useBias );
			break;

		default:
			B3_ASSERT( false );
	}
}

void b3PrepareJoints_Overflow( b3StepContext* context )
{
	b3TracyCZoneNC( prepare_joints, "PrepJoints", b3_colorOldLace, true );

	b3ConstraintGraph* graph = context->graph;
	b3JointSim* joints = graph->colors[B3_OVERFLOW_INDEX].jointSims.data;
	int jointCount = graph->colors[B3_OVERFLOW_INDEX].jointSims.count;

	for ( int i = 0; i < jointCount; ++i )
	{
		b3JointSim* joint = joints + i;
		b3PrepareJoint( joint, context );
	}

	b3TracyCZoneEnd( prepare_joints );
}

void b3WarmStartJoints_Overflow( b3StepContext* context )
{
	b3TracyCZoneNC( prepare_joints, "PrepJoints", b3_colorOldLace, true );

	b3ConstraintGraph* graph = context->graph;
	b3JointSim* joints = graph->colors[B3_OVERFLOW_INDEX].jointSims.data;
	int jointCount = graph->colors[B3_OVERFLOW_INDEX].jointSims.count;

	for ( int i = 0; i < jointCount; ++i )
	{
		b3JointSim* joint = joints + i;
		b3WarmStartJoint( joint, context );
	}

	b3TracyCZoneEnd( prepare_joints );
}

void b3SolveJoints_Overflow( b3StepContext* context, bool useBias )
{
	b3TracyCZoneNC( solve_joints, "SolveJoints", b3_colorLemonChiffon, true );

	b3ConstraintGraph* graph = context->graph;
	b3JointSim* joints = graph->colors[B3_OVERFLOW_INDEX].jointSims.data;
	int jointCount = graph->colors[B3_OVERFLOW_INDEX].jointSims.count;

	for ( int i = 0; i < jointCount; ++i )
	{
		b3JointSim* joint = joints + i;
		b3SolveJoint( joint, context, useBias );
	}

	b3TracyCZoneEnd( solve_joints );
}

void b3DrawJoint( b3DebugDraw* draw, b3World* world, b3Joint* joint )
{
	b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId  );
	b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId  );
	if ( bodyA->setIndex == b3_disabledSet || bodyB->setIndex == b3_disabledSet )
	{
		return;
	}

	b3JointSim* jointSim = b3GetJointSim( world, joint );

	b3WorldTransform transformA = b3GetBodyTransformQuick( world, bodyA );
	b3WorldTransform transformB = b3GetBodyTransformQuick( world, bodyB );
	b3Pos pA = b3TransformWorldPoint( transformA, jointSim->localFrameA.p );
	b3Pos pB = b3TransformWorldPoint( transformB, jointSim->localFrameB.p );

	b3HexColor color = b3_colorDarkSeaGreen;

	float scale = b3MaxFloat( 0.0001f, draw->jointScale * joint->drawScale );

	switch ( joint->type )
	{
		case b3_parallelJoint:
			b3DrawParallelJoint( draw, jointSim, transformA, transformB, scale );
			break;

		case b3_distanceJoint:
			b3DrawDistanceJoint( draw, jointSim, transformA, transformB );
			break;

		case b3_filterJoint:
			draw->DrawSegmentFcn( pA, pB, b3_colorGold, draw->context );
			break;

		case b3_motorJoint:
			draw->DrawSegmentFcn( pA, pB, b3_colorPlum, draw->context );
			draw->DrawPointFcn( pA, 8.0f, b3_colorYellowGreen, draw->context );
			draw->DrawPointFcn( pB, 8.0f, b3_colorPlum, draw->context );
			break;

		case b3_prismaticJoint:
			b3DrawPrismaticJoint( draw, jointSim, transformA, transformB, scale );
			break;

		case b3_revoluteJoint:
			b3DrawRevoluteJoint( draw, jointSim, transformA, transformB, scale );
			break;

		case b3_sphericalJoint:
			b3DrawSphericalJoint( draw, jointSim, transformA, transformB, scale );
			break;

		case b3_weldJoint:
			b3DrawWeldJoint( draw, jointSim, transformA, transformB, scale );
			break;

		case b3_wheelJoint:
			b3DrawWheelJoint( draw, jointSim, transformA, transformB, scale );
			break;

		default:
			draw->DrawSegmentFcn( transformA.p, pA, color, draw->context );
			draw->DrawSegmentFcn( pA, pB, color, draw->context );
			draw->DrawSegmentFcn( transformB.p, pB, color, draw->context );
			break;
	}

	if ( draw->drawGraphColors )
	{
		b3HexColor graphColors[B3_GRAPH_COLOR_COUNT] = {
			b3_colorRed,	b3_colorOrange, b3_colorYellow,	   b3_colorGreen,	  b3_colorCyan,		b3_colorBlue,
			b3_colorViolet, b3_colorPink,	b3_colorChocolate, b3_colorGoldenRod, b3_colorCoral,	b3_colorRosyBrown,
			b3_colorAqua,	b3_colorPeru,	b3_colorLime,	   b3_colorGold,	  b3_colorPlum,		b3_colorSnow,
			b3_colorTeal,	b3_colorKhaki,	b3_colorSalmon,	   b3_colorPeachPuff, b3_colorHoneyDew, b3_colorBlack,
		};

		int colorIndex = joint->colorIndex;
		if ( colorIndex != B3_NULL_INDEX )
		{
			b3Pos p = b3LerpPosition( pA, pB, 0.5f );
			draw->DrawPointFcn( p, 5.0f, graphColors[colorIndex], draw->context );
		}
	}

	if ( draw->drawJointExtras )
	{
		b3Vec3 force = b3GetJointConstraintForce( world, joint );
		b3Vec3 torque = b3GetJointConstraintTorque( world, joint );
		b3Pos p = b3LerpPosition( pA, pB, 0.5f );

		draw->DrawSegmentFcn( p, b3OffsetPos( p, b3MulSV( 0.001f, force ) ), b3_colorAzure, draw->context );

		char buffer[64];
		snprintf( buffer, 64, "f = %g, t = %g", b3Length( force ), b3Length( torque ) );
		draw->DrawStringFcn( p, buffer, b3_colorAzure, draw->context );
	}
}
