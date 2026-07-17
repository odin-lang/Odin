// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "body.h"

#include "aabb.h"
#include "contact.h"
#include "core.h"
#include "id_pool.h"
#include "island.h"
#include "joint.h"
#include "physics_world.h"
#include "recording.h"
#include "sensor.h"
#include "shape.h"
#include "solver_set.h"

// needed for dll export
#include "box3d/box3d.h"
#include "box3d/id.h"

#include <stddef.h>

// Get a validated body from a world using an id.
b3Body* b3GetBodyFullId( b3World* world, b3BodyId bodyId )
{
	B3_ASSERT( b3Body_IsValid( bodyId ) );

	// id index starts at one so that zero can represent null
	// id index starts at one so that zero can represent null
	return b3Array_Get( world->bodies, bodyId.index1 - 1 );
}

b3WorldTransform b3GetBodyTransformQuick( b3World* world, b3Body* body )
{
	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );
	b3BodySim* bodySim = b3Array_Get( set->bodySims, body->localIndex );
	return bodySim->transform;
}

b3WorldTransform b3GetBodyTransform( b3World* world, int bodyId )
{
	b3Body* body = b3Array_Get( world->bodies, bodyId );
	return b3GetBodyTransformQuick( world, body );
}

// Create a b3BodyId from a raw id.
b3BodyId b3MakeBodyId( b3World* world, int bodyId )
{
	b3Body* body = b3Array_Get( world->bodies, bodyId );
	return (b3BodyId){ bodyId + 1, world->worldId, body->generation };
}

b3BodySim* b3GetBodySim( b3World* world, b3Body* body )
{
	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );
	b3BodySim* bodySim = b3Array_Get( set->bodySims, body->localIndex );
	return bodySim;
}

b3BodyState* b3GetBodyState( b3World* world, b3Body* body )
{
	if ( body->setIndex == b3_awakeSet )
	{
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
		return b3Array_Get( set->bodyStates, body->localIndex );
	}

	return NULL;
}

void b3SyncBodyFlags( b3World* world, b3Body* body )
{
	// Never sync transient flags
	uint32_t flags = body->flags & ~b3_bodyTransientFlags;

	b3BodySim* bodySim = b3GetBodySim( world, body );
	bodySim->flags = flags;

	b3BodyState* bodyState = b3GetBodyState( world, body );
	if ( bodyState != NULL )
	{
		bodyState->flags = flags;
	}
}

static void b3CreateIslandForBody( b3World* world, int setIndex, b3Body* body )
{
	B3_ASSERT( body->islandId == B3_NULL_INDEX );
	B3_ASSERT( setIndex != b3_disabledSet );

	b3Island* island = b3CreateIsland( world, setIndex );
	b3Array_Push( island->bodies, body->id );
	body->islandId = island->islandId;
	body->islandIndex = 0;

	b3ValidateIsland( world, island->islandId );
}

static void b3RemoveBodyFromIsland( b3World* world, b3Body* body )
{
	if ( body->islandId == B3_NULL_INDEX )
	{
		B3_ASSERT( body->islandIndex == B3_NULL_INDEX );
		return;
	}

	int islandId = body->islandId;
	b3Island* island = b3Array_Get( world->islands, islandId );
	{
		int localIndex = body->islandIndex;
		int movedBodyId = island->bodies.data[island->bodies.count - 1];
		island->bodies.data[localIndex] = movedBodyId;
		B3_VALIDATE( world->bodies.data[movedBodyId].islandIndex == island->bodies.count - 1 );
		world->bodies.data[movedBodyId].islandIndex = localIndex;
		island->bodies.count -= 1;
	}

	if ( island->bodies.count == 0 )
	{
		// Destroy empty island
		B3_ASSERT( island->contacts.count == 0 );
		B3_ASSERT( island->joints.count == 0 );

		// Free the island
		b3DestroyIsland( world, island->islandId );
	}
	else
	{
		b3ValidateIsland( world, islandId );
	}

	body->islandId = B3_NULL_INDEX;
	body->islandIndex = B3_NULL_INDEX;
}

static void b3DestroyBodyContacts( b3World* world, b3Body* body, bool wakeBodies )
{
	// Destroy the attached contacts
	int edgeKey = body->headContactKey;
	while ( edgeKey != B3_NULL_INDEX )
	{
		int contactId = edgeKey >> 1;
		int edgeIndex = edgeKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId );
		edgeKey = contact->edges[edgeIndex].nextKey;
		b3DestroyContact( world, contact, wakeBodies );
	}

	b3ValidateSolverSets( world );
}

b3BodyId b3CreateBody( b3WorldId worldId, const b3BodyDef* def )
{
	B3_CHECK_DEF( def );
	B3_ASSERT( b3IsValidPosition( def->position ) );
	B3_ASSERT( b3IsValidQuat( def->rotation ) );
	B3_ASSERT( b3IsValidVec3( def->linearVelocity ) );
	B3_ASSERT( b3IsValidVec3( def->angularVelocity ) );
	B3_ASSERT( b3IsValidFloat( def->linearDamping ) && def->linearDamping >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->angularDamping ) && def->angularDamping >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->sleepThreshold ) && def->sleepThreshold >= 0.0f );
	B3_ASSERT( b3IsValidFloat( def->gravityScale ) );

	b3World* world = b3GetUnlockedWorldFromId( worldId );

	if ( world == NULL )
	{
		return b3_nullBodyId;
	}

	world->locked = true;

	bool isAwake = ( def->isAwake || def->enableSleep == false ) && def->isEnabled;

	// determine the solver set
	int setId;
	if ( def->isEnabled == false )
	{
		// any body type can be disabled
		setId = b3_disabledSet;
	}
	else if ( def->type == b3_staticBody )
	{
		setId = b3_staticSet;
	}
	else if ( isAwake == true )
	{
		setId = b3_awakeSet;
	}
	else
	{
		// new set for a sleeping body in its own island
		setId = b3AllocId( &world->solverSetIdPool );
		if ( setId == world->solverSets.count )
		{
			// Create a zero initialized solver set. All sub-arrays are also zero initialized.
			b3Array_Push( world->solverSets, (b3SolverSet){ 0 } );
		}
		else
		{
			B3_ASSERT( world->solverSets.data[setId].setIndex == B3_NULL_INDEX );
		}

		world->solverSets.data[setId].setIndex = setId;
	}

	B3_ASSERT( 0 <= setId && setId < world->solverSets.count );

	int bodyId = b3AllocId( &world->bodyIdPool );

	uint32_t lockFlags = 0;
	lockFlags |= def->motionLocks.linearX ? b3_lockLinearX : 0;
	lockFlags |= def->motionLocks.linearY ? b3_lockLinearY : 0;
	lockFlags |= def->motionLocks.linearZ ? b3_lockLinearZ : 0;
	lockFlags |= def->motionLocks.angularX ? b3_lockAngularX : 0;
	lockFlags |= def->motionLocks.angularY ? b3_lockAngularY : 0;
	lockFlags |= def->motionLocks.angularZ ? b3_lockAngularZ : 0;

	b3SolverSet* set = b3Array_Get( world->solverSets, setId );
	b3BodySim* bodySim = b3Array_Emplace( set->bodySims );
	*bodySim = (b3BodySim){ 0 };
	bodySim->transform.p = def->position;
	bodySim->transform.q = def->rotation;
	bodySim->center = def->position;
	bodySim->rotation0 = bodySim->transform.q;
	bodySim->center0 = bodySim->center;
	bodySim->localCenter = b3Vec3_zero;
	bodySim->force = b3Vec3_zero;
	bodySim->torque = b3Vec3_zero;
	bodySim->invMass = 0.0f;
	bodySim->invInertiaLocal = b3Mat3_zero;
	bodySim->minExtent = B3_HUGE;
	bodySim->maxExtent = b3Vec3_zero;
	bodySim->linearDamping = def->linearDamping;
	bodySim->angularDamping = def->angularDamping;
	bodySim->gravityScale = def->gravityScale;
	bodySim->bodyId = bodyId;
	bodySim->flags = lockFlags;
	bodySim->flags |= def->isBullet ? b3_isBullet : 0;
	bodySim->flags |= def->allowFastRotation ? b3_allowFastRotation : 0;
	bodySim->flags |= def->type == b3_dynamicBody ? b3_dynamicFlag : 0;
	bodySim->flags |= def->enableSleep ? b3_enableSleep : 0;
	bodySim->flags |= def->enableContactRecycling ? b3_bodyEnableContactRecycling : 0;

	if ( setId == b3_awakeSet )
	{
		b3BodyState* bodyState = b3Array_Emplace( set->bodyStates );

		*bodyState = (b3BodyState){ 0 };
		bodyState->linearVelocity = def->linearVelocity;
		bodyState->angularVelocity = def->angularVelocity;
		bodyState->deltaRotation = b3Quat_identity;
		bodyState->flags = bodySim->flags;

		bodySim->maxAngularVelocity = b3Length( def->angularVelocity ) + 5.0f;
	}

	if ( bodyId == world->bodies.count )
	{
		b3Array_Push( world->bodies, (b3Body){ 0 } );
	}
	else
	{
		B3_ASSERT( world->bodies.data[bodyId].id == B3_NULL_INDEX );
	}

	b3Body* body = b3Array_Get( world->bodies, bodyId );
	body->userData = def->userData;
	body->setIndex = setId;
	body->localIndex = set->bodySims.count - 1;
	body->generation += 1;
	body->headShapeId = B3_NULL_INDEX;
	body->shapeCount = 0;
	body->headChainId = B3_NULL_INDEX;
	body->headContactKey = B3_NULL_INDEX;
	body->contactCount = 0;
	body->headJointKey = B3_NULL_INDEX;
	body->jointCount = 0;
	body->islandId = B3_NULL_INDEX;
	body->islandIndex = B3_NULL_INDEX;
	body->bodyMoveIndex = B3_NULL_INDEX;
	body->id = bodyId;
	body->sleepThreshold = def->sleepThreshold;
	body->sleepTime = 0.0f;
	body->sleepVelocity = 0.0f;
	body->mass = 0.0f;
	body->inertia = b3Mat3_zero;
	body->nameId = b3AddName( &world->names, def->name );
	body->type = def->type;
	body->flags = bodySim->flags;

	// dynamic and kinematic bodies that are enabled need a island
	if ( setId >= b3_awakeSet )
	{
		b3CreateIslandForBody( world, setId, body );
	}

	b3ValidateSolverSets( world );

	b3BodyId id = { bodyId + 1, world->worldId, body->generation };

	world->locked = false;

	B3_REC_CREATE( world, CreateBody, id, worldId, *def );

	return id;
}

bool b3IsBodyAwake( b3World* world, b3Body* body )
{
	B3_UNUSED( world );
	return body->setIndex == b3_awakeSet;
}

bool b3WakeBody( b3World* world, b3Body* body )
{
	if ( body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeSolverSet( world, body->setIndex );
		b3ValidateSolverSets( world );
		return true;
	}

	return false;
}

bool b3WakeBodyWithLock( b3World* world, b3Body* body )
{
	B3_ASSERT( world->locked == false );
	world->locked = true;
	bool woke = b3WakeBody( world, body );
	world->locked = false;
	return woke;
}

void b3DestroyBody( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, DestroyBody, bodyId );

	world->locked = true;

	b3Body* body = b3GetBodyFullId( world, bodyId );

	// Wake bodies attached to this body, even if this body is static.
	bool wakeBodies = true;

	// Destroy the attached joints
	int edgeKey = body->headJointKey;
	while ( edgeKey != B3_NULL_INDEX )
	{
		int jointId = edgeKey >> 1;
		int edgeIndex = edgeKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		edgeKey = joint->edges[edgeIndex].nextKey;

		// Careful because this modifies the list being traversed
		b3DestroyJointInternal( world, joint, wakeBodies );
	}

	// Destroy all contacts attached to this body.
	b3DestroyBodyContacts( world, body, wakeBodies );

	// Destroy the attached shapes and their broad-phase proxies.
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );

		if ( shape->sensorIndex != B3_NULL_INDEX )
		{
			b3DestroySensor( world, shape );
		}

		b3DestroyShapeProxy( shape, &world->broadPhase );

		b3DestroyShapeAllocations( world, shape );

		// Return shape to free list.
		b3FreeId( &world->shapeIdPool, shapeId );
		shape->id = B3_NULL_INDEX;

		shapeId = shape->nextShapeId;
	}

	b3RemoveBodyFromIsland( world, body );

	// Remove body sim from solver set that owns it
	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );
	int movedIndex = b3Array_RemoveSwap( set->bodySims, body->localIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		// Fix moved body index
		b3BodySim* movedSim = set->bodySims.data + body->localIndex;
		int movedId = movedSim->bodyId;
		b3Body* movedBody = b3Array_Get( world->bodies, movedId );
		B3_ASSERT( movedBody->localIndex == movedIndex );
		movedBody->localIndex = body->localIndex;
	}

	// Remove body state from awake set
	if ( body->setIndex == b3_awakeSet )
	{
		int result = b3Array_RemoveSwap( set->bodyStates, body->localIndex );
		B3_UNUSED( result );
		B3_ASSERT( result == movedIndex );
	}
	else if ( set->setIndex >= b3_firstSleepingSet && set->bodySims.count == 0 )
	{
		// Remove solver set if it's now an orphan.
		b3DestroySolverSet( world, set->setIndex );
	}

	// Free body and id (preserve body revision)
	b3FreeId( &world->bodyIdPool, body->id );

	body->setIndex = B3_NULL_INDEX;
	body->localIndex = B3_NULL_INDEX;
	body->id = B3_NULL_INDEX;

	b3ValidateSolverSets( world );

	world->locked = false;
}

int b3Body_GetContactCapacity( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );

	// Conservative and fast
	return body->contactCount;
}

int b3Body_GetContactData( b3BodyId bodyId, b3ContactData* contactData, int capacity )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );

	int contactKey = body->headContactKey;
	int index = 0;
	while ( contactKey != B3_NULL_INDEX && index < capacity )
	{
		int contactId = contactKey >> 1;
		int edgeIndex = contactKey & 1;

		b3Contact* contact = b3Array_Get( world->contacts, contactId );

		// Is contact touching?
		if ( contact->flags & b3_contactTouchingFlag )
		{
			b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
			b3Shape* shapeB = b3Array_Get( world->shapes, contact->shapeIdB );

			contactData[index].contactId = (b3ContactId){ contact->contactId + 1, bodyId.world0, 0, contact->generation };
			contactData[index].shapeIdA = (b3ShapeId){ shapeA->id + 1, bodyId.world0, shapeA->generation };
			contactData[index].shapeIdB = (b3ShapeId){ shapeB->id + 1, bodyId.world0, shapeB->generation };
			contactData[index].manifolds = contact->manifolds;
			contactData[index].manifoldCount = contact->manifoldCount;
			index += 1;
		}

		contactKey = contact->edges[edgeIndex].nextKey;
	}

	B3_ASSERT( index <= capacity );

	return index;
}

b3AABB b3Body_ComputeAABB( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return (b3AABB){ 0 };
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( body->headShapeId == B3_NULL_INDEX )
	{
		b3WorldTransform transform = b3GetBodyTransform( world, body->id );
		b3Vec3 p = b3ToVec3( transform.p );
		return (b3AABB){ p, p };
	}

	b3Shape* shape = b3Array_Get( world->shapes, body->headShapeId );
	b3AABB aabb = shape->aabb;
	while ( shape->nextShapeId != B3_NULL_INDEX )
	{
		shape = b3Array_Get( world->shapes, shape->nextShapeId );
		aabb = b3AABB_Union( aabb, shape->aabb );
	}

	return aabb;
}

float b3Body_GetClosestPoint( b3BodyId bodyId, b3Vec3* result, b3Vec3 target )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		*result = (b3Vec3){ 0 };
		return 0.0f;
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform worldTransform = b3GetBodyTransform( world, body->id );
	b3Transform transform = b3ToRelativeTransform( worldTransform, b3Pos_zero );

	float closestDistance = FLT_MAX;
	b3Vec3 closestPoint = transform.p;

	b3DistanceInput input = { 0 };
	input.proxyA = (b3ShapeProxy){ &target, 1, 0.0f };

	// Target rides in frame A at the origin, so the relative pose of the shape in A is the body transform
	input.transform = transform;
	input.useRadii = false;

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		b3ShapeType type = shape->type;
		if ( type != b3_sphereShape && type != b3_capsuleShape && type != b3_hullShape )
		{
			continue;
		}

		input.proxyB = b3MakeShapeProxy( shape );

		b3SimplexCache cache = { 0 };
		b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );
		if ( output.distance < closestDistance )
		{
			closestDistance = output.distance;
			closestPoint = output.pointB;
		}
	}

	*result = closestPoint;
	return closestDistance;
}

b3BodyCastResult b3Body_CastRay( b3BodyId bodyId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter, float maxFraction,
								 b3WorldTransform bodyTransform )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return (b3BodyCastResult){ 0 };
	}

	b3BodyCastResult result = { 0 };
	b3Body* body = b3GetBodyFullId( world, bodyId );

	// The consistent framing is to center on the ray origin.
	b3RayCastInput shapeInput = { 0 };
	shapeInput.origin = b3Vec3_zero;
	shapeInput.translation = translation;
	shapeInput.maxFraction = maxFraction;

	b3Transform transform = b3ToRelativeTransform( bodyTransform, origin );

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		if ( b3ShouldQueryCollide( &shape->filter, &filter ) == false )
		{
			continue;
		}

		b3CastOutput shapeOutput = b3RayCastShape( shape, transform, &shapeInput );

		if ( shapeOutput.hit == false )
		{
			continue;
		}

		if ( shapeOutput.fraction > shapeInput.maxFraction )
		{
			continue;
		}

		// Careful with id, shapeId is the next shape.
		b3ShapeId id = { shape->id + 1, bodyId.world0, shape->generation };

		int materialIndex = b3ClampInt( shapeOutput.materialIndex, 0, shape->materialCount - 1 );
		uint64_t userMaterialId = b3GetShapeMaterials( shape )[materialIndex].userMaterialId;

		result = (b3BodyCastResult){
			.shapeId = id,
			.point = b3OffsetPos( origin, shapeOutput.point ),
			.normal = shapeOutput.normal,
			.fraction = shapeOutput.fraction,
			.triangleIndex = shapeOutput.triangleIndex,
			.userMaterialId = userMaterialId,
			.iterations = shapeOutput.iterations,
			.hit = true,
		};

		shapeInput.maxFraction = shapeOutput.fraction;
	}

	return result;
}

b3BodyCastResult b3Body_CastShape( b3BodyId bodyId, b3Pos origin, const b3ShapeProxy* proxy, b3Vec3 translation,
								   b3QueryFilter filter, float maxFraction, bool canEncroach, b3WorldTransform bodyTransform )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return (b3BodyCastResult){ 0 };
	}

	b3BodyCastResult result = { 0 };
	b3Body* body = b3GetBodyFullId( world, bodyId );

	b3Transform transform = b3ToRelativeTransform( bodyTransform, origin );

	b3ShapeCastInput shapeInput = { 0 };
	shapeInput.proxy = *proxy;
	shapeInput.translation = translation;
	shapeInput.maxFraction = maxFraction;
	shapeInput.canEncroach = canEncroach;

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		if ( b3ShouldQueryCollide( &shape->filter, &filter ) == false )
		{
			continue;
		}

		b3CastOutput shapeOutput = b3ShapeCastShape( shape, transform, &shapeInput );

		if ( shapeOutput.hit == false )
		{
			continue;
		}

		if ( shapeOutput.fraction > shapeInput.maxFraction )
		{
			continue;
		}

		// Careful with id, shapeId is the next shape.
		b3ShapeId id = { shape->id + 1, bodyId.world0, shape->generation };
		int materialIndex = b3ClampInt( shapeOutput.materialIndex, 0, shape->materialCount - 1 );
		uint64_t userMaterialId = b3GetShapeMaterials( shape )[materialIndex].userMaterialId;

		result = (b3BodyCastResult){
			.shapeId = id,
			.point = b3OffsetPos( origin, shapeOutput.point ),
			.normal = shapeOutput.normal,
			.fraction = shapeOutput.fraction,
			.triangleIndex = shapeOutput.triangleIndex,
			.userMaterialId = userMaterialId,
			.iterations = shapeOutput.iterations,
			.hit = true,
		};

		shapeInput.maxFraction = shapeOutput.fraction;
	}

	return result;
}

bool b3Body_OverlapShape( b3BodyId bodyId, b3Pos origin, const b3ShapeProxy* proxy, b3QueryFilter filter,
						  b3WorldTransform bodyTransform )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return false;
	}

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3Transform transform = b3ToRelativeTransform( bodyTransform, origin );

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		if ( b3ShouldQueryCollide( &shape->filter, &filter ) == false )
		{
			continue;
		}

		bool overlaps = b3OverlapShape( shape, transform, proxy );
		if ( overlaps )
		{
			return true;
		}
	}

	return false;
}

int b3Body_CollideMover( b3BodyId bodyId, b3BodyPlaneResult* bodyPlanes, int planeCapacity, b3Pos origin, const b3Capsule* mover,
						 b3QueryFilter filter, b3WorldTransform bodyTransform )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return 0;
	}

	if ( planeCapacity == 0 )
	{
		return 0;
	}

	int resultCount = 0;
	b3Body* body = b3GetBodyFullId( world, bodyId );

	b3Transform transform = b3ToRelativeTransform( bodyTransform, origin );

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		if ( b3ShouldQueryCollide( &shape->filter, &filter ) == false )
		{
			continue;
		}

		b3ShapeType type = shape->type;
		if ( type != b3_sphereShape && type != b3_capsuleShape && type != b3_hullShape )
		{
			continue;
		}

		b3PlaneResult plane;
		int count = b3CollideMover( &plane, 1, shape, transform, mover );

		if ( count > 0 )
		{
			b3ShapeId id = { shape->id + 1, bodyId.world0, shape->generation };
			bodyPlanes[resultCount] = (b3BodyPlaneResult){ .shapeId = id, .result = plane };
			resultCount += 1;
			if ( resultCount == planeCapacity )
			{
				return resultCount;
			}
		}
	}

	return resultCount;
}

void b3UpdateBodyMassData( b3World* world, b3Body* body )
{
	b3BodySim* bodySim = b3GetBodySim( world, body );

	// Mass is no longer dirty
	body->flags &= ~b3_dirtyMass;
	b3SyncBodyFlags( world, body );

	// Compute mass data from shapes. Each shape has its own density.
	body->mass = 0.0f;
	body->inertia = b3Mat3_zero;

	bodySim->invMass = 0.0f;
	bodySim->invInertiaLocal = b3Mat3_zero;
	bodySim->invInertiaWorld = b3Mat3_zero;
	bodySim->localCenter = b3Vec3_zero;
	bodySim->minExtent = B3_HUGE;
	bodySim->maxExtent = b3Vec3_zero;

	if ( body->headShapeId == B3_NULL_INDEX )
	{
		return;
	}

	// Static and kinematic sims have zero mass.
	if ( body->type != b3_dynamicBody )
	{
		bodySim->center = bodySim->transform.p;
		bodySim->center0 = bodySim->center;

		// Need extents for kinematic bodies for sleeping to work correctly.
		if ( body->type == b3_kinematicBody )
		{
			int shapeId = body->headShapeId;
			while ( shapeId != B3_NULL_INDEX )
			{
				const b3Shape* s = b3Array_Get( world->shapes, shapeId );

				b3ShapeExtent extent = b3ComputeShapeExtent( s, b3Vec3_zero );
				bodySim->minExtent = b3MinFloat( bodySim->minExtent, extent.minExtent );
				bodySim->maxExtent = b3Max( bodySim->maxExtent, extent.maxExtent );

				shapeId = s->nextShapeId;
			}
		}

		return;
	}

	int shapeCount = body->shapeCount;
	b3MassData* masses = b3StackAlloc( &world->stack, shapeCount * sizeof( b3MassData ), "mass data" );

	// Accumulate mass over all shapes.
	b3Vec3 localCenter = b3Vec3_zero;
	int shapeId = body->headShapeId;
	int shapeIndex = 0;
	while ( shapeId != B3_NULL_INDEX )
	{
		const b3Shape* s = b3Array_Get( world->shapes, shapeId );
		shapeId = s->nextShapeId;

		if ( s->density == 0.0f )
		{
			masses[shapeIndex] = (b3MassData){ 0 };
			shapeIndex += 1;
			continue;
		}

		b3MassData massData = b3ComputeShapeMass( s );
		body->mass += massData.mass;
		localCenter = b3MulAdd( localCenter, massData.mass, massData.center );

		masses[shapeIndex] = massData;
		shapeIndex += 1;
	}

	// Compute center of mass.
	if ( body->mass > 0.0f )
	{
		bodySim->invMass = 1.0f / body->mass;
		localCenter = b3MulSV( bodySim->invMass, localCenter );
	}

	// Second loop to accumulate the rotational inertia about the center of mass
	for ( shapeIndex = 0; shapeIndex < shapeCount; ++shapeIndex )
	{
		b3MassData massData = masses[shapeIndex];
		if ( massData.mass == 0.0f )
		{
			continue;
		}

		// Shift to center of mass. This is safe because it can only increase.
		b3Vec3 offset = b3Sub( localCenter, massData.center );
		b3Matrix3 inertia = b3AddMM( massData.inertia, b3Steiner( massData.mass, offset ) );
		body->inertia = b3AddMM( body->inertia, inertia );
	}

	b3StackFree( &world->stack, masses );
	masses = NULL;

	float det = b3Det( body->inertia );
	B3_ASSERT( det >= 0.0f );

	if ( det > 0.0f )
	{
		// This call is faster than b3Invert
		bodySim->invInertiaLocal = b3InvertT( body->inertia );

		b3Matrix3 rotationMatrix = b3MakeMatrixFromQuat( bodySim->transform.q );
		bodySim->invInertiaWorld = b3MulMM( b3MulMM( rotationMatrix, bodySim->invInertiaLocal ), b3Transpose( rotationMatrix ) );
	}

	// Move center of mass.
	b3Pos oldCenter = bodySim->center;
	bodySim->localCenter = localCenter;
	bodySim->center = b3TransformWorldPoint( bodySim->transform, bodySim->localCenter );
	bodySim->center0 = bodySim->center;

	// Update center of mass velocity
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state != NULL )
	{
		b3Vec3 deltaLinear = b3Cross( state->angularVelocity, b3SubPos( bodySim->center, oldCenter ) );
		state->linearVelocity = b3Add( state->linearVelocity, deltaLinear );
	}

	// Compute body extents relative to center of mass
	shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* s = b3Array_Get( world->shapes, shapeId );

		b3ShapeExtent extent = b3ComputeShapeExtent( s, localCenter );
		bodySim->minExtent = b3MinFloat( bodySim->minExtent, extent.minExtent );
		bodySim->maxExtent = b3Max( bodySim->maxExtent, extent.maxExtent );

		shapeId = s->nextShapeId;
	}

	// Apply fixed rotation
	if ( ( bodySim->flags & b3_fixedRotation ) == b3_fixedRotation )
	{
		body->inertia = b3Mat3_zero;
		bodySim->invInertiaLocal = b3Mat3_zero;
		bodySim->invInertiaWorld = b3Mat3_zero;
	}
}

b3Pos b3Body_GetPosition( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return transform.p;
}

b3Quat b3Body_GetRotation( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return transform.q;
}

b3WorldTransform b3Body_GetTransform( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return b3GetBodyTransformQuick( world, body );
}

b3Vec3 b3Body_GetLocalPoint( b3BodyId bodyId, b3Pos worldPoint )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return b3InvTransformWorldPoint( transform, worldPoint );
}

b3Pos b3Body_GetWorldPoint( b3BodyId bodyId, b3Vec3 localPoint )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return b3TransformWorldPoint( transform, localPoint );
}

b3Vec3 b3Body_GetLocalVector( b3BodyId bodyId, b3Vec3 worldVector )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return b3InvRotateVector( transform.q, worldVector );
}

b3Vec3 b3Body_GetWorldVector( b3BodyId bodyId, b3Vec3 localVector )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	return b3RotateVector( transform.q, localVector );
}

void b3Body_SetTransform( b3BodyId bodyId, b3Pos position, b3Quat rotation )
{
	B3_ASSERT( b3IsValidPosition( position ) );
	B3_ASSERT( b3IsValidQuat( rotation ) );
	B3_ASSERT( b3Body_IsValid( bodyId ) );
	b3World* world = b3GetWorld( bodyId.world0 );
	B3_ASSERT( world->locked == false );

	B3_REC( world, BodySetTransform, bodyId, position, rotation );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );

	bodySim->transform.p = position;
	bodySim->transform.q = rotation;
	bodySim->center = b3TransformWorldPoint( bodySim->transform, bodySim->localCenter );

	b3Matrix3 rotationMatrix = b3MakeMatrixFromQuat( bodySim->transform.q );
	bodySim->invInertiaWorld = b3MulMM( b3MulMM( rotationMatrix, bodySim->invInertiaLocal ), b3Transpose( rotationMatrix ) );

	bodySim->rotation0 = bodySim->transform.q;
	bodySim->center0 = bodySim->center;

	b3BroadPhase* broadPhase = &world->broadPhase;

	b3WorldTransform transform = bodySim->transform;
	const float speculativeDistance = B3_SPECULATIVE_DISTANCE;

	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		b3AABB aabb = b3ComputeFatShapeAABB( shape, transform, speculativeDistance );
		shape->aabb = aabb;

		if ( b3AABB_Contains( shape->fatAABB, aabb ) == false )
		{
			float margin = shape->aabbMargin;
			b3AABB fatAABB;
			fatAABB.lowerBound.x = aabb.lowerBound.x - margin;
			fatAABB.lowerBound.y = aabb.lowerBound.y - margin;
			fatAABB.lowerBound.z = aabb.lowerBound.z - margin;
			fatAABB.upperBound.x = aabb.upperBound.x + margin;
			fatAABB.upperBound.y = aabb.upperBound.y + margin;
			fatAABB.upperBound.z = aabb.upperBound.z + margin;
			shape->fatAABB = fatAABB;

			// The body could be disabled
			if ( shape->proxyKey != B3_NULL_INDEX )
			{
				b3BroadPhase_MoveProxy( broadPhase, shape->proxyKey, fatAABB );
			}
		}

		shapeId = shape->nextShapeId;
	}
}

b3Vec3 b3Body_GetLinearVelocity( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state != NULL )
	{
		return state->linearVelocity;
	}
	return b3Vec3_zero;
}

b3Vec3 b3Body_GetAngularVelocity( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state != NULL )
	{
		return state->angularVelocity;
	}
	return b3Vec3_zero;
}

void b3Body_SetLinearVelocity( b3BodyId bodyId, b3Vec3 linearVelocity )
{
	B3_ASSERT( b3IsValidVec3( linearVelocity ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodySetLinearVelocity, bodyId, linearVelocity );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( body->type == b3_staticBody )
	{
		return;
	}

	if ( b3LengthSquared( linearVelocity ) > 0.0f )
	{
		b3WakeBodyWithLock( world, body );
	}

	b3BodyState* state = b3GetBodyState( world, body );
	if ( state == NULL )
	{
		return;
	}

	state->linearVelocity = linearVelocity;
}

void b3Body_SetAngularVelocity( b3BodyId bodyId, b3Vec3 angularVelocity )
{
	B3_ASSERT( b3IsValidVec3( angularVelocity ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodySetAngularVelocity, bodyId, angularVelocity );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( body->type == b3_staticBody )
	{
		return;
	}

	// Apply locks to avoid waking
	b3Vec3 w;
	w.x = ( body->flags & b3_lockAngularX ) ? 0.0f : angularVelocity.x;
	w.y = ( body->flags & b3_lockAngularY ) ? 0.0f : angularVelocity.y;
	w.z = ( body->flags & b3_lockAngularZ ) ? 0.0f : angularVelocity.z;

	if ( b3LengthSquared( w ) != 0.0f )
	{
		b3WakeBodyWithLock( world, body );
	}

	b3BodyState* state = b3GetBodyState( world, body );
	if ( state == NULL )
	{
		return;
	}

	state->angularVelocity = w;
}

void b3Body_SetTargetTransform( b3BodyId bodyId, b3WorldTransform target, float timeStep, bool wake )
{
	B3_ASSERT( b3IsValidWorldTransform( target ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodySetTargetTransform, bodyId, target, timeStep, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( body->setIndex == b3_disabledSet )
	{
		return;
	}

	if ( body->type == b3_staticBody || timeStep <= 0.0f )
	{
		return;
	}

	if ( body->setIndex != b3_awakeSet && wake == false )
	{
		return;
	}

	b3BodySim* sim = b3GetBodySim( world, body );

	// Compute linear velocity. The center difference is taken in world precision then demoted.
	b3Pos center1 = sim->center;
	b3Pos center2 = b3TransformWorldPoint( target, sim->localCenter );
	float invTimeStep = 1.0f / timeStep;
	b3Vec3 linearVelocity = b3MulSV( invTimeStep, b3SubPos( center2, center1 ) );

	// Compute angular velocity:
	// q' = 0.5 * w * q
	// <~> ( q2 - q1 ) / dt =  0.5 * w * q1
	// <=> w = 2 * ( q2 - q1 ) * Conjugate( q1 ) / dt
	b3Quat q1 = sim->transform.q;
	b3Quat q2 = target.q;

	// Use the shortest arc quaternion
	if ( b3DotQuat( q1, q2 ) < 0.0f )
	{
		q2 = b3NegateQuat( q2 );
	}

	b3Quat dq = { b3Sub( q2.v, q1.v ), q2.s - q1.s };
	b3Quat omega = b3MulQuat( dq, b3Conjugate( q1 ) );
	b3Vec3 angularVelocity = b3MulSV( 2.0f * invTimeStep, omega.v );

	// Early out if the body is asleep already and the desired movement is small
	if ( body->setIndex != b3_awakeSet )
	{
		float maxVelocity = b3Length( linearVelocity ) + b3Length( b3Mul( angularVelocity, sim->maxExtent ) );

		// Return if velocity would be sleepy
		if ( maxVelocity < body->sleepThreshold )
		{
			return;
		}

		// Must wake for state to exist
		b3WakeBodyWithLock( world, body );
	}

	B3_ASSERT( body->setIndex == b3_awakeSet );

	b3BodyState* state = b3GetBodyState( world, body );
	state->linearVelocity = linearVelocity;
	state->angularVelocity = angularVelocity;
}

b3Vec3 b3Body_GetLocalPointVelocity( b3BodyId bodyId, b3Vec3 localPoint )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state == NULL )
	{
		return b3Vec3_zero;
	}

	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );
	b3BodySim* bodySim = b3Array_Get( set->bodySims, body->localIndex );

	b3Vec3 r = b3RotateVector( bodySim->transform.q, b3Sub( localPoint, bodySim->localCenter ) );
	b3Vec3 v = b3Add( state->linearVelocity, b3Cross( state->angularVelocity, r ) );
	return v;
}

b3Vec3 b3Body_GetWorldPointVelocity( b3BodyId bodyId, b3Pos worldPoint )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state == NULL )
	{
		return b3Vec3_zero;
	}

	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );
	b3BodySim* bodySim = b3Array_Get( set->bodySims, body->localIndex );

	b3Vec3 r = b3SubPos( worldPoint, bodySim->center );
	b3Vec3 v = b3Add( state->linearVelocity, b3Cross( state->angularVelocity, r ) );
	return v;
}

void b3Body_ApplyForce( b3BodyId bodyId, b3Vec3 force, b3Pos point, bool wake )
{
	B3_ASSERT( b3IsValidVec3( force ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyForce, bodyId, force, point, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		b3BodySim* bodySim = b3GetBodySim( world, body );
		bodySim->force = b3Add( bodySim->force, force );
		bodySim->torque = b3Add( bodySim->torque, b3Cross( b3SubPos( point, bodySim->center ), force ) );
	}
}

void b3Body_ApplyForceToCenter( b3BodyId bodyId, b3Vec3 force, bool wake )
{
	B3_ASSERT( b3IsValidVec3( force ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyForceToCenter, bodyId, force, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		b3BodySim* bodySim = b3GetBodySim( world, body );
		bodySim->force = b3Add( bodySim->force, force );
	}
}

void b3Body_ApplyTorque( b3BodyId bodyId, b3Vec3 torque, bool wake )
{
	B3_ASSERT( b3IsValidVec3( torque ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyTorque, bodyId, torque, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		b3BodySim* bodySim = b3GetBodySim( world, body );
		bodySim->torque = b3Add( bodySim->torque, torque );
	}
}

void b3Body_ApplyLinearImpulse( b3BodyId bodyId, b3Vec3 impulse, b3Pos point, bool wake )
{
	B3_ASSERT( b3IsValidVec3( impulse ) );
	B3_ASSERT( b3IsValidPosition( point ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyLinearImpulse, bodyId, impulse, point, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		int localIndex = body->localIndex;
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
		b3BodyState* state = b3Array_Get( set->bodyStates, localIndex );
		b3BodySim* bodySim = b3Array_Get( set->bodySims, localIndex );

		state->linearVelocity = b3MulAdd( state->linearVelocity, bodySim->invMass, impulse );

		float maxLinearSpeed = world->maxLinearSpeed;
		if ( b3LengthSquared( state->linearVelocity ) > maxLinearSpeed * maxLinearSpeed )
		{
			state->linearVelocity = b3MulSV( maxLinearSpeed, b3Normalize( state->linearVelocity ) );
		}

		b3Vec3 delta = b3MulMV( bodySim->invInertiaWorld, b3Cross( b3SubPos( point, bodySim->center ), impulse ) );
		state->angularVelocity = b3Add( state->angularVelocity, delta );
	}
}

void b3Body_ApplyLinearImpulseToCenter( b3BodyId bodyId, b3Vec3 impulse, bool wake )
{
	B3_ASSERT( b3IsValidVec3( impulse ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyLinearImpulseToCenter, bodyId, impulse, wake );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		int localIndex = body->localIndex;
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
		b3BodyState* state = b3Array_Get( set->bodyStates, localIndex );
		b3BodySim* bodySim = b3Array_Get( set->bodySims, localIndex );
		state->linearVelocity = b3MulAdd( state->linearVelocity, bodySim->invMass, impulse );

		float maxLinearSpeed = world->maxLinearSpeed;
		if ( b3LengthSquared( state->linearVelocity ) > maxLinearSpeed * maxLinearSpeed )
		{
			state->linearVelocity = b3MulSV( maxLinearSpeed, b3Normalize( state->linearVelocity ) );
		}
	}
}

void b3Body_ApplyAngularImpulse( b3BodyId bodyId, b3Vec3 impulse, bool wake )
{
	B3_ASSERT( b3IsValidVec3( impulse ) );
	B3_ASSERT( b3Body_IsValid( bodyId ) );

	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyApplyAngularImpulse, bodyId, impulse, wake );

	int id = bodyId.index1 - 1;
	b3Body* body = b3Array_Get( world->bodies, id );
	B3_ASSERT( body->generation == bodyId.generation );

	if ( wake && body->setIndex >= b3_firstSleepingSet )
	{
		// this will not invalidate body pointer
		b3WakeBodyWithLock( world, body );
	}

	if ( body->setIndex == b3_awakeSet )
	{
		int localIndex = body->localIndex;
		b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
		b3BodyState* state = b3Array_Get( set->bodyStates, localIndex );
		b3BodySim* bodySim = b3Array_Get( set->bodySims, localIndex );

		b3Vec3 localImpulse = b3InvRotateVector( bodySim->transform.q, impulse );
		b3Vec3 localAngularVelocityDelta = b3MulMV( bodySim->invInertiaLocal, localImpulse );
		state->angularVelocity =
			b3Add( state->angularVelocity, b3RotateVector( bodySim->transform.q, localAngularVelocityDelta ) );
	}
}

b3BodyType b3Body_GetType( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->type;
}

// This should follow similar steps as you would get destroying and recreating the body, shapes, and joints.
// Contacts are difficult to preserve because the broad-phase pairs change, so I just destroy them.
// todo with a bit more effort I could support an option to let the body sleep
//
// Revised steps:
// 1 Skip disabled bodies
// 2 Destroy all contacts on the body
// 3 Wake the body
// 4 For all joints attached to the body
//  - wake attached bodies
//  - remove from island
//  - move to static set temporarily
// 5 Change the body type and transfer the body
// 6 If the body was static
//   - create an island for the body
//   Else if the body is becoming static
//   - remove it from the island
// 7 For all joints
//  - if either body is non-static
//    - link into island
//    - transfer to constraint graph
// 8 For all shapes
//  - Destroy proxy in old tree
//  - Create proxy in new tree
// Notes:
// - the implementation below tries to minimize the number of predicates, so some
//   operations may have no effect, such as transferring a joint to the same set
void b3Body_SetType( b3BodyId bodyId, b3BodyType type )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetType, bodyId, (int32_t)type );

	world->locked = true;
	b3Body* body = b3GetBodyFullId( world, bodyId );

	b3BodyType originalType = body->type;
	if ( originalType == type )
	{
		world->locked = false;
		return;
	}

	if ( type != b3_staticBody )
	{
		int shapeId = body->headShapeId;
		while ( shapeId != B3_NULL_INDEX )
		{
			b3Shape* shape = b3Array_Get( world->shapes, shapeId );
			if ( shape->type == b3_compoundShape || shape->type == b3_heightShape )
			{
				// Setting the body type is not supported for bodies with compound shapes
				return;
			}

			shapeId = shape->nextShapeId;
		}
	}

	// Stage 1: skip disabled bodies
	if ( body->setIndex == b3_disabledSet )
	{
		// Disabled bodies don't change solver sets or islands when they change type.
		body->type = type;

		if ( type == b3_dynamicBody )
		{
			body->flags |= b3_dynamicFlag;
		}
		else
		{
			body->flags &= ~b3_dynamicFlag;
		}

		b3SyncBodyFlags( world, body );

		// Body type affects the mass properties
		b3UpdateBodyMassData( world, body );
		world->locked = false;
		return;
	}

	// Stage 2: destroy all contacts but don't wake bodies (because we don't need to)
	bool wakeBodies = false;
	b3DestroyBodyContacts( world, body, wakeBodies );

	// Stage 3: wake this body (does nothing if body is static), otherwise it will also wake
	// all bodies in the same sleeping solver set.
	b3WakeBody( world, body );

	// Stage 4: move joints to temporary storage
	b3SolverSet* staticSet = b3Array_Get( world->solverSets, b3_staticSet );

	int jointKey = body->headJointKey;
	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		jointKey = joint->edges[edgeIndex].nextKey;

		// Joint may be disabled by other body
		if ( joint->setIndex == b3_disabledSet )
		{
			continue;
		}

		// Wake attached bodies. The b3WakeBody call above does not wake bodies
		// attached to a static body. But it is necessary because the body may have
		// no joints.
		b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId );
		b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId );
		b3WakeBody( world, bodyA );
		b3WakeBody( world, bodyB );

		// Remove joint from island
		b3UnlinkJoint( world, joint );

		// It is necessary to transfer all joints to the static set
		// so they can be added to the constraint graph below and acquire consistent colors.
		b3SolverSet* jointSourceSet = b3Array_Get( world->solverSets, joint->setIndex );
		b3TransferJoint( world, staticSet, jointSourceSet, joint );
	}

	// Stage 5: change the body type and transfer body
	body->type = type;

	if ( type == b3_dynamicBody )
	{
		body->flags |= b3_dynamicFlag;
	}
	else
	{
		body->flags &= ~b3_dynamicFlag;
	}

	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	b3SolverSet* sourceSet = b3Array_Get( world->solverSets, body->setIndex );
	b3SolverSet* targetSet = type == b3_staticBody ? staticSet : awakeSet;

	// Transfer body
	b3TransferBody( world, targetSet, sourceSet, body );

	// Stage 6: update island participation for the body
	if ( originalType == b3_staticBody )
	{
		// Create island for body
		b3CreateIslandForBody( world, b3_awakeSet, body );
	}
	else if ( type == b3_staticBody )
	{
		// Remove body from island.
		b3RemoveBodyFromIsland( world, body );
	}

	// Stage 7: Transfer joints to the target set
	jointKey = body->headJointKey;
	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );

		jointKey = joint->edges[edgeIndex].nextKey;

		// Joint may be disabled by other body
		if ( joint->setIndex == b3_disabledSet )
		{
			continue;
		}

		// All joints were transferred to the static set in an earlier stage
		B3_ASSERT( joint->setIndex == b3_staticSet );

		b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId );
		b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId );
		B3_ASSERT( bodyA->setIndex == b3_staticSet || bodyA->setIndex == b3_awakeSet );
		B3_ASSERT( bodyB->setIndex == b3_staticSet || bodyB->setIndex == b3_awakeSet );

		if ( bodyA->type == b3_dynamicBody || bodyB->type == b3_dynamicBody )
		{
			b3TransferJoint( world, awakeSet, staticSet, joint );
		}
	}

	// Recreate shape proxies in broadphase
	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );

		// Setting the body type is not supported for bodies with compound shapes
		B3_ASSERT( shape->type != b3_compoundShape );

		shapeId = shape->nextShapeId;
		b3DestroyShapeProxy( shape, &world->broadPhase );
		bool forcePairCreation = true;
		b3CreateShapeProxy( shape, &world->broadPhase, type, transform, forcePairCreation );
	}

	// Relink all joints
	jointKey = body->headJointKey;
	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		jointKey = joint->edges[edgeIndex].nextKey;

		int otherEdgeIndex = edgeIndex ^ 1;
		int otherBodyId = joint->edges[otherEdgeIndex].bodyId;
		b3Body* otherBody = b3Array_Get( world->bodies, otherBodyId );

		if ( otherBody->setIndex == b3_disabledSet )
		{
			continue;
		}

		if ( body->type != b3_dynamicBody && otherBody->type != b3_dynamicBody )
		{
			continue;
		}

		b3LinkJoint( world, joint );
	}

	b3SyncBodyFlags( world, body );

	// Body type affects the mass
	b3UpdateBodyMassData( world, body );

	b3ValidateSolverSets( world );
	b3ValidateIsland( world, body->islandId );

	world->locked = false;
}

void b3Body_SetName( b3BodyId bodyId, const char* name )
{
	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodySetName, bodyId, name );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	body->nameId = b3AddName( &world->names, name );
}

const char* b3Body_GetName( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return b3FindNameWithDefault( &world->names, body->nameId, "" );
}

void b3Body_SetUserData( b3BodyId bodyId, void* userData )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	body->userData = userData;
}

void* b3Body_GetUserData( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->userData;
}

float b3Body_GetMass( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->mass;
}

b3Matrix3 b3Body_GetLocalRotationalInertia( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->inertia;
}

float b3Body_GetInverseMass( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* sim = b3GetBodySim( world, body );
	return sim->invMass;
}

b3Matrix3 b3Body_GetWorldInverseRotationalInertia( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* sim = b3GetBodySim( world, body );
	return sim->invInertiaWorld;
}

b3Vec3 b3Body_GetLocalCenter( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	return bodySim->localCenter;
}

b3Pos b3Body_GetWorldCenter( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	return bodySim->center;
}

void b3Body_SetMassData( b3BodyId bodyId, b3MassData massData )
{
	B3_ASSERT( b3IsValidFloat( massData.mass ) && massData.mass >= 0.0f );
	B3_ASSERT( b3IsValidMatrix3( massData.inertia ) );
	B3_ASSERT( b3IsValidVec3( massData.center ) );

	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetMassData, bodyId, massData );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );

	// Mass is no longer dirty
	body->flags &= ~b3_dirtyMass;
	b3SyncBodyFlags( world, body );

	body->mass = massData.mass;
	body->inertia = massData.inertia;
	bodySim->localCenter = massData.center;

	b3Pos oldCenter = bodySim->center;
	b3Pos center = b3TransformWorldPoint( bodySim->transform, massData.center );
	bodySim->center = center;
	bodySim->center0 = center;
	bodySim->invMass = body->mass > 0.0f ? 1.0f / body->mass : 0.0f;

	// Update center of mass velocity
	b3BodyState* state = b3GetBodyState( world, body );
	if ( state != NULL )
	{
		b3Vec3 deltaLinear = b3Cross( state->angularVelocity, b3SubPos( bodySim->center, oldCenter ) );
		state->linearVelocity = b3Add( state->linearVelocity, deltaLinear );
	}

	float det = b3Det( body->inertia );
	B3_ASSERT( det >= 0.0f );

	if ( det > 0.0f )
	{
		// This call is faster than b3Invert
		bodySim->invInertiaLocal = b3InvertT( body->inertia );

		b3Matrix3 rotationMatrix = b3MakeMatrixFromQuat( bodySim->transform.q );
		bodySim->invInertiaWorld = b3MulMM( b3MulMM( rotationMatrix, bodySim->invInertiaLocal ), b3Transpose( rotationMatrix ) );
	}
	else
	{
		bodySim->invInertiaLocal = b3Mat3_zero;
		bodySim->invInertiaWorld = b3Mat3_zero;
	}

	// Apply fixed rotation
	if ( ( bodySim->flags & b3_fixedRotation ) == b3_fixedRotation )
	{
		body->inertia = b3Mat3_zero;
		bodySim->invInertiaLocal = b3Mat3_zero;
		bodySim->invInertiaWorld = b3Mat3_zero;
	}

	// Update extents using supplied mass center.
	bodySim->minExtent = B3_HUGE;
	bodySim->maxExtent = b3Vec3_zero;
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		const b3Shape* s = b3Array_Get( world->shapes, shapeId );
		b3ShapeExtent extent = b3ComputeShapeExtent( s, massData.center );
		bodySim->minExtent = b3MinFloat( bodySim->minExtent, extent.minExtent );
		bodySim->maxExtent = b3Max( bodySim->maxExtent, extent.maxExtent );
		shapeId = s->nextShapeId;
	}
}

b3MassData b3Body_GetMassData( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	b3MassData massData = { body->mass, bodySim->localCenter, body->inertia };
	return massData;
}

void b3Body_ApplyMassFromShapes( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodyApplyMassFromShapes, bodyId );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3UpdateBodyMassData( world, body );
}

void b3Body_SetLinearDamping( b3BodyId bodyId, float linearDamping )
{
	B3_ASSERT( b3IsValidFloat( linearDamping ) && linearDamping >= 0.0f );

	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetLinearDamping, bodyId, linearDamping );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	bodySim->linearDamping = linearDamping;
}

float b3Body_GetLinearDamping( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	return bodySim->linearDamping;
}

void b3Body_SetAngularDamping( b3BodyId bodyId, float angularDamping )
{
	B3_ASSERT( b3IsValidFloat( angularDamping ) && angularDamping >= 0.0f );

	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetAngularDamping, bodyId, angularDamping );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	bodySim->angularDamping = angularDamping;
}

float b3Body_GetAngularDamping( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	return bodySim->angularDamping;
}

void b3Body_SetGravityScale( b3BodyId bodyId, float gravityScale )
{
	B3_ASSERT( b3Body_IsValid( bodyId ) );
	B3_ASSERT( b3IsValidFloat( gravityScale ) );

	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetGravityScale, bodyId, gravityScale );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	bodySim->gravityScale = gravityScale;
}

float b3Body_GetGravityScale( b3BodyId bodyId )
{
	B3_ASSERT( b3Body_IsValid( bodyId ) );
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	b3BodySim* bodySim = b3GetBodySim( world, body );
	return bodySim->gravityScale;
}

bool b3Body_IsAwake( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->setIndex == b3_awakeSet;
}

void b3Body_SetAwake( b3BodyId bodyId, bool awake )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetAwake, bodyId, awake );

	world->locked = true;

	b3Body* body = b3GetBodyFullId( world, bodyId );

	if ( awake && body->setIndex >= b3_firstSleepingSet )
	{
		b3WakeBody( world, body );
	}
	else if ( awake == false && body->setIndex == b3_awakeSet )
	{
		b3Island* island = b3Array_Get( world->islands, body->islandId );
		if ( island->constraintRemoveCount > 0 )
		{
			// Must split the island before sleeping. This is expensive.
			b3SplitIsland( world, body->islandId );
		}

		b3TrySleepIsland( world, body->islandId );
	}

	world->locked = false;
}

bool b3Body_IsEnabled( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->setIndex != b3_disabledSet;
}

bool b3Body_IsSleepEnabled( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return ( body->flags & b3_enableSleep ) == b3_enableSleep;
}

void b3Body_SetSleepThreshold( b3BodyId bodyId, float sleepThreshold )
{
	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodySetSleepThreshold, bodyId, sleepThreshold );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	body->sleepThreshold = sleepThreshold;
}

float b3Body_GetSleepThreshold( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->sleepThreshold;
}

void b3Body_EnableSleep( b3BodyId bodyId, bool enableSleep )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodyEnableSleep, bodyId, enableSleep );

	b3Body* body = b3GetBodyFullId( world, bodyId );

	bool flag = ( body->flags & b3_enableSleep ) == b3_enableSleep;
	if ( enableSleep == flag )
	{
		return;
	}

	world->locked = true;

	body->flags = enableSleep ? body->flags | b3_enableSleep : body->flags & ~b3_enableSleep;
	b3SyncBodyFlags( world, body );

	if ( enableSleep == false )
	{
		b3WakeBody( world, body );
	}

	world->locked = false;
}

// Disabling a body requires a lot of detailed bookkeeping, but it is a valuable feature.
// The most challenging aspect that joints may connect to bodies that are not disabled.
void b3Body_Disable( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodyDisable, bodyId );

	world->locked = true;

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( body->setIndex == b3_disabledSet )
	{
		world->locked = false;
		return;
	}

	// Destroy contacts and wake bodies touching this body. This avoid floating bodies.
	// This is necessary even for static bodies.
	bool wakeBodies = true;
	b3DestroyBodyContacts( world, body, wakeBodies );

	// The current solver set of the body
	b3SolverSet* set = b3Array_Get( world->solverSets, body->setIndex );

	// Disabled bodies and connected joints are moved to the disabled set
	b3SolverSet* disabledSet = b3Array_Get( world->solverSets, b3_disabledSet );

	// Unlink joints and transfer them to the disabled set
	int jointKey = body->headJointKey;
	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		jointKey = joint->edges[edgeIndex].nextKey;

		// joint may already be disabled by other body
		if ( joint->setIndex == b3_disabledSet )
		{
			continue;
		}

		B3_ASSERT( joint->setIndex == set->setIndex || set->setIndex == b3_staticSet );

		// Remove joint from island
		b3UnlinkJoint( world, joint );

		// Transfer joint to disabled set
		b3SolverSet* jointSet = b3Array_Get( world->solverSets, joint->setIndex );
		b3TransferJoint( world, disabledSet, jointSet, joint );
	}

	// Remove shapes from broad-phase
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;
		b3DestroyShapeProxy( shape, &world->broadPhase );
	}

	// Disabled bodies are not in an island. If the island becomes empty it will be destroyed.
	b3RemoveBodyFromIsland( world, body );

	// Transfer body sim
	b3TransferBody( world, disabledSet, set, body );

	b3ValidateConnectivity( world );
	b3ValidateSolverSets( world );

	world->locked = false;
}

void b3Body_Enable( b3BodyId bodyId )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodyEnable, bodyId );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( body->setIndex != b3_disabledSet )
	{
		return;
	}

	b3SolverSet* disabledSet = b3Array_Get( world->solverSets, b3_disabledSet );
	int setId = body->type == b3_staticBody ? b3_staticSet : b3_awakeSet;
	b3SolverSet* targetSet = b3Array_Get( world->solverSets, setId );

	b3TransferBody( world, targetSet, disabledSet, body );

	b3WorldTransform transform = b3GetBodyTransformQuick( world, body );

	// Add shapes to broad-phase
	b3BodyType proxyType = body->type;
	bool forcePairCreation = true;
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shapeId = shape->nextShapeId;

		b3CreateShapeProxy( shape, &world->broadPhase, proxyType, transform, forcePairCreation );
	}

	if ( setId != b3_staticSet )
	{
		b3CreateIslandForBody( world, setId, body );
	}

	// Transfer joints. If the other body is disabled, don't transfer.
	// If the other body is sleeping, wake it.
	int jointKey = body->headJointKey;
	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		B3_ASSERT( joint->setIndex == b3_disabledSet );
		B3_ASSERT( joint->islandId == B3_NULL_INDEX );

		jointKey = joint->edges[edgeIndex].nextKey;

		b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId );
		b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId );

		if ( bodyA->setIndex == b3_disabledSet || bodyB->setIndex == b3_disabledSet )
		{
			// one body is still disabled
			continue;
		}

		// Transfer joint first
		int jointSetId;
		if ( bodyA->setIndex == b3_staticSet && bodyB->setIndex == b3_staticSet )
		{
			jointSetId = b3_staticSet;
		}
		else if ( bodyA->setIndex == b3_staticSet )
		{
			jointSetId = bodyB->setIndex;
		}
		else
		{
			jointSetId = bodyA->setIndex;
		}

		b3SolverSet* jointSet = b3Array_Get( world->solverSets, jointSetId );
		b3TransferJoint( world, jointSet, disabledSet, joint );

		// Now that the joint is in the correct set, I can link the joint in the island.
		if ( jointSetId != b3_staticSet )
		{
			b3LinkJoint( world, joint );
		}
	}

	b3ValidateSolverSets( world );
}

void b3Body_SetMotionLocks( b3BodyId bodyId, b3MotionLocks locks )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetMotionLocks, bodyId, locks );

	uint32_t newLocks = 0;
	newLocks |= locks.linearX ? b3_lockLinearX : 0;
	newLocks |= locks.linearY ? b3_lockLinearY : 0;
	newLocks |= locks.linearZ ? b3_lockLinearZ : 0;
	newLocks |= locks.angularX ? b3_lockAngularX : 0;
	newLocks |= locks.angularY ? b3_lockAngularY : 0;
	newLocks |= locks.angularZ ? b3_lockAngularZ : 0;

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( ( body->flags & b3_allLocks ) == newLocks )
	{
		return;
	}

	bool fixedRotation1 = ( body->flags & b3_fixedRotation ) == b3_fixedRotation;
	bool fixedRotation2 = ( newLocks & b3_fixedRotation ) == b3_fixedRotation;

	body->flags &= ~b3_allLocks;
	body->flags |= newLocks;

	b3SyncBodyFlags( world, body );

	b3BodyState* state = b3GetBodyState( world, body );

	if ( state != NULL )
	{
		if ( locks.linearX )
		{
			state->linearVelocity.x = 0.0f;
		}

		if ( locks.linearY )
		{
			state->linearVelocity.y = 0.0f;
		}

		if ( locks.linearZ )
		{
			state->linearVelocity.z = 0.0f;
		}

		if ( locks.angularX )
		{
			state->angularVelocity.x = 0.0f;
		}

		if ( locks.angularY )
		{
			state->angularVelocity.y = 0.0f;
		}

		if ( locks.angularZ )
		{
			state->angularVelocity.z = 0.0f;
		}
	}

	if ( fixedRotation1 != fixedRotation2 )
	{
		b3UpdateBodyMassData( world, body );
	}
}

b3MotionLocks b3Body_GetMotionLocks( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );

	b3MotionLocks locks;
	locks.linearX = ( body->flags & b3_lockLinearX );
	locks.linearY = ( body->flags & b3_lockLinearY );
	locks.linearZ = ( body->flags & b3_lockLinearZ );
	locks.angularX = ( body->flags & b3_lockAngularX );
	locks.angularY = ( body->flags & b3_lockAngularY );
	locks.angularZ = ( body->flags & b3_lockAngularZ );
	return locks;
}

void b3Body_SetBullet( b3BodyId bodyId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodySetBullet, bodyId, flag );

	uint32_t newFlag = flag ? b3_isBullet : 0;

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( ( body->flags & b3_isBullet ) == newFlag )
	{
		return;
	}

	body->flags &= ~b3_isBullet;
	body->flags |= newFlag;

	b3SyncBodyFlags( world, body );
}

bool b3Body_IsBullet( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return ( body->flags & b3_isBullet ) != 0;
}

void b3Body_EnableContactRecycling( b3BodyId bodyId, bool flag )
{
	b3World* world = b3GetUnlockedWorld( bodyId.world0 );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, BodyEnableContactRecycling, bodyId, flag );

	uint32_t newFlag = flag ? b3_bodyEnableContactRecycling : 0;

	b3Body* body = b3GetBodyFullId( world, bodyId );
	if ( ( body->flags & b3_bodyEnableContactRecycling ) == newFlag )
	{
		return;
	}

	body->flags &= ~b3_bodyEnableContactRecycling;
	body->flags |= newFlag;

	b3SyncBodyFlags( world, body );
}

bool b3Body_IsContactRecyclingEnabled( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return ( body->flags & b3_bodyEnableContactRecycling ) != 0;
}

void b3Body_EnableHitEvents( b3BodyId bodyId, bool flag )
{
	b3World* world = b3GetWorld( bodyId.world0 );

	B3_REC( world, BodyEnableHitEvents, bodyId, flag );

	b3Body* body = b3GetBodyFullId( world, bodyId );
	int shapeId = body->headShapeId;
	while ( shapeId != B3_NULL_INDEX )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		shape->flags = flag ? shape->flags | b3_enableHitEvents : shape->flags & ~b3_enableHitEvents;
		shapeId = shape->nextShapeId;
	}
}

b3WorldId b3Body_GetWorld( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	return (b3WorldId){ (uint16_t)( bodyId.world0 + 1 ), world->generation };
}

int b3Body_GetShapeCount( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->shapeCount;
}

int b3Body_GetShapes( b3BodyId bodyId, b3ShapeId* shapeArray, int capacity )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	int shapeId = body->headShapeId;
	int shapeCount = 0;
	while ( shapeId != B3_NULL_INDEX && shapeCount < capacity )
	{
		b3Shape* shape = b3Array_Get( world->shapes, shapeId );
		b3ShapeId id = { shape->id + 1, bodyId.world0, shape->generation };
		shapeArray[shapeCount] = id;
		shapeCount += 1;

		shapeId = shape->nextShapeId;
	}

	return shapeCount;
}

int b3Body_GetJointCount( b3BodyId bodyId )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	return body->jointCount;
}

int b3Body_GetJoints( b3BodyId bodyId, b3JointId* jointArray, int capacity )
{
	b3World* world = b3GetWorld( bodyId.world0 );
	b3Body* body = b3GetBodyFullId( world, bodyId );
	int jointKey = body->headJointKey;

	int jointCount = 0;
	while ( jointKey != B3_NULL_INDEX && jointCount < capacity )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );

		b3JointId id = { jointId + 1, bodyId.world0, joint->generation };
		jointArray[jointCount] = id;
		jointCount += 1;

		jointKey = joint->edges[edgeIndex].nextKey;
	}

	return jointCount;
}

bool b3ShouldBodiesCollide( b3World* world, b3Body* bodyA, b3Body* bodyB )
{
	if ( bodyA->type != b3_dynamicBody && bodyB->type != b3_dynamicBody )
	{
		return false;
	}

	int jointKey;
	int otherBodyId;
	if ( bodyA->jointCount < bodyB->jointCount )
	{
		jointKey = bodyA->headJointKey;
		otherBodyId = bodyB->id;
	}
	else
	{
		jointKey = bodyB->headJointKey;
		otherBodyId = bodyA->id;
	}

	while ( jointKey != B3_NULL_INDEX )
	{
		int jointId = jointKey >> 1;
		int edgeIndex = jointKey & 1;
		int otherEdgeIndex = edgeIndex ^ 1;

		b3Joint* joint = b3Array_Get( world->joints, jointId );
		if ( joint->collideConnected == false && joint->edges[otherEdgeIndex].bodyId == otherBodyId )
		{
			return false;
		}

		jointKey = joint->edges[edgeIndex].nextKey;
	}

	return true;
}
