// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#if defined( _MSC_VER ) && !defined( _CRT_SECURE_NO_WARNINGS )
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "recording_replay.h"

#include "body.h"
#include "compound.h"
#include "physics_world.h"
#include "world_snapshot.h"

#include "box3d/box3d.h"

#include <inttypes.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>

// Read primitives

static void b3RecRdrCheck( b3RecReader* rdr, int size )
{
	if ( size < 0 || (int64_t)rdr->cursor + (int64_t)size > (int64_t)rdr->size )
	{
		rdr->ok = false;
	}
}

static void b3RecRdrBlob( b3RecReader* rdr, void* out, int size )
{
	b3RecRdrCheck( rdr, size );
	if ( !rdr->ok )
	{
		memset( out, 0, (size_t)size );
		return;
	}
	memcpy( out, rdr->data + rdr->cursor, (size_t)size );
	rdr->cursor += size;
}

uint8_t b3RecR_U8( b3RecReader* rdr )
{
	b3RecRdrCheck( rdr, 1 );
	if ( !rdr->ok )
	{
		return 0;
	}
	return rdr->data[rdr->cursor++];
}

uint16_t b3RecR_U16( b3RecReader* rdr )
{
	b3RecRdrCheck( rdr, 2 );
	if ( !rdr->ok )
	{
		return 0;
	}
	uint16_t v = (uint16_t)rdr->data[rdr->cursor] | ( (uint16_t)rdr->data[rdr->cursor + 1] << 8 );
	rdr->cursor += 2;
	return v;
}

uint32_t b3RecR_U24( b3RecReader* rdr )
{
	b3RecRdrCheck( rdr, 3 );
	if ( !rdr->ok )
	{
		return 0;
	}
	uint32_t v = (uint32_t)rdr->data[rdr->cursor] | ( (uint32_t)rdr->data[rdr->cursor + 1] << 8 ) |
				 ( (uint32_t)rdr->data[rdr->cursor + 2] << 16 );
	rdr->cursor += 3;
	return v;
}

uint32_t b3RecR_U32( b3RecReader* rdr )
{
	b3RecRdrCheck( rdr, 4 );
	if ( !rdr->ok )
	{
		return 0;
	}
	uint32_t v = (uint32_t)rdr->data[rdr->cursor] | ( (uint32_t)rdr->data[rdr->cursor + 1] << 8 ) |
				 ( (uint32_t)rdr->data[rdr->cursor + 2] << 16 ) | ( (uint32_t)rdr->data[rdr->cursor + 3] << 24 );
	rdr->cursor += 4;
	return v;
}

uint64_t b3RecR_U64( b3RecReader* rdr )
{
	b3RecRdrCheck( rdr, 8 );
	if ( !rdr->ok )
	{
		return 0;
	}
	uint64_t v = (uint64_t)rdr->data[rdr->cursor] | ( (uint64_t)rdr->data[rdr->cursor + 1] << 8 ) |
				 ( (uint64_t)rdr->data[rdr->cursor + 2] << 16 ) | ( (uint64_t)rdr->data[rdr->cursor + 3] << 24 ) |
				 ( (uint64_t)rdr->data[rdr->cursor + 4] << 32 ) | ( (uint64_t)rdr->data[rdr->cursor + 5] << 40 ) |
				 ( (uint64_t)rdr->data[rdr->cursor + 6] << 48 ) | ( (uint64_t)rdr->data[rdr->cursor + 7] << 56 );
	rdr->cursor += 8;
	return v;
}

int32_t b3RecR_I32( b3RecReader* rdr )
{
	return (int32_t)b3RecR_U32( rdr );
}

float b3RecR_F32( b3RecReader* rdr )
{
	uint32_t bits = b3RecR_U32( rdr );
	float v;
	memcpy( &v, &bits, 4 );
	return v;
}

double b3RecR_F64( b3RecReader* rdr )
{
	uint64_t bits = b3RecR_U64( rdr );
	double v;
	memcpy( &v, &bits, 8 );
	return v;
}

bool b3RecR_BOOL( b3RecReader* rdr )
{
	return b3RecR_U8( rdr ) != 0u;
}

b3Vec3 b3RecR_VEC3( b3RecReader* rdr )
{
	b3Vec3 v;
	v.x = b3RecR_F32( rdr );
	v.y = b3RecR_F32( rdr );
	v.z = b3RecR_F32( rdr );
	return v;
}

b3Quat b3RecR_QUAT( b3RecReader* rdr )
{
	b3Quat q;
	q.v.x = b3RecR_F32( rdr );
	q.v.y = b3RecR_F32( rdr );
	q.v.z = b3RecR_F32( rdr );
	q.s = b3RecR_F32( rdr );
	return q;
}

b3Transform b3RecR_TRANSFORM( b3RecReader* rdr )
{
	b3Transform t;
	t.p = b3RecR_VEC3( rdr );
	t.q = b3RecR_QUAT( rdr );
	return t;
}

b3Pos b3RecR_POSITION( b3RecReader* rdr )
{
	b3Pos p;
#if defined( BOX3D_DOUBLE_PRECISION )
	p.x = b3RecR_F64( rdr );
	p.y = b3RecR_F64( rdr );
	p.z = b3RecR_F64( rdr );
#else
	p.x = b3RecR_F32( rdr );
	p.y = b3RecR_F32( rdr );
	p.z = b3RecR_F32( rdr );
#endif
	return p;
}

b3WorldTransform b3RecR_WORLDXF( b3RecReader* rdr )
{
	b3WorldTransform t;
	t.p = b3RecR_POSITION( rdr );
	t.q = b3RecR_QUAT( rdr );
	return t;
}

b3Matrix3 b3RecR_MATRIX3( b3RecReader* rdr )
{
	b3Matrix3 m;
	m.cx = b3RecR_VEC3( rdr );
	m.cy = b3RecR_VEC3( rdr );
	m.cz = b3RecR_VEC3( rdr );
	return m;
}

b3AABB b3RecR_AABB( b3RecReader* rdr )
{
	b3AABB v;
	v.lowerBound = b3RecR_VEC3( rdr );
	v.upperBound = b3RecR_VEC3( rdr );
	return v;
}

b3QueryFilter b3RecR_QUERYFILTER( b3RecReader* rdr )
{
	// id and name are not on the wire here, they ride the separate QueryTag op. Start from the default
	// so they keep the untagged sentinel instead of garbage.
	b3QueryFilter f = b3DefaultQueryFilter();
	f.categoryBits = b3RecR_U64( rdr );
	f.maskBits = b3RecR_U64( rdr );
	return f;
}

// Reserve reader scratch for a count taken from an untrusted file. Every recorded element
// consumes at least one byte, so a valid count can never exceed the bytes left in the file.
// Reject anything larger (or negative, or that would overflow the byte size) by failing the read
// rather than allocating wildly. A grow keeps the old contents so callers can accumulate across
// reserves, as the collide-mover dispatcher does one shape group at a time.
static bool b3RecReserveScratch( b3RecReader* rdr, void** data, int* cap, int need, int elemSize )
{
	int remaining = rdr->size - rdr->cursor;
	if ( need < 0 || remaining < 0 || need > remaining || need > INT_MAX / elemSize )
	{
		rdr->ok = false;
		return false;
	}
	if ( need <= *cap )
	{
		return true;
	}
	int newCap = need <= INT_MAX / elemSize - 8 ? need + 8 : need;
	void* grown = b3Alloc( (size_t)newCap * (size_t)elemSize );
	if ( *data != NULL )
	{
		memcpy( grown, *data, (size_t)*cap * (size_t)elemSize );
		b3Free( *data, (size_t)*cap * (size_t)elemSize );
	}
	*data = grown;
	*cap = newCap;
	return true;
}

// Variable length, mirrors b3RecW_SHAPEPROXY: count, count points, radius. The decoded proxy borrows
// the reader's scratch for its point cloud, valid until the next proxy read.
b3ShapeProxy b3RecR_SHAPEPROXY( b3RecReader* rdr )
{
	b3ShapeProxy p = { 0 };
	int count = b3RecR_I32( rdr );
	if ( count < 0 )
		count = 0;
	if ( count > B3_MAX_SHAPE_CAST_POINTS )
		count = B3_MAX_SHAPE_CAST_POINTS;
	if ( count > 0 &&
		 b3RecReserveScratch( rdr, (void**)&rdr->proxyScratch, &rdr->proxyScratchCap, count, (int)sizeof( b3Vec3 ) ) )
	{
		for ( int i = 0; i < count; ++i )
		{
			rdr->proxyScratch[i] = b3RecR_VEC3( rdr );
		}
		p.points = rdr->proxyScratch;
		p.count = count;
	}
	p.radius = b3RecR_F32( rdr );
	return p;
}

b3TreeStats b3RecR_TREESTATS( b3RecReader* rdr )
{
	b3TreeStats v;
	v.nodeVisits = b3RecR_I32( rdr );
	v.leafVisits = b3RecR_I32( rdr );
	return v;
}

b3RayResult b3RecR_RAYRESULT( b3RecReader* rdr )
{
	b3RayResult v = { 0 };
	// shapeId keeps the recorded world0; b3RecMakeShapeId is applied at compare time
	v.shapeId = b3RecR_SHAPEID( rdr );
	v.point = b3RecR_POSITION( rdr );
	v.normal = b3RecR_VEC3( rdr );
	v.userMaterialId = b3RecR_U64( rdr );
	v.fraction = b3RecR_F32( rdr );
	v.triangleIndex = b3RecR_I32( rdr );
	v.childIndex = b3RecR_I32( rdr );
	v.hit = b3RecR_BOOL( rdr );
	return v;
}

b3PlaneResult b3RecR_PLANERESULT( b3RecReader* rdr )
{
	b3PlaneResult v;
	v.plane.normal = b3RecR_VEC3( rdr );
	v.plane.offset = b3RecR_F32( rdr );
	v.point = b3RecR_VEC3( rdr );
	return v;
}

b3WorldId b3RecR_WORLDID( b3RecReader* rdr )
{
	return b3LoadWorldId( b3RecR_U32( rdr ) );
}

b3BodyId b3RecR_BODYID( b3RecReader* rdr )
{
	return b3LoadBodyId( b3RecR_U64( rdr ) );
}

b3ShapeId b3RecR_SHAPEID( b3RecReader* rdr )
{
	return b3LoadShapeId( b3RecR_U64( rdr ) );
}

b3JointId b3RecR_JOINTID( b3RecReader* rdr )
{
	return b3LoadJointId( b3RecR_U64( rdr ) );
}

b3Sphere b3RecR_SPHERE( b3RecReader* rdr )
{
	b3Sphere s;
	b3RecRdrBlob( rdr, &s, (int)sizeof( s ) );
	return s;
}

b3Capsule b3RecR_CAPSULE( b3RecReader* rdr )
{
	b3Capsule c;
	b3RecRdrBlob( rdr, &c, (int)sizeof( c ) );
	return c;
}

uint32_t b3RecR_GEOMID( b3RecReader* rdr )
{
	return b3RecR_U32( rdr );
}

b3Filter b3RecR_FILTER( b3RecReader* rdr )
{
	b3Filter f;
	f.categoryBits = b3RecR_U64( rdr );
	f.maskBits = b3RecR_U64( rdr );
	f.groupIndex = b3RecR_I32( rdr );
	return f;
}

b3SurfaceMaterial b3RecR_MATERIAL( b3RecReader* rdr )
{
	b3SurfaceMaterial m = b3DefaultSurfaceMaterial();
	m.friction = b3RecR_F32( rdr );
	m.restitution = b3RecR_F32( rdr );
	m.rollingResistance = b3RecR_F32( rdr );
	m.tangentVelocity = b3RecR_VEC3( rdr );
	m.userMaterialId = b3RecR_U64( rdr );
	m.customColor = b3RecR_U32( rdr );
	return m;
}

b3MassData b3RecR_MASSDATA( b3RecReader* rdr )
{
	b3MassData md;
	md.mass = b3RecR_F32( rdr );
	md.center = b3RecR_VEC3( rdr );
	md.inertia = b3RecR_MATRIX3( rdr );
	return md;
}

b3MotionLocks b3RecR_LOCKS( b3RecReader* rdr )
{
	b3MotionLocks locks;
	locks.linearX = b3RecR_BOOL( rdr );
	locks.linearY = b3RecR_BOOL( rdr );
	locks.linearZ = b3RecR_BOOL( rdr );
	locks.angularX = b3RecR_BOOL( rdr );
	locks.angularY = b3RecR_BOOL( rdr );
	locks.angularZ = b3RecR_BOOL( rdr );
	return locks;
}

// Rotating set of static string buffers, valid until the next 4 STR reads.
const char* b3RecR_STR( b3RecReader* rdr )
{
	char* buf = rdr->stringBuffers[rdr->nextString];
	rdr->nextString = ( rdr->nextString + 1 ) & 3;

	uint16_t len = b3RecR_U16( rdr );
	if ( len == 0xFFFFu )
	{
		return NULL;
	}

	int n = (int)len;
	if ( n > B3_MAX_NAME_LENGTH )
	{
		n = B3_MAX_NAME_LENGTH;
	}
	b3RecRdrCheck( rdr, (int)len );
	if ( rdr->ok && n > 0 )
	{
		memcpy( buf, rdr->data + rdr->cursor, (size_t)n );
	}
	rdr->cursor += (int)len;
	buf[n] = '\0';
	return buf;
}

// Def readers: start from b3Default*Def() then overlay each serialized field
// in the exact order the writer produced them.

b3ExplosionDef b3RecR_EXPLOSIONDEF( b3RecReader* rdr )
{
	b3ExplosionDef def = b3DefaultExplosionDef();
	def.maskBits = b3RecR_U64( rdr );
	def.position = b3RecR_POSITION( rdr );
	def.radius = b3RecR_F32( rdr );
	def.falloff = b3RecR_F32( rdr );
	def.impulsePerArea = b3RecR_F32( rdr );
	return def;
}

b3BodyDef b3RecR_BODYDEF( b3RecReader* rdr )
{
	b3BodyDef def = b3DefaultBodyDef();
	def.type = (b3BodyType)b3RecR_I32( rdr );
	def.position = b3RecR_POSITION( rdr );
	def.rotation = b3RecR_QUAT( rdr );
	def.linearVelocity = b3RecR_VEC3( rdr );
	def.angularVelocity = b3RecR_VEC3( rdr );
	def.linearDamping = b3RecR_F32( rdr );
	def.angularDamping = b3RecR_F32( rdr );
	def.gravityScale = b3RecR_F32( rdr );
	def.sleepThreshold = b3RecR_F32( rdr );
	def.name = b3RecR_STR( rdr );
	(void)b3RecR_U64( rdr ); // userData placeholder
	def.motionLocks = b3RecR_LOCKS( rdr );
	def.enableSleep = b3RecR_BOOL( rdr );
	def.isAwake = b3RecR_BOOL( rdr );
	def.isBullet = b3RecR_BOOL( rdr );
	def.isEnabled = b3RecR_BOOL( rdr );
	def.allowFastRotation = b3RecR_BOOL( rdr );
	def.enableContactRecycling = b3RecR_BOOL( rdr );
	def.userData = NULL;
	return def;
}

b3ShapeDef b3RecR_SHAPEDEF( b3RecReader* rdr )
{
	b3ShapeDef def = b3DefaultShapeDef();

	def.name = b3RecR_STR( rdr );
	(void)b3RecR_U64( rdr ); // userData placeholder

	int matCount = b3RecR_I32( rdr );
	if ( matCount < 0 )
	{
		matCount = 0;
	}
	if ( matCount > 0 &&
		 b3RecReserveScratch( rdr, (void**)&rdr->matScratch, &rdr->matScratchCap, matCount, (int)sizeof( b3SurfaceMaterial ) ) )
	{
		for ( int i = 0; i < matCount; ++i )
		{
			rdr->matScratch[i] = b3RecR_MATERIAL( rdr );
		}
		def.materials = rdr->matScratch;
		def.materialCount = matCount;
	}
	else
	{
		for ( int i = 0; i < matCount; ++i )
		{
			(void)b3RecR_MATERIAL( rdr );
		}
		def.materials = NULL;
		def.materialCount = 0;
	}

	def.baseMaterial = b3RecR_MATERIAL( rdr );
	def.density = b3RecR_F32( rdr );
	def.explosionScale = b3RecR_F32( rdr );
	def.filter = b3RecR_FILTER( rdr );
	def.enableCustomFiltering = b3RecR_BOOL( rdr );
	def.isSensor = b3RecR_BOOL( rdr );
	def.enableSensorEvents = b3RecR_BOOL( rdr );
	def.enableContactEvents = b3RecR_BOOL( rdr );
	def.enableHitEvents = b3RecR_BOOL( rdr );
	def.enablePreSolveEvents = b3RecR_BOOL( rdr );
	def.invokeContactCreation = b3RecR_BOOL( rdr );
	def.updateBodyMass = b3RecR_BOOL( rdr );
	def.enableSpeculativeContact = b3RecR_BOOL( rdr );
	def.userData = NULL;
	return def;
}

// Shared base for all joint defs. Body ids come in with recorded world0; callers remap them.
static void b3RecR_JointBase( b3RecReader* rdr, b3JointDef* base )
{
	(void)b3RecR_U64( rdr ); // userData
	base->bodyIdA = b3RecR_BODYID( rdr );
	base->bodyIdB = b3RecR_BODYID( rdr );
	base->localFrameA = b3RecR_TRANSFORM( rdr );
	base->localFrameB = b3RecR_TRANSFORM( rdr );
	base->forceThreshold = b3RecR_F32( rdr );
	base->torqueThreshold = b3RecR_F32( rdr );
	base->constraintHertz = b3RecR_F32( rdr );
	base->constraintDampingRatio = b3RecR_F32( rdr );
	base->drawScale = b3RecR_F32( rdr );
	base->collideConnected = b3RecR_BOOL( rdr );
	base->userData = NULL;
}

b3ParallelJointDef b3RecR_PARALLELJOINTDEF( b3RecReader* rdr )
{
	b3ParallelJointDef def = b3DefaultParallelJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.hertz = b3RecR_F32( rdr );
	def.dampingRatio = b3RecR_F32( rdr );
	def.maxTorque = b3RecR_F32( rdr );
	return def;
}

b3DistanceJointDef b3RecR_DISTANCEJOINTDEF( b3RecReader* rdr )
{
	b3DistanceJointDef def = b3DefaultDistanceJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.length = b3RecR_F32( rdr );
	def.enableSpring = b3RecR_BOOL( rdr );
	def.lowerSpringForce = b3RecR_F32( rdr );
	def.upperSpringForce = b3RecR_F32( rdr );
	def.hertz = b3RecR_F32( rdr );
	def.dampingRatio = b3RecR_F32( rdr );
	def.enableLimit = b3RecR_BOOL( rdr );
	def.minLength = b3RecR_F32( rdr );
	def.maxLength = b3RecR_F32( rdr );
	def.enableMotor = b3RecR_BOOL( rdr );
	def.maxMotorForce = b3RecR_F32( rdr );
	def.motorSpeed = b3RecR_F32( rdr );
	return def;
}

b3FilterJointDef b3RecR_FILTERJOINTDEF( b3RecReader* rdr )
{
	b3FilterJointDef def = b3DefaultFilterJointDef();
	b3RecR_JointBase( rdr, &def.base );
	return def;
}

b3MotorJointDef b3RecR_MOTORJOINTDEF( b3RecReader* rdr )
{
	b3MotorJointDef def = b3DefaultMotorJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.linearVelocity = b3RecR_VEC3( rdr );
	def.maxVelocityForce = b3RecR_F32( rdr );
	def.angularVelocity = b3RecR_VEC3( rdr );
	def.maxVelocityTorque = b3RecR_F32( rdr );
	def.linearHertz = b3RecR_F32( rdr );
	def.linearDampingRatio = b3RecR_F32( rdr );
	def.maxSpringForce = b3RecR_F32( rdr );
	def.angularHertz = b3RecR_F32( rdr );
	def.angularDampingRatio = b3RecR_F32( rdr );
	def.maxSpringTorque = b3RecR_F32( rdr );
	return def;
}

b3PrismaticJointDef b3RecR_PRISMATICJOINTDEF( b3RecReader* rdr )
{
	b3PrismaticJointDef def = b3DefaultPrismaticJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.enableSpring = b3RecR_BOOL( rdr );
	def.hertz = b3RecR_F32( rdr );
	def.dampingRatio = b3RecR_F32( rdr );
	def.targetTranslation = b3RecR_F32( rdr );
	def.enableLimit = b3RecR_BOOL( rdr );
	def.lowerTranslation = b3RecR_F32( rdr );
	def.upperTranslation = b3RecR_F32( rdr );
	def.enableMotor = b3RecR_BOOL( rdr );
	def.maxMotorForce = b3RecR_F32( rdr );
	def.motorSpeed = b3RecR_F32( rdr );
	return def;
}

b3RevoluteJointDef b3RecR_REVOLUTEJOINTDEF( b3RecReader* rdr )
{
	b3RevoluteJointDef def = b3DefaultRevoluteJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.targetAngle = b3RecR_F32( rdr );
	def.enableSpring = b3RecR_BOOL( rdr );
	def.hertz = b3RecR_F32( rdr );
	def.dampingRatio = b3RecR_F32( rdr );
	def.enableLimit = b3RecR_BOOL( rdr );
	def.lowerAngle = b3RecR_F32( rdr );
	def.upperAngle = b3RecR_F32( rdr );
	def.enableMotor = b3RecR_BOOL( rdr );
	def.maxMotorTorque = b3RecR_F32( rdr );
	def.motorSpeed = b3RecR_F32( rdr );
	return def;
}

b3SphericalJointDef b3RecR_SPHERICALJOINTDEF( b3RecReader* rdr )
{
	b3SphericalJointDef def = b3DefaultSphericalJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.enableSpring = b3RecR_BOOL( rdr );
	def.hertz = b3RecR_F32( rdr );
	def.dampingRatio = b3RecR_F32( rdr );
	def.targetRotation = b3RecR_QUAT( rdr );
	def.enableConeLimit = b3RecR_BOOL( rdr );
	def.coneAngle = b3RecR_F32( rdr );
	def.enableTwistLimit = b3RecR_BOOL( rdr );
	def.lowerTwistAngle = b3RecR_F32( rdr );
	def.upperTwistAngle = b3RecR_F32( rdr );
	def.enableMotor = b3RecR_BOOL( rdr );
	def.maxMotorTorque = b3RecR_F32( rdr );
	def.motorVelocity = b3RecR_VEC3( rdr );
	return def;
}

b3WeldJointDef b3RecR_WELDJOINTDEF( b3RecReader* rdr )
{
	b3WeldJointDef def = b3DefaultWeldJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.linearHertz = b3RecR_F32( rdr );
	def.angularHertz = b3RecR_F32( rdr );
	def.linearDampingRatio = b3RecR_F32( rdr );
	def.angularDampingRatio = b3RecR_F32( rdr );
	return def;
}

b3WheelJointDef b3RecR_WHEELJOINTDEF( b3RecReader* rdr )
{
	b3WheelJointDef def = b3DefaultWheelJointDef();
	b3RecR_JointBase( rdr, &def.base );
	def.enableSuspensionSpring = b3RecR_BOOL( rdr );
	def.suspensionHertz = b3RecR_F32( rdr );
	def.suspensionDampingRatio = b3RecR_F32( rdr );
	def.enableSuspensionLimit = b3RecR_BOOL( rdr );
	def.lowerSuspensionLimit = b3RecR_F32( rdr );
	def.upperSuspensionLimit = b3RecR_F32( rdr );
	def.enableSpinMotor = b3RecR_BOOL( rdr );
	def.maxSpinTorque = b3RecR_F32( rdr );
	def.spinSpeed = b3RecR_F32( rdr );
	def.enableSteering = b3RecR_BOOL( rdr );
	def.steeringHertz = b3RecR_F32( rdr );
	def.steeringDampingRatio = b3RecR_F32( rdr );
	def.targetSteeringAngle = b3RecR_F32( rdr );
	def.maxSteeringTorque = b3RecR_F32( rdr );
	def.enableSteeringLimit = b3RecR_BOOL( rdr );
	def.lowerSteeringLimit = b3RecR_F32( rdr );
	def.upperSteeringLimit = b3RecR_F32( rdr );
	return def;
}

// Outliner body tracking. Defined after the player struct; forward declared here because the
// create/destroy dispatch sits above that struct.
static void b3RecTrackBodyCreate( b3RecPlayer* player, b3BodyId id );
static void b3RecTrackBodyDestroy( b3RecPlayer* player, b3BodyId id );

// Id retargeting: replace world0 with the replay world's slot index.

static b3BodyId b3RecMakeBodyId( b3RecReader* rdr, b3BodyId recorded )
{
	b3BodyId id;
	id.index1 = recorded.index1;
	id.world0 = (uint16_t)( rdr->replayWorldId.index1 - 1u );
	id.generation = recorded.generation;
	return id;
}

static b3ShapeId b3RecMakeShapeId( b3RecReader* rdr, b3ShapeId recorded )
{
	b3ShapeId id;
	id.index1 = recorded.index1;
	id.world0 = (uint16_t)( rdr->replayWorldId.index1 - 1u );
	id.generation = recorded.generation;
	return id;
}

static b3JointId b3RecMakeJointId( b3RecReader* rdr, b3JointId recorded )
{
	b3JointId id;
	id.index1 = recorded.index1;
	id.world0 = (uint16_t)( rdr->replayWorldId.index1 - 1u );
	id.generation = recorded.generation;
	return id;
}

// A create op appends the returned id after args. index1 and generation must match;
// world0 always differs so we ignore it.
static void b3RecCheckId( b3RecReader* rdr, const char* kind, int gotIndex, unsigned gotGen, int recIndex, unsigned recGen )
{
	if ( gotIndex != recIndex || gotGen != recGen )
	{
		printf( "b3ReplayFile: %s id mismatch (rec index1=%d gen=%u, got index1=%d gen=%u)\n", kind, recIndex, recGen, gotIndex,
				gotGen );
		rdr->ok = false;
	}
}

static void b3RecCheckBodyId( b3RecReader* rdr, b3BodyId got, b3BodyId rec )
{
	b3RecCheckId( rdr, "body", got.index1, got.generation, rec.index1, rec.generation );
}

static void b3RecCheckShapeId( b3RecReader* rdr, b3ShapeId got, b3ShapeId rec )
{
	b3RecCheckId( rdr, "shape", got.index1, got.generation, rec.index1, rec.generation );
}

static void b3RecCheckJointId( b3RecReader* rdr, b3JointId got, b3JointId rec )
{
	b3RecCheckId( rdr, "joint", got.index1, got.generation, rec.index1, rec.generation );
}

// Registry slot reconstruction. Returns the live pointer for the given slot, building it
// on first use. The hull case is handled inline at the call site since it doesn't cache.

static void* b3RecGetLiveMesh( b3RegistrySlot* slot )
{
	// Mesh is a self-contained blob used by reference, with no pointer fixup. Hand back the pristine
	// bytes directly: they already outlive the world and are freed at teardown, so a copy would just
	// double the memory. Compound can't do this, see b3RecGetLiveCompound.
	return slot->bytes;
}

static void* b3RecGetLiveHeightField( b3RegistrySlot* slot )
{
	// Self-contained blob used by reference, like b3RecGetLiveMesh. The bytes already are a
	// valid b3HeightFieldData with no pointer fixup, so hand them back directly.
	return slot->bytes;
}

static void* b3RecGetLiveCompound( b3RegistrySlot* slot )
{
	if ( slot->live != NULL )
	{
		return slot->live;
	}
	// The copy is unavoidable here: b3ConvertBytesToCompound rewrites its input in place, while the
	// pristine bytes must survive for keyframe registry seeding (b3RecSeedKeyframeRegistry). So we
	// keep both the serialized bytes and a separate converted live object.
	slot->live = b3Alloc( (size_t)slot->byteCount );
	memcpy( slot->live, slot->bytes, (size_t)slot->byteCount );
	b3ConvertBytesToCompound( (uint8_t*)slot->live, slot->byteCount );
	return slot->live;
}

// Dispatch functions, one per op

static void b3RecDispatch_DestroyWorld( const b3RecArgs_DestroyWorld* a, b3RecReader* rdr )
{
	(void)a;
	(void)rdr;
	// End-of-session marker. The replay world is torn down in b3ValidateReplay, not here.
}

static void b3RecDispatch_Step( const b3RecArgs_Step* a, b3RecReader* rdr )
{
	(void)a;
	b3World_Step( rdr->replayWorldId, a->dt, a->subStepCount );
}

static void b3RecDispatch_WorldEnableSleeping( const b3RecArgs_WorldEnableSleeping* a, b3RecReader* rdr )
{
	b3World_EnableSleeping( rdr->replayWorldId, a->flag );
}

static void b3RecDispatch_WorldEnableContinuous( const b3RecArgs_WorldEnableContinuous* a, b3RecReader* rdr )
{
	b3World_EnableContinuous( rdr->replayWorldId, a->flag );
}

static void b3RecDispatch_WorldSetRestitutionThreshold( const b3RecArgs_WorldSetRestitutionThreshold* a, b3RecReader* rdr )
{
	b3World_SetRestitutionThreshold( rdr->replayWorldId, a->value );
}

static void b3RecDispatch_WorldSetHitEventThreshold( const b3RecArgs_WorldSetHitEventThreshold* a, b3RecReader* rdr )
{
	b3World_SetHitEventThreshold( rdr->replayWorldId, a->value );
}

static void b3RecDispatch_WorldSetGravity( const b3RecArgs_WorldSetGravity* a, b3RecReader* rdr )
{
	b3World_SetGravity( rdr->replayWorldId, a->gravity );
}

static void b3RecDispatch_WorldExplode( const b3RecArgs_WorldExplode* a, b3RecReader* rdr )
{
	b3World_Explode( rdr->replayWorldId, &a->def );
}

static void b3RecDispatch_WorldSetContactTuning( const b3RecArgs_WorldSetContactTuning* a, b3RecReader* rdr )
{
	b3World_SetContactTuning( rdr->replayWorldId, a->hertz, a->dampingRatio, a->contactSpeed );
}

static void b3RecDispatch_WorldSetContactRecycleDistance( const b3RecArgs_WorldSetContactRecycleDistance* a, b3RecReader* rdr )
{
	b3World_SetContactRecycleDistance( rdr->replayWorldId, a->recycleDistance );
}

static void b3RecDispatch_WorldSetMaximumLinearSpeed( const b3RecArgs_WorldSetMaximumLinearSpeed* a, b3RecReader* rdr )
{
	b3World_SetMaximumLinearSpeed( rdr->replayWorldId, a->maximumLinearSpeed );
}

static void b3RecDispatch_WorldEnableWarmStarting( const b3RecArgs_WorldEnableWarmStarting* a, b3RecReader* rdr )
{
	b3World_EnableWarmStarting( rdr->replayWorldId, a->flag );
}

static void b3RecDispatch_WorldRebuildStaticTree( const b3RecArgs_WorldRebuildStaticTree* a, b3RecReader* rdr )
{
	(void)a;
	b3World_RebuildStaticTree( rdr->replayWorldId );
}

static void b3RecDispatch_WorldEnableSpeculative( const b3RecArgs_WorldEnableSpeculative* a, b3RecReader* rdr )
{
	b3World_EnableSpeculative( rdr->replayWorldId, a->flag );
}

static void b3RecDispatch_CreateBody( const b3RecArgs_CreateBody* a, b3RecReader* rdr )
{
	b3BodyId recId = b3RecR_BODYID( rdr );
	b3BodyId gotId = b3CreateBody( rdr->replayWorldId, &a->def );
	b3RecCheckBodyId( rdr, gotId, recId );
	if ( rdr->owner != NULL )
	{
		b3RecTrackBodyCreate( rdr->owner, gotId );
	}
}

static void b3RecDispatch_DestroyBody( const b3RecArgs_DestroyBody* a, b3RecReader* rdr )
{
	b3BodyId id = b3RecMakeBodyId( rdr, a->body );
	if ( rdr->owner != NULL )
	{
		b3RecTrackBodyDestroy( rdr->owner, id );
	}
	b3DestroyBody( id );
}

static void b3RecDispatch_BodySetTransform( const b3RecArgs_BodySetTransform* a, b3RecReader* rdr )
{
	b3Body_SetTransform( b3RecMakeBodyId( rdr, a->body ), a->position, a->rotation );
}

static void b3RecDispatch_BodySetLinearVelocity( const b3RecArgs_BodySetLinearVelocity* a, b3RecReader* rdr )
{
	b3Body_SetLinearVelocity( b3RecMakeBodyId( rdr, a->body ), a->v );
}

static void b3RecDispatch_BodySetType( const b3RecArgs_BodySetType* a, b3RecReader* rdr )
{
	b3Body_SetType( b3RecMakeBodyId( rdr, a->body ), (b3BodyType)a->type );
}

static void b3RecDispatch_BodySetName( const b3RecArgs_BodySetName* a, b3RecReader* rdr )
{
	b3Body_SetName( b3RecMakeBodyId( rdr, a->body ), a->name );
}

static void b3RecDispatch_BodySetAngularVelocity( const b3RecArgs_BodySetAngularVelocity* a, b3RecReader* rdr )
{
	b3Body_SetAngularVelocity( b3RecMakeBodyId( rdr, a->body ), a->w );
}

static void b3RecDispatch_BodySetTargetTransform( const b3RecArgs_BodySetTargetTransform* a, b3RecReader* rdr )
{
	b3Body_SetTargetTransform( b3RecMakeBodyId( rdr, a->body ), a->target, a->timeStep, a->wake );
}

static void b3RecDispatch_BodyApplyForce( const b3RecArgs_BodyApplyForce* a, b3RecReader* rdr )
{
	b3Body_ApplyForce( b3RecMakeBodyId( rdr, a->body ), a->force, a->point, a->wake );
}

static void b3RecDispatch_BodyApplyForceToCenter( const b3RecArgs_BodyApplyForceToCenter* a, b3RecReader* rdr )
{
	b3Body_ApplyForceToCenter( b3RecMakeBodyId( rdr, a->body ), a->force, a->wake );
}

static void b3RecDispatch_BodyApplyTorque( const b3RecArgs_BodyApplyTorque* a, b3RecReader* rdr )
{
	b3Body_ApplyTorque( b3RecMakeBodyId( rdr, a->body ), a->torque, a->wake );
}

static void b3RecDispatch_BodyApplyLinearImpulse( const b3RecArgs_BodyApplyLinearImpulse* a, b3RecReader* rdr )
{
	b3Body_ApplyLinearImpulse( b3RecMakeBodyId( rdr, a->body ), a->impulse, a->point, a->wake );
}

static void b3RecDispatch_BodyApplyLinearImpulseToCenter( const b3RecArgs_BodyApplyLinearImpulseToCenter* a, b3RecReader* rdr )
{
	b3Body_ApplyLinearImpulseToCenter( b3RecMakeBodyId( rdr, a->body ), a->impulse, a->wake );
}

static void b3RecDispatch_BodyApplyAngularImpulse( const b3RecArgs_BodyApplyAngularImpulse* a, b3RecReader* rdr )
{
	b3Body_ApplyAngularImpulse( b3RecMakeBodyId( rdr, a->body ), a->impulse, a->wake );
}

static void b3RecDispatch_BodySetMassData( const b3RecArgs_BodySetMassData* a, b3RecReader* rdr )
{
	b3Body_SetMassData( b3RecMakeBodyId( rdr, a->body ), a->massData );
}

static void b3RecDispatch_BodyApplyMassFromShapes( const b3RecArgs_BodyApplyMassFromShapes* a, b3RecReader* rdr )
{
	b3Body_ApplyMassFromShapes( b3RecMakeBodyId( rdr, a->body ) );
}

static void b3RecDispatch_BodySetLinearDamping( const b3RecArgs_BodySetLinearDamping* a, b3RecReader* rdr )
{
	b3Body_SetLinearDamping( b3RecMakeBodyId( rdr, a->body ), a->damping );
}

static void b3RecDispatch_BodySetAngularDamping( const b3RecArgs_BodySetAngularDamping* a, b3RecReader* rdr )
{
	b3Body_SetAngularDamping( b3RecMakeBodyId( rdr, a->body ), a->damping );
}

static void b3RecDispatch_BodySetGravityScale( const b3RecArgs_BodySetGravityScale* a, b3RecReader* rdr )
{
	b3Body_SetGravityScale( b3RecMakeBodyId( rdr, a->body ), a->scale );
}

static void b3RecDispatch_BodySetAwake( const b3RecArgs_BodySetAwake* a, b3RecReader* rdr )
{
	b3Body_SetAwake( b3RecMakeBodyId( rdr, a->body ), a->awake );
}

static void b3RecDispatch_BodyEnableSleep( const b3RecArgs_BodyEnableSleep* a, b3RecReader* rdr )
{
	b3Body_EnableSleep( b3RecMakeBodyId( rdr, a->body ), a->flag );
}

static void b3RecDispatch_BodySetSleepThreshold( const b3RecArgs_BodySetSleepThreshold* a, b3RecReader* rdr )
{
	b3Body_SetSleepThreshold( b3RecMakeBodyId( rdr, a->body ), a->threshold );
}

static void b3RecDispatch_BodyDisable( const b3RecArgs_BodyDisable* a, b3RecReader* rdr )
{
	b3Body_Disable( b3RecMakeBodyId( rdr, a->body ) );
}

static void b3RecDispatch_BodyEnable( const b3RecArgs_BodyEnable* a, b3RecReader* rdr )
{
	b3Body_Enable( b3RecMakeBodyId( rdr, a->body ) );
}

static void b3RecDispatch_BodySetMotionLocks( const b3RecArgs_BodySetMotionLocks* a, b3RecReader* rdr )
{
	b3Body_SetMotionLocks( b3RecMakeBodyId( rdr, a->body ), a->locks );
}

static void b3RecDispatch_BodySetBullet( const b3RecArgs_BodySetBullet* a, b3RecReader* rdr )
{
	b3Body_SetBullet( b3RecMakeBodyId( rdr, a->body ), a->flag );
}

static void b3RecDispatch_BodyEnableContactRecycling( const b3RecArgs_BodyEnableContactRecycling* a, b3RecReader* rdr )
{
	b3Body_EnableContactRecycling( b3RecMakeBodyId( rdr, a->body ), a->flag );
}

static void b3RecDispatch_BodyEnableHitEvents( const b3RecArgs_BodyEnableHitEvents* a, b3RecReader* rdr )
{
	b3Body_EnableHitEvents( b3RecMakeBodyId( rdr, a->body ), a->flag );
}

static void b3RecDispatch_CreateSphereShape( const b3RecArgs_CreateSphereShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	b3ShapeId gotId = b3CreateSphereShape( bodyId, &a->def, &a->sphere );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_CreateCapsuleShape( const b3RecArgs_CreateCapsuleShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	b3ShapeId gotId = b3CreateCapsuleShape( bodyId, &a->def, &a->capsule );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_CreateHullShape( const b3RecArgs_CreateHullShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	if ( !rdr->ok )
	{
		return;
	}
	uint32_t id = a->geometryId;
	if ( id >= (uint32_t)rdr->slotCount )
	{
		printf( "b3ReplayFile: hull geometryId %u out of range\n", id );
		rdr->ok = false;
		return;
	}
	b3RegistrySlot* slot = rdr->slots + id;
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	// Hull is cloned by b3CreateHullShape into the world DB; no caching needed.
	b3ShapeId gotId = b3CreateHullShape( bodyId, &a->def, (const b3HullData*)slot->bytes );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_CreateMeshShape( const b3RecArgs_CreateMeshShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	if ( !rdr->ok )
	{
		return;
	}
	uint32_t id = a->geometryId;
	if ( id >= (uint32_t)rdr->slotCount )
	{
		printf( "b3ReplayFile: mesh geometryId %u out of range\n", id );
		rdr->ok = false;
		return;
	}
	b3RegistrySlot* slot = rdr->slots + id;
	const b3MeshData* mesh = (const b3MeshData*)b3RecGetLiveMesh( slot );
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	b3ShapeId gotId = b3CreateMeshShape( bodyId, &a->def, mesh, a->scale );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_CreateHeightFieldShape( const b3RecArgs_CreateHeightFieldShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	if ( !rdr->ok )
	{
		return;
	}
	uint32_t id = a->geometryId;
	if ( id >= (uint32_t)rdr->slotCount )
	{
		printf( "b3ReplayFile: heightfield geometryId %u out of range\n", id );
		rdr->ok = false;
		return;
	}
	b3RegistrySlot* slot = rdr->slots + id;
	const b3HeightFieldData* hf = (const b3HeightFieldData*)b3RecGetLiveHeightField( slot );
	if ( hf == NULL )
	{
		printf( "b3ReplayFile: heightfield geometry %u is corrupt\n", id );
		rdr->ok = false;
		return;
	}
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	b3ShapeId gotId = b3CreateHeightFieldShape( bodyId, &a->def, hf );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_CreateCompoundShape( const b3RecArgs_CreateCompoundShape* a, b3RecReader* rdr )
{
	b3ShapeId recId = b3RecR_SHAPEID( rdr );
	if ( !rdr->ok )
	{
		return;
	}
	uint32_t id = a->geometryId;
	if ( id >= (uint32_t)rdr->slotCount )
	{
		printf( "b3ReplayFile: compound geometryId %u out of range\n", id );
		rdr->ok = false;
		return;
	}
	b3RegistrySlot* slot = rdr->slots + id;
	const b3CompoundData* compound = (const b3CompoundData*)b3RecGetLiveCompound( slot );
	b3BodyId bodyId = b3RecMakeBodyId( rdr, a->body );
	// b3CreateCompoundShape takes a non-const def pointer; cast away const for the scratch def
	b3ShapeDef shapeDef = a->def;
	b3ShapeId gotId = b3CreateCompoundShape( bodyId, &shapeDef, compound );
	b3RecCheckShapeId( rdr, gotId, recId );
}

static void b3RecDispatch_DestroyShape( const b3RecArgs_DestroyShape* a, b3RecReader* rdr )
{
	b3DestroyShape( b3RecMakeShapeId( rdr, a->shape ), a->updateBodyMass );
}

static void b3RecDispatch_ShapeSetName( const b3RecArgs_ShapeSetName* a, b3RecReader* rdr )
{
	b3Shape_SetName( b3RecMakeShapeId( rdr, a->shape ), a->name );
}

static void b3RecDispatch_ShapeSetDensity( const b3RecArgs_ShapeSetDensity* a, b3RecReader* rdr )
{
	b3Shape_SetDensity( b3RecMakeShapeId( rdr, a->shape ), a->density, a->updateBodyMass );
}

static void b3RecDispatch_ShapeSetFriction( const b3RecArgs_ShapeSetFriction* a, b3RecReader* rdr )
{
	b3Shape_SetFriction( b3RecMakeShapeId( rdr, a->shape ), a->friction );
}

static void b3RecDispatch_ShapeSetRestitution( const b3RecArgs_ShapeSetRestitution* a, b3RecReader* rdr )
{
	b3Shape_SetRestitution( b3RecMakeShapeId( rdr, a->shape ), a->restitution );
}

static void b3RecDispatch_ShapeSetSurfaceMaterial( const b3RecArgs_ShapeSetSurfaceMaterial* a, b3RecReader* rdr )
{
	b3Shape_SetSurfaceMaterial( b3RecMakeShapeId( rdr, a->shape ), a->material );
}

static void b3RecDispatch_ShapeSetFilter( const b3RecArgs_ShapeSetFilter* a, b3RecReader* rdr )
{
	b3Shape_SetFilter( b3RecMakeShapeId( rdr, a->shape ), a->filter, a->invokeContacts );
}

static void b3RecDispatch_ShapeEnableSensorEvents( const b3RecArgs_ShapeEnableSensorEvents* a, b3RecReader* rdr )
{
	b3Shape_EnableSensorEvents( b3RecMakeShapeId( rdr, a->shape ), a->flag );
}

static void b3RecDispatch_ShapeEnableContactEvents( const b3RecArgs_ShapeEnableContactEvents* a, b3RecReader* rdr )
{
	b3Shape_EnableContactEvents( b3RecMakeShapeId( rdr, a->shape ), a->flag );
}

static void b3RecDispatch_ShapeEnablePreSolveEvents( const b3RecArgs_ShapeEnablePreSolveEvents* a, b3RecReader* rdr )
{
	b3Shape_EnablePreSolveEvents( b3RecMakeShapeId( rdr, a->shape ), a->flag );
}

static void b3RecDispatch_ShapeEnableHitEvents( const b3RecArgs_ShapeEnableHitEvents* a, b3RecReader* rdr )
{
	b3Shape_EnableHitEvents( b3RecMakeShapeId( rdr, a->shape ), a->flag );
}

static void b3RecDispatch_ShapeSetSphere( const b3RecArgs_ShapeSetSphere* a, b3RecReader* rdr )
{
	b3Shape_SetSphere( b3RecMakeShapeId( rdr, a->shape ), &a->sphere );
}

static void b3RecDispatch_ShapeSetCapsule( const b3RecArgs_ShapeSetCapsule* a, b3RecReader* rdr )
{
	b3Shape_SetCapsule( b3RecMakeShapeId( rdr, a->shape ), &a->capsule );
}

static void b3RecDispatch_ShapeApplyWind( const b3RecArgs_ShapeApplyWind* a, b3RecReader* rdr )
{
	b3Shape_ApplyWind( b3RecMakeShapeId( rdr, a->shape ), a->wind, a->drag, a->lift, a->maxSpeed, a->wake );
}

// Joint creates: remap body ids in the def before calling the API.

static void b3RecDispatch_CreateParallelJoint( const b3RecArgs_CreateParallelJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3ParallelJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateParallelJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateDistanceJoint( const b3RecArgs_CreateDistanceJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3DistanceJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateDistanceJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateFilterJoint( const b3RecArgs_CreateFilterJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3FilterJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateFilterJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateMotorJoint( const b3RecArgs_CreateMotorJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3MotorJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateMotorJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreatePrismaticJoint( const b3RecArgs_CreatePrismaticJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3PrismaticJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreatePrismaticJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateRevoluteJoint( const b3RecArgs_CreateRevoluteJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3RevoluteJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateRevoluteJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateSphericalJoint( const b3RecArgs_CreateSphericalJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3SphericalJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateSphericalJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateWeldJoint( const b3RecArgs_CreateWeldJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3WeldJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateWeldJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_CreateWheelJoint( const b3RecArgs_CreateWheelJoint* a, b3RecReader* rdr )
{
	b3JointId recId = b3RecR_JOINTID( rdr );
	b3WheelJointDef def = a->def;
	def.base.bodyIdA = b3RecMakeBodyId( rdr, def.base.bodyIdA );
	def.base.bodyIdB = b3RecMakeBodyId( rdr, def.base.bodyIdB );
	b3RecCheckJointId( rdr, b3CreateWheelJoint( rdr->replayWorldId, &def ), recId );
}

static void b3RecDispatch_DestroyJoint( const b3RecArgs_DestroyJoint* a, b3RecReader* rdr )
{
	b3DestroyJoint( b3RecMakeJointId( rdr, a->joint ), a->wakeAttached );
}

static void b3RecDispatch_JointSetLocalFrameA( const b3RecArgs_JointSetLocalFrameA* a, b3RecReader* rdr )
{
	b3Joint_SetLocalFrameA( b3RecMakeJointId( rdr, a->joint ), a->localFrame );
}

static void b3RecDispatch_JointSetLocalFrameB( const b3RecArgs_JointSetLocalFrameB* a, b3RecReader* rdr )
{
	b3Joint_SetLocalFrameB( b3RecMakeJointId( rdr, a->joint ), a->localFrame );
}

static void b3RecDispatch_JointSetCollideConnected( const b3RecArgs_JointSetCollideConnected* a, b3RecReader* rdr )
{
	b3Joint_SetCollideConnected( b3RecMakeJointId( rdr, a->joint ), a->shouldCollide );
}

static void b3RecDispatch_JointWakeBodies( const b3RecArgs_JointWakeBodies* a, b3RecReader* rdr )
{
	b3Joint_WakeBodies( b3RecMakeJointId( rdr, a->joint ) );
}

static void b3RecDispatch_JointSetConstraintTuning( const b3RecArgs_JointSetConstraintTuning* a, b3RecReader* rdr )
{
	b3Joint_SetConstraintTuning( b3RecMakeJointId( rdr, a->joint ), a->hertz, a->dampingRatio );
}

static void b3RecDispatch_JointSetForceThreshold( const b3RecArgs_JointSetForceThreshold* a, b3RecReader* rdr )
{
	b3Joint_SetForceThreshold( b3RecMakeJointId( rdr, a->joint ), a->threshold );
}

static void b3RecDispatch_JointSetTorqueThreshold( const b3RecArgs_JointSetTorqueThreshold* a, b3RecReader* rdr )
{
	b3Joint_SetTorqueThreshold( b3RecMakeJointId( rdr, a->joint ), a->threshold );
}

static void b3RecDispatch_ParallelJointSetSpringHertz( const b3RecArgs_ParallelJointSetSpringHertz* a, b3RecReader* rdr )
{
	b3ParallelJoint_SetSpringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_ParallelJointSetSpringDampingRatio( const b3RecArgs_ParallelJointSetSpringDampingRatio* a,
															  b3RecReader* rdr )
{
	b3ParallelJoint_SetSpringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_ParallelJointSetMaxTorque( const b3RecArgs_ParallelJointSetMaxTorque* a, b3RecReader* rdr )
{
	b3ParallelJoint_SetMaxTorque( b3RecMakeJointId( rdr, a->joint ), a->maxTorque );
}

static void b3RecDispatch_DistanceJointSetLength( const b3RecArgs_DistanceJointSetLength* a, b3RecReader* rdr )
{
	b3DistanceJoint_SetLength( b3RecMakeJointId( rdr, a->joint ), a->length );
}

static void b3RecDispatch_DistanceJointEnableSpring( const b3RecArgs_DistanceJointEnableSpring* a, b3RecReader* rdr )
{
	b3DistanceJoint_EnableSpring( b3RecMakeJointId( rdr, a->joint ), a->enableSpring );
}

static void b3RecDispatch_DistanceJointSetSpringForceRange( const b3RecArgs_DistanceJointSetSpringForceRange* a,
															b3RecReader* rdr )
{
	b3DistanceJoint_SetSpringForceRange( b3RecMakeJointId( rdr, a->joint ), a->lowerForce, a->upperForce );
}

static void b3RecDispatch_DistanceJointSetSpringHertz( const b3RecArgs_DistanceJointSetSpringHertz* a, b3RecReader* rdr )
{
	b3DistanceJoint_SetSpringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_DistanceJointSetSpringDampingRatio( const b3RecArgs_DistanceJointSetSpringDampingRatio* a,
															  b3RecReader* rdr )
{
	b3DistanceJoint_SetSpringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_DistanceJointEnableLimit( const b3RecArgs_DistanceJointEnableLimit* a, b3RecReader* rdr )
{
	b3DistanceJoint_EnableLimit( b3RecMakeJointId( rdr, a->joint ), a->enableLimit );
}

static void b3RecDispatch_DistanceJointSetLengthRange( const b3RecArgs_DistanceJointSetLengthRange* a, b3RecReader* rdr )
{
	b3DistanceJoint_SetLengthRange( b3RecMakeJointId( rdr, a->joint ), a->minLength, a->maxLength );
}

static void b3RecDispatch_DistanceJointEnableMotor( const b3RecArgs_DistanceJointEnableMotor* a, b3RecReader* rdr )
{
	b3DistanceJoint_EnableMotor( b3RecMakeJointId( rdr, a->joint ), a->enableMotor );
}

static void b3RecDispatch_DistanceJointSetMotorSpeed( const b3RecArgs_DistanceJointSetMotorSpeed* a, b3RecReader* rdr )
{
	b3DistanceJoint_SetMotorSpeed( b3RecMakeJointId( rdr, a->joint ), a->motorSpeed );
}

static void b3RecDispatch_DistanceJointSetMaxMotorForce( const b3RecArgs_DistanceJointSetMaxMotorForce* a, b3RecReader* rdr )
{
	b3DistanceJoint_SetMaxMotorForce( b3RecMakeJointId( rdr, a->joint ), a->force );
}

static void b3RecDispatch_MotorJointSetLinearVelocity( const b3RecArgs_MotorJointSetLinearVelocity* a, b3RecReader* rdr )
{
	b3MotorJoint_SetLinearVelocity( b3RecMakeJointId( rdr, a->joint ), a->velocity );
}

static void b3RecDispatch_MotorJointSetAngularVelocity( const b3RecArgs_MotorJointSetAngularVelocity* a, b3RecReader* rdr )
{
	b3MotorJoint_SetAngularVelocity( b3RecMakeJointId( rdr, a->joint ), a->velocity );
}

static void b3RecDispatch_MotorJointSetMaxVelocityForce( const b3RecArgs_MotorJointSetMaxVelocityForce* a, b3RecReader* rdr )
{
	b3MotorJoint_SetMaxVelocityForce( b3RecMakeJointId( rdr, a->joint ), a->maxForce );
}

static void b3RecDispatch_MotorJointSetMaxVelocityTorque( const b3RecArgs_MotorJointSetMaxVelocityTorque* a, b3RecReader* rdr )
{
	b3MotorJoint_SetMaxVelocityTorque( b3RecMakeJointId( rdr, a->joint ), a->maxTorque );
}

static void b3RecDispatch_MotorJointSetLinearHertz( const b3RecArgs_MotorJointSetLinearHertz* a, b3RecReader* rdr )
{
	b3MotorJoint_SetLinearHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_MotorJointSetLinearDampingRatio( const b3RecArgs_MotorJointSetLinearDampingRatio* a, b3RecReader* rdr )
{
	b3MotorJoint_SetLinearDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->damping );
}

static void b3RecDispatch_MotorJointSetAngularHertz( const b3RecArgs_MotorJointSetAngularHertz* a, b3RecReader* rdr )
{
	b3MotorJoint_SetAngularHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_MotorJointSetAngularDampingRatio( const b3RecArgs_MotorJointSetAngularDampingRatio* a,
															b3RecReader* rdr )
{
	b3MotorJoint_SetAngularDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->damping );
}

static void b3RecDispatch_MotorJointSetMaxSpringForce( const b3RecArgs_MotorJointSetMaxSpringForce* a, b3RecReader* rdr )
{
	b3MotorJoint_SetMaxSpringForce( b3RecMakeJointId( rdr, a->joint ), a->maxForce );
}

static void b3RecDispatch_MotorJointSetMaxSpringTorque( const b3RecArgs_MotorJointSetMaxSpringTorque* a, b3RecReader* rdr )
{
	b3MotorJoint_SetMaxSpringTorque( b3RecMakeJointId( rdr, a->joint ), a->maxTorque );
}

static void b3RecDispatch_PrismaticJointEnableSpring( const b3RecArgs_PrismaticJointEnableSpring* a, b3RecReader* rdr )
{
	b3PrismaticJoint_EnableSpring( b3RecMakeJointId( rdr, a->joint ), a->enableSpring );
}

static void b3RecDispatch_PrismaticJointSetSpringHertz( const b3RecArgs_PrismaticJointSetSpringHertz* a, b3RecReader* rdr )
{
	b3PrismaticJoint_SetSpringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_PrismaticJointSetSpringDampingRatio( const b3RecArgs_PrismaticJointSetSpringDampingRatio* a,
															   b3RecReader* rdr )
{
	b3PrismaticJoint_SetSpringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_PrismaticJointSetTargetTranslation( const b3RecArgs_PrismaticJointSetTargetTranslation* a,
															  b3RecReader* rdr )
{
	b3PrismaticJoint_SetTargetTranslation( b3RecMakeJointId( rdr, a->joint ), a->translation );
}

static void b3RecDispatch_PrismaticJointEnableLimit( const b3RecArgs_PrismaticJointEnableLimit* a, b3RecReader* rdr )
{
	b3PrismaticJoint_EnableLimit( b3RecMakeJointId( rdr, a->joint ), a->enableLimit );
}

static void b3RecDispatch_PrismaticJointSetLimits( const b3RecArgs_PrismaticJointSetLimits* a, b3RecReader* rdr )
{
	b3PrismaticJoint_SetLimits( b3RecMakeJointId( rdr, a->joint ), a->lower, a->upper );
}

static void b3RecDispatch_PrismaticJointEnableMotor( const b3RecArgs_PrismaticJointEnableMotor* a, b3RecReader* rdr )
{
	b3PrismaticJoint_EnableMotor( b3RecMakeJointId( rdr, a->joint ), a->enableMotor );
}

static void b3RecDispatch_PrismaticJointSetMotorSpeed( const b3RecArgs_PrismaticJointSetMotorSpeed* a, b3RecReader* rdr )
{
	b3PrismaticJoint_SetMotorSpeed( b3RecMakeJointId( rdr, a->joint ), a->motorSpeed );
}

static void b3RecDispatch_PrismaticJointSetMaxMotorForce( const b3RecArgs_PrismaticJointSetMaxMotorForce* a, b3RecReader* rdr )
{
	b3PrismaticJoint_SetMaxMotorForce( b3RecMakeJointId( rdr, a->joint ), a->force );
}

static void b3RecDispatch_RevoluteJointEnableSpring( const b3RecArgs_RevoluteJointEnableSpring* a, b3RecReader* rdr )
{
	b3RevoluteJoint_EnableSpring( b3RecMakeJointId( rdr, a->joint ), a->enableSpring );
}

static void b3RecDispatch_RevoluteJointSetSpringHertz( const b3RecArgs_RevoluteJointSetSpringHertz* a, b3RecReader* rdr )
{
	b3RevoluteJoint_SetSpringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_RevoluteJointSetSpringDampingRatio( const b3RecArgs_RevoluteJointSetSpringDampingRatio* a,
															  b3RecReader* rdr )
{
	b3RevoluteJoint_SetSpringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_RevoluteJointSetTargetAngle( const b3RecArgs_RevoluteJointSetTargetAngle* a, b3RecReader* rdr )
{
	b3RevoluteJoint_SetTargetAngle( b3RecMakeJointId( rdr, a->joint ), a->angle );
}

static void b3RecDispatch_RevoluteJointEnableLimit( const b3RecArgs_RevoluteJointEnableLimit* a, b3RecReader* rdr )
{
	b3RevoluteJoint_EnableLimit( b3RecMakeJointId( rdr, a->joint ), a->enableLimit );
}

static void b3RecDispatch_RevoluteJointSetLimits( const b3RecArgs_RevoluteJointSetLimits* a, b3RecReader* rdr )
{
	b3RevoluteJoint_SetLimits( b3RecMakeJointId( rdr, a->joint ), a->lower, a->upper );
}

static void b3RecDispatch_RevoluteJointEnableMotor( const b3RecArgs_RevoluteJointEnableMotor* a, b3RecReader* rdr )
{
	b3RevoluteJoint_EnableMotor( b3RecMakeJointId( rdr, a->joint ), a->enableMotor );
}

static void b3RecDispatch_RevoluteJointSetMotorSpeed( const b3RecArgs_RevoluteJointSetMotorSpeed* a, b3RecReader* rdr )
{
	b3RevoluteJoint_SetMotorSpeed( b3RecMakeJointId( rdr, a->joint ), a->motorSpeed );
}

static void b3RecDispatch_RevoluteJointSetMaxMotorTorque( const b3RecArgs_RevoluteJointSetMaxMotorTorque* a, b3RecReader* rdr )
{
	b3RevoluteJoint_SetMaxMotorTorque( b3RecMakeJointId( rdr, a->joint ), a->torque );
}

static void b3RecDispatch_SphericalJointEnableConeLimit( const b3RecArgs_SphericalJointEnableConeLimit* a, b3RecReader* rdr )
{
	b3SphericalJoint_EnableConeLimit( b3RecMakeJointId( rdr, a->joint ), a->enableLimit );
}

static void b3RecDispatch_SphericalJointSetConeLimit( const b3RecArgs_SphericalJointSetConeLimit* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetConeLimit( b3RecMakeJointId( rdr, a->joint ), a->angleRadians );
}

static void b3RecDispatch_SphericalJointEnableTwistLimit( const b3RecArgs_SphericalJointEnableTwistLimit* a, b3RecReader* rdr )
{
	b3SphericalJoint_EnableTwistLimit( b3RecMakeJointId( rdr, a->joint ), a->enableLimit );
}

static void b3RecDispatch_SphericalJointSetTwistLimits( const b3RecArgs_SphericalJointSetTwistLimits* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetTwistLimits( b3RecMakeJointId( rdr, a->joint ), a->lower, a->upper );
}

static void b3RecDispatch_SphericalJointEnableSpring( const b3RecArgs_SphericalJointEnableSpring* a, b3RecReader* rdr )
{
	b3SphericalJoint_EnableSpring( b3RecMakeJointId( rdr, a->joint ), a->enableSpring );
}

static void b3RecDispatch_SphericalJointSetSpringHertz( const b3RecArgs_SphericalJointSetSpringHertz* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetSpringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_SphericalJointSetSpringDampingRatio( const b3RecArgs_SphericalJointSetSpringDampingRatio* a,
															   b3RecReader* rdr )
{
	b3SphericalJoint_SetSpringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_SphericalJointSetTargetRotation( const b3RecArgs_SphericalJointSetTargetRotation* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetTargetRotation( b3RecMakeJointId( rdr, a->joint ), a->targetRotation );
}

static void b3RecDispatch_SphericalJointEnableMotor( const b3RecArgs_SphericalJointEnableMotor* a, b3RecReader* rdr )
{
	b3SphericalJoint_EnableMotor( b3RecMakeJointId( rdr, a->joint ), a->enableMotor );
}

static void b3RecDispatch_SphericalJointSetMotorVelocity( const b3RecArgs_SphericalJointSetMotorVelocity* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetMotorVelocity( b3RecMakeJointId( rdr, a->joint ), a->motorVelocity );
}

static void b3RecDispatch_SphericalJointSetMaxMotorTorque( const b3RecArgs_SphericalJointSetMaxMotorTorque* a, b3RecReader* rdr )
{
	b3SphericalJoint_SetMaxMotorTorque( b3RecMakeJointId( rdr, a->joint ), a->torque );
}

static void b3RecDispatch_WeldJointSetLinearHertz( const b3RecArgs_WeldJointSetLinearHertz* a, b3RecReader* rdr )
{
	b3WeldJoint_SetLinearHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_WeldJointSetLinearDampingRatio( const b3RecArgs_WeldJointSetLinearDampingRatio* a, b3RecReader* rdr )
{
	b3WeldJoint_SetLinearDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_WeldJointSetAngularHertz( const b3RecArgs_WeldJointSetAngularHertz* a, b3RecReader* rdr )
{
	b3WeldJoint_SetAngularHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_WeldJointSetAngularDampingRatio( const b3RecArgs_WeldJointSetAngularDampingRatio* a, b3RecReader* rdr )
{
	b3WeldJoint_SetAngularDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_WheelJointEnableSuspension( const b3RecArgs_WheelJointEnableSuspension* a, b3RecReader* rdr )
{
	b3WheelJoint_EnableSuspension( b3RecMakeJointId( rdr, a->joint ), a->flag );
}

static void b3RecDispatch_WheelJointSetSuspensionHertz( const b3RecArgs_WheelJointSetSuspensionHertz* a, b3RecReader* rdr )
{
	b3WheelJoint_SetSuspensionHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_WheelJointSetSuspensionDampingRatio( const b3RecArgs_WheelJointSetSuspensionDampingRatio* a,
															   b3RecReader* rdr )
{
	b3WheelJoint_SetSuspensionDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_WheelJointEnableSuspensionLimit( const b3RecArgs_WheelJointEnableSuspensionLimit* a, b3RecReader* rdr )
{
	b3WheelJoint_EnableSuspensionLimit( b3RecMakeJointId( rdr, a->joint ), a->flag );
}

static void b3RecDispatch_WheelJointSetSuspensionLimits( const b3RecArgs_WheelJointSetSuspensionLimits* a, b3RecReader* rdr )
{
	b3WheelJoint_SetSuspensionLimits( b3RecMakeJointId( rdr, a->joint ), a->lower, a->upper );
}

static void b3RecDispatch_WheelJointEnableSpinMotor( const b3RecArgs_WheelJointEnableSpinMotor* a, b3RecReader* rdr )
{
	b3WheelJoint_EnableSpinMotor( b3RecMakeJointId( rdr, a->joint ), a->flag );
}

static void b3RecDispatch_WheelJointSetSpinMotorSpeed( const b3RecArgs_WheelJointSetSpinMotorSpeed* a, b3RecReader* rdr )
{
	b3WheelJoint_SetSpinMotorSpeed( b3RecMakeJointId( rdr, a->joint ), a->speed );
}

static void b3RecDispatch_WheelJointSetMaxSpinTorque( const b3RecArgs_WheelJointSetMaxSpinTorque* a, b3RecReader* rdr )
{
	b3WheelJoint_SetMaxSpinTorque( b3RecMakeJointId( rdr, a->joint ), a->torque );
}

static void b3RecDispatch_WheelJointEnableSteering( const b3RecArgs_WheelJointEnableSteering* a, b3RecReader* rdr )
{
	b3WheelJoint_EnableSteering( b3RecMakeJointId( rdr, a->joint ), a->flag );
}

static void b3RecDispatch_WheelJointSetSteeringHertz( const b3RecArgs_WheelJointSetSteeringHertz* a, b3RecReader* rdr )
{
	b3WheelJoint_SetSteeringHertz( b3RecMakeJointId( rdr, a->joint ), a->hertz );
}

static void b3RecDispatch_WheelJointSetSteeringDampingRatio( const b3RecArgs_WheelJointSetSteeringDampingRatio* a,
															 b3RecReader* rdr )
{
	b3WheelJoint_SetSteeringDampingRatio( b3RecMakeJointId( rdr, a->joint ), a->dampingRatio );
}

static void b3RecDispatch_WheelJointSetMaxSteeringTorque( const b3RecArgs_WheelJointSetMaxSteeringTorque* a, b3RecReader* rdr )
{
	b3WheelJoint_SetMaxSteeringTorque( b3RecMakeJointId( rdr, a->joint ), a->torque );
}

static void b3RecDispatch_WheelJointEnableSteeringLimit( const b3RecArgs_WheelJointEnableSteeringLimit* a, b3RecReader* rdr )
{
	b3WheelJoint_EnableSteeringLimit( b3RecMakeJointId( rdr, a->joint ), a->flag );
}

static void b3RecDispatch_WheelJointSetSteeringLimits( const b3RecArgs_WheelJointSetSteeringLimits* a, b3RecReader* rdr )
{
	b3WheelJoint_SetSteeringLimits( b3RecMakeJointId( rdr, a->joint ), a->lower, a->upper );
}

static void b3RecDispatch_WheelJointSetTargetSteeringAngle( const b3RecArgs_WheelJointSetTargetSteeringAngle* a,
															b3RecReader* rdr )
{
	b3WheelJoint_SetTargetSteeringAngle( b3RecMakeJointId( rdr, a->joint ), a->radians );
}

static void b3RecDispatch_StateHash( const b3RecArgs_StateHash* a, b3RecReader* rdr )
{
	b3World* world = b3GetWorldFromId( rdr->replayWorldId );
	uint64_t computed = b3HashWorldState( world );
	if ( computed != a->hash )
	{
		printf( "b3ReplayFile: StateHash mismatch (recorded=0x%" PRIx64 ", computed=0x%" PRIx64 ")\n", a->hash, computed );
		rdr->diverged = true;
	}
}

static void b3RecDispatch_RecordingBounds( const b3RecArgs_RecordingBounds* a, b3RecReader* rdr )
{
	// Primary resolve is the open-time scan, this keeps the value right if it ever moves earlier
	if ( rdr->owner != NULL )
	{
		rdr->owner->bounds = a->bounds;
	}
}

// Spatial query replay. The recorded inputs come through the manifest; here the variable-length hit
// tail is read back, the query re-issued against the replay world, and each callback hit compared to
// what was recorded. Any mismatch latches rdr->diverged. When a player owns the reader the hits are
// also stashed for the viewer overlay. The stash helpers dereference the player struct, defined later
// in this file, so they are forward declared and implemented in Block B below.

static void b3RecGrow( void** data, int* capacity, int need, int keep, int elemSize );
static b3RecDrawQuery* b3RecStashQueryBegin( b3RecPlayer* player, int kind, const b3RecRecordedHit* hits, int hitCount );

// Grow the reader's hit scratch to at least n entries, preserving contents. n is bounded by the file
// size since every recorded hit consumes at least one byte, so a corrupt count fails the read.
void b3RecEnsureHits( b3RecReader* rdr, int n )
{
	b3RecReserveScratch( rdr, (void**)&rdr->hits, &rdr->hitCap, n, (int)sizeof( b3RecRecordedHit ) );
}

// Bitwise float compare so the determinism check is exact, not within a tolerance.
static bool b3RecF32Differs( float a, float b )
{
	uint32_t ua, ub;
	memcpy( &ua, &a, 4 );
	memcpy( &ub, &b, 4 );
	return ua != ub;
}

static bool b3RecVec3Differs( b3Vec3 a, b3Vec3 b )
{
	return b3RecF32Differs( a.x, b.x ) || b3RecF32Differs( a.y, b.y ) || b3RecF32Differs( a.z, b.z );
}

// Shared context for the replay trampolines: walks recorded hits in order, flagging any divergence
// from the re-issued query.
typedef struct b3RecReplayQueryCtx
{
	b3RecReader* rdr;
	const b3RecRecordedHit* hits;
	int count;
	int cursor;
} b3RecReplayQueryCtx;

static bool b3RecReplayOverlapTrampoline( b3ShapeId id, void* ctx )
{
	b3RecReplayQueryCtx* rc = ctx;
	if ( rc->cursor >= rc->count )
	{
		rc->rdr->diverged = true;
		return false;
	}
	const b3RecRecordedHit* h = &rc->hits[rc->cursor++];
	if ( id.index1 != h->id.index1 || id.generation != h->id.generation )
	{
		rc->rdr->diverged = true;
	}
	return h->userReturnB;
}

// The mover filter has the same bool(shapeId, ctx) shape as an overlap callback, so it replays the
// same way. A distinct typed wrapper keeps the function-pointer types clean.
static bool b3RecReplayMoverFilterTrampoline( b3ShapeId id, void* ctx )
{
	return b3RecReplayOverlapTrampoline( id, ctx );
}

static float b3RecReplayCastTrampoline( b3ShapeId id, b3Pos point, b3Vec3 normal, float fraction, uint64_t userMaterialId,
										int triangleIndex, int childIndex, void* ctx )
{
	b3RecReplayQueryCtx* rc = ctx;
	if ( rc->cursor >= rc->count )
	{
		rc->rdr->diverged = true;
		return 0.0f;
	}
	const b3RecRecordedHit* h = &rc->hits[rc->cursor++];
	// Positions compared through a full-width delta, truncating both sides would pass vacuously far
	// from the origin.
	if ( id.index1 != h->id.index1 || id.generation != h->id.generation ||
		 b3RecVec3Differs( b3SubPos( point, h->point ), b3Vec3_zero ) || b3RecVec3Differs( normal, h->normal ) ||
		 b3RecF32Differs( fraction, h->fraction ) || userMaterialId != h->userMaterialId || triangleIndex != h->triangleIndex ||
		 childIndex != h->childIndex )
	{
		rc->rdr->diverged = true;
	}
	return h->userReturnF;
}

// 3D delivers a whole shape's planes in one call. The recorded group starts at the cursor with its
// plane count and user return replicated on each hit, so compare the batch and advance by the
// recorded count to stay aligned with the stream even when the count itself diverged.
static bool b3RecReplayPlaneTrampoline( b3ShapeId id, const b3PlaneResult* planes, int planeCount, void* ctx )
{
	b3RecReplayQueryCtx* rc = ctx;
	if ( rc->cursor >= rc->count )
	{
		rc->rdr->diverged = true;
		return true;
	}
	const b3RecRecordedHit* head = &rc->hits[rc->cursor];
	int recordedCount = head->planeCount;
	bool ret = head->userReturnB;
	if ( id.index1 != head->id.index1 || id.generation != head->id.generation || recordedCount != planeCount )
	{
		rc->rdr->diverged = true;
	}
	int n = recordedCount < planeCount ? recordedCount : planeCount;
	for ( int i = 0; i < n; ++i )
	{
		const b3RecRecordedHit* h = &rc->hits[rc->cursor + i];
		if ( b3RecVec3Differs( h->plane.plane.normal, planes[i].plane.normal ) ||
			 b3RecF32Differs( h->plane.plane.offset, planes[i].plane.offset ) ||
			 b3RecVec3Differs( h->plane.point, planes[i].point ) )
		{
			rc->rdr->diverged = true;
		}
	}
	rc->cursor += recordedCount;
	return ret;
}

// Copy a decoded proxy's points into a draw record so the overlay does not depend on reader scratch.
static void b3RecStashProxy( b3RecDrawQuery* q, const b3ShapeProxy* proxy )
{
	int count = proxy->count;
	if ( count > B3_MAX_SHAPE_CAST_POINTS )
		count = B3_MAX_SHAPE_CAST_POINTS;
	q->proxyCount = count;
	q->proxyRadius = proxy->radius;
	for ( int i = 0; i < count; ++i )
	{
		q->proxyPoints[i] = proxy->points[i];
	}
}

// Tight world-space bounds of a query's swept geometry, so the viewer can frame any query and not
// just the overlap AABB. Mover and proxy points are origin relative. A cast sweeps the shape from the
// origin to origin plus translation. The overlap AABB is already a world-space box.
static void b3RecComputeQueryBounds( b3RecDrawQuery* q )
{
	if ( q->kind == B3_RECQ_OVERLAP_AABB )
	{
		return;
	}

	// Shape points relative to the origin, plus the fattening radius. A ray has no shape, so it falls
	// through to a single point at the origin.
	b3Vec3 local[B3_MAX_SHAPE_CAST_POINTS];
	int count = 0;
	float radius = 0.0f;
	switch ( q->kind )
	{
		case B3_RECQ_CAST_MOVER:
		case B3_RECQ_COLLIDE_MOVER:
			local[0] = q->mover.center1;
			local[1] = q->mover.center2;
			count = 2;
			radius = q->mover.radius;
			break;

		case B3_RECQ_OVERLAP_SHAPE:
		case B3_RECQ_CAST_SHAPE:
			count = q->proxyCount;
			for ( int i = 0; i < count; ++i )
			{
				local[i] = q->proxyPoints[i];
			}
			radius = q->proxyRadius;
			break;

		default:
			break;
	}
	if ( count == 0 )
	{
		local[0] = b3Vec3_zero;
		count = 1;
	}

	// Sweep each point across the translation. A non-cast query has zero translation, so both ends
	// coincide and the duplicates fold away.
	b3Pos end = b3OffsetPos( q->origin, q->translation );
	b3Vec3 world[2 * B3_MAX_SHAPE_CAST_POINTS];
	int n = 0;
	for ( int i = 0; i < count; ++i )
	{
		world[n++] = b3ToVec3( b3OffsetPos( q->origin, local[i] ) );
		world[n++] = b3ToVec3( b3OffsetPos( end, local[i] ) );
	}
	q->aabb = b3MakeAABB( world, n, radius );
}

static void b3RecDispatch_QueryOverlapAABB( const b3RecArgs_QueryOverlapAABB* a, b3RecReader* rdr )
{
	uint32_t n = b3RecR_U32( rdr );
	b3RecEnsureHits( rdr, (int)n );
	if ( !rdr->ok )
		return;
	for ( uint32_t i = 0; i < n; ++i )
	{
		rdr->hits[i].id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		rdr->hits[i].userReturnB = b3RecR_BOOL( rdr );
	}
	(void)b3RecR_TREESTATS( rdr );
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, (int)n, 0 };
	b3World_OverlapAABB( rdr->replayWorldId, a->aabb, a->filter, b3RecReplayOverlapTrampoline, &rc );
	if ( rc.cursor != (int)n )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_OVERLAP_AABB, rdr->hits, (int)n );
		q->filter = a->filter;
		q->aabb = a->aabb;
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryOverlapShape( const b3RecArgs_QueryOverlapShape* a, b3RecReader* rdr )
{
	uint32_t n = b3RecR_U32( rdr );
	b3RecEnsureHits( rdr, (int)n );
	if ( !rdr->ok )
		return;
	for ( uint32_t i = 0; i < n; ++i )
	{
		rdr->hits[i].id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		rdr->hits[i].userReturnB = b3RecR_BOOL( rdr );
	}
	(void)b3RecR_TREESTATS( rdr );
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, (int)n, 0 };
	b3World_OverlapShape( rdr->replayWorldId, a->origin, &a->proxy, a->filter, b3RecReplayOverlapTrampoline, &rc );
	if ( rc.cursor != (int)n )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_OVERLAP_SHAPE, rdr->hits, (int)n );
		q->filter = a->filter;
		q->origin = a->origin;
		b3RecStashProxy( q, &a->proxy );
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryCastRay( const b3RecArgs_QueryCastRay* a, b3RecReader* rdr )
{
	uint32_t n = b3RecR_U32( rdr );
	b3RecEnsureHits( rdr, (int)n );
	if ( !rdr->ok )
		return;
	for ( uint32_t i = 0; i < n; ++i )
	{
		rdr->hits[i].id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		rdr->hits[i].point = b3RecR_POSITION( rdr );
		rdr->hits[i].normal = b3RecR_VEC3( rdr );
		rdr->hits[i].fraction = b3RecR_F32( rdr );
		rdr->hits[i].userMaterialId = b3RecR_U64( rdr );
		rdr->hits[i].triangleIndex = b3RecR_I32( rdr );
		rdr->hits[i].childIndex = b3RecR_I32( rdr );
		rdr->hits[i].userReturnF = b3RecR_F32( rdr );
	}
	(void)b3RecR_TREESTATS( rdr );
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, (int)n, 0 };
	b3World_CastRay( rdr->replayWorldId, a->origin, a->translation, a->filter, b3RecReplayCastTrampoline, &rc );
	if ( rc.cursor != (int)n )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_CAST_RAY, rdr->hits, (int)n );
		q->filter = a->filter;
		q->origin = a->origin;
		q->translation = a->translation;
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryCastShape( const b3RecArgs_QueryCastShape* a, b3RecReader* rdr )
{
	uint32_t n = b3RecR_U32( rdr );
	b3RecEnsureHits( rdr, (int)n );
	if ( !rdr->ok )
		return;
	for ( uint32_t i = 0; i < n; ++i )
	{
		rdr->hits[i].id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		rdr->hits[i].point = b3RecR_POSITION( rdr );
		rdr->hits[i].normal = b3RecR_VEC3( rdr );
		rdr->hits[i].fraction = b3RecR_F32( rdr );
		rdr->hits[i].userMaterialId = b3RecR_U64( rdr );
		rdr->hits[i].triangleIndex = b3RecR_I32( rdr );
		rdr->hits[i].childIndex = b3RecR_I32( rdr );
		rdr->hits[i].userReturnF = b3RecR_F32( rdr );
	}
	(void)b3RecR_TREESTATS( rdr );
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, (int)n, 0 };
	b3World_CastShape( rdr->replayWorldId, a->origin, &a->proxy, a->translation, a->filter, b3RecReplayCastTrampoline, &rc );
	if ( rc.cursor != (int)n )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_CAST_SHAPE, rdr->hits, (int)n );
		q->filter = a->filter;
		q->origin = a->origin;
		q->translation = a->translation;
		b3RecStashProxy( q, &a->proxy );
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryCastRayClosest( const b3RecArgs_QueryCastRayClosest* a, b3RecReader* rdr )
{
	b3RayResult rec = b3RecR_RAYRESULT( rdr );
	if ( !rdr->ok )
		return;
	b3RayResult got = b3World_CastRayClosest( rdr->replayWorldId, a->origin, a->translation, a->filter );
	b3ShapeId recId = b3RecMakeShapeId( rdr, rec.shapeId );
	if ( got.hit != rec.hit ||
		 ( got.hit &&
		   ( got.shapeId.index1 != recId.index1 || got.shapeId.generation != recId.generation ||
			 b3RecVec3Differs( b3SubPos( got.point, rec.point ), b3Vec3_zero ) || b3RecVec3Differs( got.normal, rec.normal ) ||
			 b3RecF32Differs( got.fraction, rec.fraction ) || got.userMaterialId != rec.userMaterialId ) ) )
	{
		rdr->diverged = true;
	}
	if ( rdr->owner )
	{
		// Stash the closest result as a single pooled hit so the shared draw loop renders its point.
		b3RecRecordedHit h = { 0 };
		h.id = recId;
		h.point = rec.point;
		h.normal = rec.normal;
		h.fraction = rec.fraction;
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_CAST_RAY_CLOSEST, &h, rec.hit ? 1 : 0 );
		q->filter = a->filter;
		q->origin = a->origin;
		q->translation = a->translation;
		q->rayResult = rec;
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryCastMover( const b3RecArgs_QueryCastMover* a, b3RecReader* rdr )
{
	uint32_t n = b3RecR_U32( rdr );
	b3RecEnsureHits( rdr, (int)n );
	if ( !rdr->ok )
		return;
	for ( uint32_t i = 0; i < n; ++i )
	{
		rdr->hits[i].id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		rdr->hits[i].userReturnB = b3RecR_BOOL( rdr );
	}
	float recFraction = b3RecR_F32( rdr );
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, (int)n, 0 };
	float got = b3World_CastMover( rdr->replayWorldId, a->origin, &a->mover, a->translation, a->filter,
								   b3RecReplayMoverFilterTrampoline, &rc );
	if ( rc.cursor != (int)n || b3RecF32Differs( got, recFraction ) )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_CAST_MOVER, NULL, 0 );
		q->filter = a->filter;
		q->origin = a->origin;
		q->mover = a->mover;
		q->translation = a->translation;
		q->castFraction = recFraction;
		b3RecComputeQueryBounds( q );
	}
}

static void b3RecDispatch_QueryCollideMover( const b3RecArgs_QueryCollideMover* a, b3RecReader* rdr )
{
	// Recorded as shapeCount groups, each: shapeId, planeCount, planeCount planes, user return. Flatten
	// into one hit per plane with the group's count and return replicated, so the replay walker can
	// re-group per shape.
	uint32_t shapeCount = b3RecR_U32( rdr );
	int total = 0;
	for ( uint32_t s = 0; s < shapeCount; ++s )
	{
		b3ShapeId id = b3RecMakeShapeId( rdr, b3RecR_SHAPEID( rdr ) );
		int planeCount = b3RecR_I32( rdr );
		if ( planeCount < 0 )
			planeCount = 0;
		b3RecEnsureHits( rdr, total + planeCount );
		if ( !rdr->ok )
			return;
		for ( int i = 0; i < planeCount; ++i )
		{
			rdr->hits[total + i].plane = b3RecR_PLANERESULT( rdr );
		}
		bool ret = b3RecR_BOOL( rdr );
		for ( int i = 0; i < planeCount; ++i )
		{
			rdr->hits[total + i].id = id;
			rdr->hits[total + i].planeCount = planeCount;
			rdr->hits[total + i].userReturnB = ret;
		}
		total += planeCount;
	}
	if ( !rdr->ok )
		return;
	b3RecReplayQueryCtx rc = { rdr, rdr->hits, total, 0 };
	b3World_CollideMover( rdr->replayWorldId, a->origin, &a->mover, a->filter, b3RecReplayPlaneTrampoline, &rc );
	if ( rc.cursor != total )
		rdr->diverged = true;
	if ( rdr->owner )
	{
		b3RecDrawQuery* q = b3RecStashQueryBegin( rdr->owner, B3_RECQ_COLLIDE_MOVER, rdr->hits, total );
		q->filter = a->filter;
		q->origin = a->origin;
		q->mover = a->mover;
		b3RecComputeQueryBounds( q );
	}
}

// Stash the identity key of the query that immediately follows. Consumed by the next stash.
static void b3RecDispatch_QueryTag( const b3RecArgs_QueryTag* a, b3RecReader* rdr )
{
	rdr->pendingQueryKey = a->key;
}

// X-macro dispatch switch: read opcode+u24 payloadSize, dispatch, skip unknown ops.
// Returns the opcode dispatched, or -1 when the stream is exhausted or broken.

static int b3RecDispatchOne( b3RecReader* rdr )
{
	if ( rdr->cursor >= rdr->size || !rdr->ok )
	{
		return -1;
	}
	uint8_t opcode = b3RecR_U8( rdr );
	uint32_t payloadSize = b3RecR_U24( rdr );
	if ( !rdr->ok )
	{
		return -1;
	}

	int payloadStart = rdr->cursor;

	switch ( opcode )
	{
#define ARG( TAG, field ) a.field = b3RecR_##TAG( rdr );
#define B3_REC_OP( op, Name, RET, ... )                                                                                          \
	case op:                                                                                                                     \
	{                                                                                                                            \
		b3RecArgs_##Name a;                                                                                                      \
		memset( &a, 0, sizeof( a ) );                                                                                            \
		__VA_ARGS__                                                                                                              \
		if ( rdr->ok )                                                                                                           \
		{                                                                                                                        \
			b3RecDispatch_##Name( &a, rdr );                                                                                     \
		}                                                                                                                        \
		break;                                                                                                                   \
	}
#include "recording_ops.inl"
#undef B3_REC_OP
#undef ARG
		default:
			printf( "b3ReplayFile: unknown opcode 0x%02X, skipping %u bytes\n", opcode, payloadSize );
			// payloadStart is in bounds, so size - payloadStart is the bytes left to skip over
			if ( payloadSize > (uint32_t)( rdr->size - payloadStart ) )
			{
				rdr->ok = false;
			}
			else
			{
				rdr->cursor = payloadStart + (int)payloadSize;
			}
			break;
	}
	return (int)(unsigned)opcode;
}

// Public entry point

bool b3ValidateReplay( const void* data, int size, int workerCount )
{
	b3RecPlayer* player = b3RecPlayer_Create( data, size, workerCount );
	if ( player == NULL )
	{
		return false;
	}

	while ( b3RecPlayer_StepFrame( player ) )
	{
		if ( player->rdr.diverged )
		{
			break;
		}
	}

	bool ok = player->rdr.ok && player->rdr.diverged == false;
	b3RecPlayer_Destroy( player );
	return ok;
}

// b3RecPlayer implementation

#define B3_REC_KEYFRAME_INTERVAL_DEFAULT 16
#define B3_REC_KEYFRAME_BUDGET_DEFAULT ( (size_t)512 * 1024 * 1024 )

// Overflow-safe growth for the player's accumulating arrays. Counts come from the replay itself,
// not the file, so this only guards the byte-size multiply. Preserves keep elements.
static void b3RecGrow( void** data, int* capacity, int need, int keep, int elemSize )
{
	if ( need <= *capacity )
	{
		return;
	}
	int newCap = *capacity == 0 ? 8 : 2 * *capacity;
	if ( newCap < need )
	{
		newCap = need;
	}
	void* grown = b3Alloc( (size_t)newCap * (size_t)elemSize );
	if ( *data != NULL )
	{
		if ( keep > 0 )
		{
			memcpy( grown, *data, (size_t)keep * (size_t)elemSize );
		}
		b3Free( *data, (size_t)*capacity * (size_t)elemSize );
	}
	*data = grown;
	*capacity = newCap;
}

// Block B: per-frame query store helpers. Forward declared above the query dispatchers, which run
// before the player struct is defined, so the player-dereferencing code lives here.

static void b3RecGrowFrameQueries( b3RecPlayer* player )
{
	b3RecGrow( (void**)&player->frameQueries, &player->frameQueryCap, player->frameQueryCount + 1, player->frameQueryCount,
			   (int)sizeof( b3RecDrawQuery ) );
}

static void b3RecGrowFrameHits( b3RecPlayer* player, int need )
{
	b3RecGrow( (void**)&player->frameHits, &player->frameHitCap, player->frameHitCount + need, player->frameHitCount,
			   (int)sizeof( b3RecRecordedHit ) );
}

// Push a draw record for one query and copy its hits into the per-frame store. Ids in hits[] are
// already remapped to the replay world by the dispatcher.
static b3RecDrawQuery* b3RecStashQueryBegin( b3RecPlayer* player, int kind, const b3RecRecordedHit* hits, int hitCount )
{
	b3RecGrowFrameQueries( player );
	b3RecDrawQuery* q = &player->frameQueries[player->frameQueryCount];
	memset( q, 0, sizeof( *q ) );
	q->kind = kind;
	// Pair the query with the key from its preceding QueryTag op, if any, then clear it so the next
	// untagged query reads 0.
	q->key = player->rdr.pendingQueryKey;
	player->rdr.pendingQueryKey = 0;
	q->hitStart = player->frameHitCount;
	q->hitCount = hitCount;
	b3RecGrowFrameHits( player, hitCount );
	for ( int i = 0; i < hitCount; ++i )
	{
		player->frameHits[player->frameHitCount + i] = hits[i];
	}
	player->frameHitCount += hitCount;
	player->frameQueryCount++;
	return q;
}

// Append a created body to the outliner list. Ordinals are creation order and never reused.
static void b3RecTrackBodyCreate( b3RecPlayer* player, b3BodyId id )
{
	b3RecGrow( (void**)&player->bodyIds, &player->bodyIdCap, player->bodyIdCount + 1, player->bodyIdCount,
			   (int)sizeof( b3BodyId ) );
	player->bodyIds[player->bodyIdCount] = id;
	player->bodyIdCount += 1;
}

// Leave a hole so later ordinals do not shift, keeping a stored selection stable.
static void b3RecTrackBodyDestroy( b3RecPlayer* player, b3BodyId id )
{
	for ( int i = 0; i < player->bodyIdCount; ++i )
	{
		if ( B3_ID_EQUALS( player->bodyIds[i], id ) )
		{
			player->bodyIds[i] = b3_nullBodyId;
			return;
		}
	}
}

// Snapshot bodies are restored as a struct image and never hit the CreateBody hook the tracker keys
// on, so the seed world must be walked once to populate the outliner list. Slot order is stable.
static void b3RecSeedBodyIds( b3RecPlayer* player )
{
	b3World* world = b3GetWorldFromId( player->rdr.replayWorldId );
	player->bodyIdCount = 0;
	int count = world->bodies.count;
	for ( int i = 0; i < count; ++i )
	{
		if ( world->bodies.data[i].id != i )
		{
			continue; // free slot
		}
		b3RecTrackBodyCreate( player, b3MakeBodyId( world, i ) );
	}
}

// Seed the outliner list from the current world and save it as the frame-0 restore copy.
static void b3RecSeedFrame0BodyIds( b3RecPlayer* player )
{
	b3RecSeedBodyIds( player );
	if ( player->frame0BodyIds != NULL )
	{
		b3Free( player->frame0BodyIds, (size_t)player->frame0BodyIdCount * sizeof( b3BodyId ) );
		player->frame0BodyIds = NULL;
	}
	player->frame0BodyIdCount = player->bodyIdCount;
	if ( player->bodyIdCount > 0 )
	{
		player->frame0BodyIds = (b3BodyId*)b3Alloc( (size_t)player->bodyIdCount * sizeof( b3BodyId ) );
		memcpy( player->frame0BodyIds, player->bodyIds, (size_t)player->bodyIdCount * sizeof( b3BodyId ) );
	}
}

// Tag key to tag index, so the viewer resolves a query's caller id and label in O(1) instead of a
// linear scan over the tag table.
#define NAME b3RecTagLookup
#define KEY_TY uint64_t
#define VAL_TY uint32_t
#define HASH_FN vt_hash_integer
#define CMPR_FN vt_cmpr_integer
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

// Read the optional query-tag table trailing the geometry entries: u32 tagCount then per tag
// { u64 key, u64 id, u16 len, name bytes }. A recording written before the tag table leaves rp at
// dataEnd, so nothing loads. Bounds-checked; tagCount reflects only the tags that fully fit, so a
// truncated tail loads what it can and reports the real count.
static void b3RecLoadTags( b3RecReader* rdr, const uint8_t* rp, const uint8_t* dataEnd )
{
	b3RecReader sub = { 0 };
	sub.data = rp;
	sub.size = (int)( dataEnd - rp );
	sub.ok = true;

	uint32_t count = b3RecR_U32( &sub );
	if ( sub.ok == false || count == 0 )
	{
		return;
	}

	// Each tag is at least 18 bytes (8 key + 8 id + 2 length). Reject a count that cannot fit the
	// remaining bytes so a corrupt table cannot request a wild allocation.
	if ( (size_t)count > (size_t)( sub.size - sub.cursor ) / 18 )
	{
		return;
	}

	b3RecTag* tags = (b3RecTag*)b3Alloc( (size_t)count * sizeof( b3RecTag ) );
	memset( tags, 0, (size_t)count * sizeof( b3RecTag ) );

	b3RecTagLookup* map = (b3RecTagLookup*)b3Alloc( sizeof( b3RecTagLookup ) );
	b3RecTagLookup_init( map );

	uint32_t loaded = 0;
	for ( uint32_t i = 0; i < count; ++i )
	{
		uint64_t key = b3RecR_U64( &sub );
		uint64_t id = b3RecR_U64( &sub );
		uint16_t len = b3RecR_U16( &sub );
		if ( sub.ok == false )
		{
			break;
		}
		if ( len == 0xFFFFu )
		{
			len = 0; // a null name is written as 0xFFFF
		}
		if ( (int64_t)sub.cursor + (int64_t)len > (int64_t)sub.size )
		{
			break;
		}
		int n = len > B3_MAX_QUERY_NAME_LENGTH ? B3_MAX_QUERY_NAME_LENGTH : (int)len;
		tags[loaded].key = key;
		tags[loaded].id = id;
		if ( n > 0 )
		{
			memcpy( tags[loaded].queryName, sub.data + sub.cursor, (size_t)n );
		}
		tags[loaded].queryName[n] = '\0';
		sub.cursor += len;
		b3RecTagLookup_insert( map, key, loaded );
		loaded += 1;
	}

	rdr->tags = tags;
	rdr->tagCount = (int)loaded;
	rdr->tagCapacity = (int)count;
	rdr->tagMap = map;
}

// Load the trailing registry block and fill rdr->slots/slotCount, then the optional tag table.
// Returns true on success. On failure sets rdr->ok = false and returns false.
static bool b3RecLoadSlots( b3RecReader* rdr, const void* data, int size, uint64_t registryOffset, uint64_t registryByteCount )
{
	if ( registryOffset == 0 || registryByteCount == 0 )
	{
		rdr->slots = NULL;
		rdr->slotCount = 0;
		return true;
	}

	int regStart = (int)registryOffset;
	int regEnd = regStart + (int)registryByteCount;
	if ( regEnd > size )
	{
		printf( "b3ReplayFile: registry block out of bounds\n" );
		return false;
	}
	if ( regStart + 4 > size )
	{
		printf( "b3ReplayFile: registry too small\n" );
		return false;
	}

	const uint8_t* dataEnd = (const uint8_t*)data + regEnd;
	const uint8_t* rp = (const uint8_t*)data + regStart;
	uint32_t count = (uint32_t)rp[0] | ( (uint32_t)rp[1] << 8 ) | ( (uint32_t)rp[2] << 16 ) | ( (uint32_t)rp[3] << 24 );
	rp += 4;

	if ( count == 0 )
	{
		rdr->slots = NULL;
		rdr->slotCount = 0;
		b3RecLoadTags( rdr, rp, dataEnd );
		return true;
	}

	// Each entry is at least 5 bytes (kind + 4-byte length). A count that cannot fit the remaining
	// registry bytes is a corrupt header, so reject it before allocating.
	if ( rp > dataEnd || (size_t)count > (size_t)( dataEnd - rp ) / 5 )
	{
		printf( "b3ReplayFile: registry count out of range\n" );
		return false;
	}

	b3RegistrySlot* slots = (b3RegistrySlot*)b3Alloc( (size_t)count * sizeof( b3RegistrySlot ) );
	memset( slots, 0, (size_t)count * sizeof( b3RegistrySlot ) );

	for ( uint32_t i = 0; i < count; ++i )
	{
		if ( rp + 5 > dataEnd )
		{
			printf( "b3ReplayFile: registry truncated at entry %u\n", i );
			for ( uint32_t j = 0; j < i; ++j )
			{
				if ( slots[j].bytes != NULL )
				{
					b3Free( slots[j].bytes, (size_t)slots[j].byteCount );
				}
			}
			b3Free( slots, (size_t)count * sizeof( b3RegistrySlot ) );
			return false;
		}
		uint8_t kind = rp[0];
		uint32_t byteCount = (uint32_t)rp[1] | ( (uint32_t)rp[2] << 8 ) | ( (uint32_t)rp[3] << 16 ) | ( (uint32_t)rp[4] << 24 );
		rp += 5;
		if ( rp + byteCount > dataEnd )
		{
			printf( "b3ReplayFile: registry entry %u bytes out of bounds\n", i );
			for ( uint32_t j = 0; j < i; ++j )
			{
				if ( slots[j].bytes != NULL )
				{
					b3Free( slots[j].bytes, (size_t)slots[j].byteCount );
				}
			}
			b3Free( slots, (size_t)count * sizeof( b3RegistrySlot ) );
			return false;
		}
		uint8_t* bytes = (uint8_t*)b3Alloc( byteCount > 0 ? (size_t)byteCount : 1u );
		if ( byteCount > 0 )
		{
			memcpy( bytes, rp, (size_t)byteCount );
		}
		rp += byteCount;
		slots[i].kind = (b3GeometryKind)kind;
		slots[i].byteCount = (int)byteCount;
		slots[i].bytes = bytes;
		slots[i].live = NULL;
	}

	rdr->slots = slots;
	rdr->slotCount = (int)count;
	b3RecLoadTags( rdr, rp, dataEnd );
	return true;
}

// Free slots loaded by b3RecLoadSlots.
static void b3RecFreeSlots( b3RegistrySlot* slots, int slotCount )
{
	if ( slots == NULL )
	{
		return;
	}
	for ( int i = 0; i < slotCount; ++i )
	{
		b3RegistrySlot* slot = slots + i;
		if ( slot->live != NULL )
		{
			switch ( slot->kind )
			{
				// Mesh and height field have no separate live object; they borrow the bytes freed below.
				case b3_geometryCompound:
					b3Free( slot->live, (size_t)slot->byteCount );
					break;
				default:
					break;
			}
		}
		if ( slot->bytes != NULL )
		{
			b3Free( slot->bytes, slot->byteCount > 0 ? (size_t)slot->byteCount : 1u );
		}
	}
	b3Free( slots, (size_t)slotCount * sizeof( b3RegistrySlot ) );
}

// Walk the op stream once without dispatching: count Step ops and grab the first step's tuning.
static void b3RecScanFile( b3RecPlayer* player )
{
	const uint8_t* data = player->data;
	int size = player->registryEnd;
	int cursor = player->headerEnd;
	int frameCount = 0;
	bool gotStep = false;

	while ( cursor + 4 <= size )
	{
		uint8_t opcode = data[cursor];
		uint32_t payloadSize =
			(uint32_t)data[cursor + 1] | ( (uint32_t)data[cursor + 2] << 8 ) | ( (uint32_t)data[cursor + 3] << 16 );
		int payloadStart = cursor + 4;
		if ( payloadStart + (int)payloadSize > size )
		{
			break;
		}
		if ( opcode == b3_recOpStep )
		{
			frameCount += 1;
			if ( !gotStep && payloadSize >= 12 )
			{
				uint32_t dtBits = (uint32_t)data[payloadStart + 4] | ( (uint32_t)data[payloadStart + 5] << 8 ) |
								  ( (uint32_t)data[payloadStart + 6] << 16 ) | ( (uint32_t)data[payloadStart + 7] << 24 );
				memcpy( &player->recordedDt, &dtBits, 4 );
				player->recordedSubStepCount =
					(int)( (uint32_t)data[payloadStart + 8] | ( (uint32_t)data[payloadStart + 9] << 8 ) |
						   ( (uint32_t)data[payloadStart + 10] << 16 ) | ( (uint32_t)data[payloadStart + 11] << 24 ) );
				gotStep = true;
			}
		}
		else if ( opcode == 0xF2 && payloadSize >= (uint32_t)sizeof( b3AABB ) ) // RecordingBounds
		{
			// Payload is a single b3AABB (lower xyz, upper xyz as f32), written at stop so the
			// viewer can frame the whole recorded motion without playing to the end.
			memcpy( &player->bounds, data + payloadStart, sizeof( b3AABB ) );
		}
		cursor = payloadStart + (int)payloadSize;
	}
	player->frameCount = frameCount;
}

// Free one keyframe's heap.
static void b3FreeKeyframe( b3RecKeyframe* kf )
{
	if ( kf->image != NULL )
	{
		b3Free( kf->image, (size_t)kf->imageCapacity );
	}
	if ( kf->bodyIds != NULL )
	{
		b3Free( kf->bodyIds, (size_t)kf->bodyIdCount * sizeof( b3BodyId ) );
	}
}

// Pre-populate keyframeRec's registry to mirror rdr.slots so geometry ids stay stable during
// b3SerializeWorld. Each slot becomes one entry with id == slot index, even byte-identical slots that
// a hash collision left undeduplicated in an already-recorded file. b3SerializeWorld then resolves a
// live blob back to a valid slot index via the registry's exact dedup, so capture never grows it.
static void b3RecSeedKeyframeRegistry( b3RecPlayer* player )
{
	b3GeometryRegistry* reg = &player->keyframeRec->registry;
	for ( int i = 0; i < player->rdr.slotCount; ++i )
	{
		b3RegistrySlot* slot = player->rdr.slots + i;
		// Copy so the registry can take ownership.
		int n = slot->byteCount > 0 ? slot->byteCount : 1;
		uint8_t* copy = (uint8_t*)b3Alloc( (size_t)n );
		if ( slot->byteCount > 0 )
		{
			memcpy( copy, slot->bytes, (size_t)slot->byteCount );
		}
		uint64_t h = b3Hash64Blob( slot->bytes, slot->byteCount );
		uint32_t id = b3AppendGeometry( reg, slot->kind, h, copy, slot->byteCount );
		// Seeding in order without dedup keeps id == slot index.
		B3_ASSERT( id == (uint32_t)i );
		(void)id;
	}
}

// Capture a restore-point keyframe for the just-completed frame. rdr.cursor already points to
// the next frame's Step op.
static void b3RecCaptureKeyframe( b3RecPlayer* player )
{
	b3World* world = b3GetWorldFromId( player->rdr.replayWorldId );
	b3RecBuffer buf = { 0 };

	int regCountBefore = player->keyframeRec->registry.count;
	B3_UNUSED( regCountBefore );

	b3SerializeWorld( world, &buf, player->keyframeRec );
	// Registry must not grow: all geometry was pre-seeded and the registry dedups exactly.
	B3_ASSERT( player->keyframeRec->registry.count == regCountBefore );

	size_t bodyBytes = (size_t)player->bodyIdCount * sizeof( b3BodyId );
	size_t newBytes = (size_t)buf.capacity + bodyBytes;

	// Make room under the budget by doubling the spacing and evicting off-grid keyframes.
	while ( player->keyframeCount > 0 && player->keyframeBytes + newBytes > player->keyframeBudget )
	{
		player->keyframeInterval *= 2;
		int kept = 0;
		size_t keptBytes = 0;
		for ( int i = 0; i < player->keyframeCount; ++i )
		{
			b3RecKeyframe* kf = player->keyframes + i;
			if ( kf->frame % player->keyframeInterval == 0 )
			{
				player->keyframes[kept] = *kf;
				keptBytes += (size_t)kf->imageCapacity + (size_t)kf->bodyIdCount * sizeof( b3BodyId );
				kept += 1;
			}
			else
			{
				b3FreeKeyframe( kf );
			}
		}
		bool progress = ( kept < player->keyframeCount );
		player->keyframeCount = kept;
		player->keyframeBytes = keptBytes;
		if ( !progress )
		{
			break;
		}
	}

	// Grow the keyframe ring if needed.
	if ( player->keyframeCount >= player->keyframeCapacity )
	{
		int newCap = player->keyframeCapacity < 8 ? 8 : player->keyframeCapacity * 2;
		player->keyframes = (b3RecKeyframe*)b3GrowAlloc(
			player->keyframes, player->keyframeCapacity * (int)sizeof( b3RecKeyframe ), newCap * (int)sizeof( b3RecKeyframe ) );
		player->keyframeCapacity = newCap;
	}

	b3RecKeyframe* kf = player->keyframes + player->keyframeCount;
	kf->image = buf.data;
	kf->imageSize = buf.size;
	kf->imageCapacity = buf.capacity;
	kf->frame = player->frame;
	kf->cursor = player->rdr.cursor;
	kf->divergeFrame = player->divergeFrame;
	kf->diverged = player->rdr.diverged;
	kf->bodyIdCount = player->bodyIdCount;
	kf->bodyIds = NULL;
	if ( bodyBytes > 0 )
	{
		kf->bodyIds = (b3BodyId*)b3Alloc( bodyBytes );
		memcpy( kf->bodyIds, player->bodyIds, bodyBytes );
	}

	player->keyframeBytes += newBytes;
	player->keyframeCount += 1;
	player->lastKeyframeFrame = player->frame;
}

// Restore the world in-place from a keyframe image.
static void b3RecPlayerRestoreKeyframe( b3RecPlayer* player, const b3RecKeyframe* kf )
{
	b3World* world = b3GetWorldFromId( player->rdr.replayWorldId );
	if ( b3DeserializeIntoShell( kf->image, kf->imageSize, world, &player->rdr ) == false )
	{
		player->rdr.ok = false;
		return;
	}
	player->rdr.cursor = kf->cursor;
	player->rdr.ok = true;
	player->rdr.diverged = kf->diverged;
	player->frame = kf->frame;
	player->divergeFrame = kf->divergeFrame;
	player->atEnd = false;
	player->atPreStep = false;

	// Restore the outliner list verbatim so ordinals match this frame.
	b3RecGrow( (void**)&player->bodyIds, &player->bodyIdCap, kf->bodyIdCount, 0, (int)sizeof( b3BodyId ) );
	player->bodyIdCount = kf->bodyIdCount;
	if ( kf->bodyIdCount > 0 )
	{
		memcpy( player->bodyIds, kf->bodyIds, (size_t)kf->bodyIdCount * sizeof( b3BodyId ) );
	}
}

// Create a replay world carrying the host debug-shape callbacks. Every world the player
// stands up funnels through here so the sample renderer can draw replayed shapes.
static b3WorldId b3RecPlayerCreateWorld( const b3RecPlayer* player )
{
	b3WorldDef worldDef = b3DefaultWorldDef();
	worldDef.createDebugShape = player->createDebugShape;
	worldDef.destroyDebugShape = player->destroyDebugShape;
	worldDef.userDebugShapeContext = player->debugShapeContext;
	// Carry the requested worker count so a rebuild on Restart or backward seek keeps the same
	// graph partitioning. Replaying at a different count than recorded is a determinism check.
	worldDef.workerCount = b3MaxInt( 1, player->recordedWorkerCount );
	return b3CreateWorld( &worldDef );
}

b3RecPlayer* b3RecPlayer_Create( const void* data, int size, int workerCount )
{
	if ( data == NULL || size < (int)sizeof( b3RecHeader ) )
	{
		printf( "b3RecPlayer_Create: recording too small\n" );
		return NULL;
	}

	b3RecHeader hdr;
	memcpy( &hdr, data, sizeof( hdr ) );

	if ( hdr.magic != B3_REC_MAGIC )
	{
		printf( "b3RecPlayer_Create: bad magic 0x%08X\n", hdr.magic );
		return NULL;
	}
	// Only the major version is breaking. Minor bumps are additive op-stream changes that keep the
	// header shape, and the dispatcher skips opcodes it doesn't know, so a minor mismatch still loads.
	if ( hdr.versionMajor != B3_REC_VERSION_MAJOR )
	{
		printf( "b3RecPlayer_Create: version mismatch %u.%u vs %u.%u\n", hdr.versionMajor, hdr.versionMinor, B3_REC_VERSION_MAJOR,
				B3_REC_VERSION_MINOR );
		return NULL;
	}
	if ( hdr.pointerWidth != (uint8_t)sizeof( void* ) )
	{
		printf( "b3RecPlayer_Create: pointer width mismatch %u vs %u\n", hdr.pointerWidth, (unsigned)sizeof( void* ) );
		return NULL;
	}
	if ( hdr.bigEndian != 0 )
	{
		printf( "b3RecPlayer_Create: big-endian recording not supported\n" );
		return NULL;
	}

	// Every recording is snapshot-seeded: the seed blob sits between the header and the op stream.
	if ( hdr.snapshotSize == 0 )
	{
		printf( "b3RecPlayer_Create: missing snapshot seed\n" );
		return NULL;
	}

	// snapshotSize and registryOffset are 64-bit and come from the file. Validate in 64-bit so a
	// hostile value can't wrap when narrowed to int, then narrow once the bounds are known good.
	uint64_t headerEnd64 = (uint64_t)sizeof( b3RecHeader ) + hdr.snapshotSize;
	uint64_t registryEnd64 = ( hdr.registryOffset != 0 ) ? hdr.registryOffset : (uint64_t)size;

	if ( headerEnd64 < sizeof( b3RecHeader ) || headerEnd64 > registryEnd64 || registryEnd64 > (uint64_t)size )
	{
		printf( "b3RecPlayer_Create: corrupt offsets\n" );
		return NULL;
	}

	int headerEnd = (int)headerEnd64;
	int registryEnd = (int)registryEnd64;

	// Own a private copy so the caller can free their buffer right away.
	uint8_t* copy = b3Alloc( (size_t)size );
	memcpy( copy, data, (size_t)size );

	b3RecPlayer* player = b3Alloc( sizeof( b3RecPlayer ) );
	memset( player, 0, sizeof( b3RecPlayer ) );

	player->data = copy;
	player->size = size;
	player->headerEnd = headerEnd;
	player->registryEnd = registryEnd;
	player->lengthScale = hdr.lengthScale;
	player->previousLengthScale = b3GetLengthUnitsPerMeter();
	player->frame = 0;
	player->frameCount = 0;
	player->recordedDt = 0.0f;
	player->recordedSubStepCount = 0;
	player->recordedWorkerCount = workerCount;
	player->atEnd = false;
	player->atPreStep = false;
	player->divergeFrame = -1;
	player->keyframeMinInterval = B3_REC_KEYFRAME_INTERVAL_DEFAULT;
	player->keyframeInterval = B3_REC_KEYFRAME_INTERVAL_DEFAULT;
	player->keyframeBudget = B3_REC_KEYFRAME_BUDGET_DEFAULT;
	player->lastKeyframeFrame = 0;

	// Set length scale so replay reproduces the same tuning constants.
	if ( hdr.lengthScale > 0.0f )
	{
		b3SetLengthUnitsPerMeter( hdr.lengthScale );
	}

	// Count frames and read first step's dt so the viewer can show hz up front.
	b3RecScanFile( player );

	// Create the replay world. Debug-shape callbacks are NULL here; the sample wires
	// them right after Create via b3RecPlayer_SetDebugShapeCallbacks, which rebuilds.
	b3WorldId worldId = b3RecPlayerCreateWorld( player );

	// Initialize the reader.
	player->rdr.data = copy;
	player->rdr.size = size;
	player->rdr.cursor = headerEnd;
	player->rdr.replayWorldId = worldId;
	player->rdr.ok = true;
	player->rdr.diverged = false;
	player->rdr.owner = player;

	// Load the trailing geometry registry.
	if ( !b3RecLoadSlots( &player->rdr, copy, size, hdr.registryOffset, hdr.registryByteCount ) )
	{
		b3DestroyWorld( worldId );
		b3Free( copy, (size_t)size );
		b3Free( player, sizeof( b3RecPlayer ) );
		return NULL;
	}

	// Restore the seed snapshot to stand up the replay world. The blob doubles as the frame-0
	// restore image, owned by the copy held above.
	{
		int snapStart = (int)sizeof( b3RecHeader );
		int snapSize = (int)hdr.snapshotSize;
		b3World* replayWorld = b3GetWorldFromId( worldId );
		if ( b3DeserializeIntoShell( copy + snapStart, snapSize, replayWorld, &player->rdr ) == false )
		{
			printf( "b3RecPlayer_Create: snapshot deserialization failed\n" );
			b3DestroyWorld( worldId );
			b3RecFreeSlots( player->rdr.slots, player->rdr.slotCount );
			if ( player->rdr.tags != NULL )
			{
				b3Free( player->rdr.tags, (size_t)player->rdr.tagCapacity * sizeof( b3RecTag ) );
			}
			if ( player->rdr.tagMap != NULL )
			{
				b3RecTagLookup_cleanup( (b3RecTagLookup*)player->rdr.tagMap );
				b3Free( player->rdr.tagMap, sizeof( b3RecTagLookup ) );
			}
			b3Free( copy, (size_t)size );
			b3Free( player, sizeof( b3RecPlayer ) );
			return NULL;
		}
		player->rdr.cursor = headerEnd;
		player->frame0Image = copy + snapStart;
		player->frame0Size = snapSize;
	}

	// Seed the outliner from the restored world (snapshot bodies bypass the create hook) and save
	// the frame-0 restore copy.
	b3RecSeedFrame0BodyIds( player );

	// Build the keyframe recording with a pre-seeded registry that mirrors rdr.slots,
	// so b3SerializeWorld geometry ids stay stable across captures.
	player->keyframeRec = b3CreateRecording( 0 );
	b3RecSeedKeyframeRegistry( player );

	return player;
}

void b3RecPlayer_Destroy( b3RecPlayer* player )
{
	if ( player == NULL )
	{
		return;
	}

	if ( b3World_IsValid( player->rdr.replayWorldId ) )
	{
		b3DestroyWorld( player->rdr.replayWorldId );
	}

	// Free live geometry after destroying the world (slot->live may be used by the world).
	b3RecFreeSlots( player->rdr.slots, player->rdr.slotCount );

	// Free reader scratch.
	if ( player->rdr.matScratch != NULL )
	{
		b3Free( player->rdr.matScratch, (size_t)player->rdr.matScratchCap * sizeof( b3SurfaceMaterial ) );
	}
	if ( player->rdr.proxyScratch != NULL )
	{
		b3Free( player->rdr.proxyScratch, (size_t)player->rdr.proxyScratchCap * sizeof( b3Vec3 ) );
	}
	if ( player->rdr.hits != NULL )
	{
		b3Free( player->rdr.hits, (size_t)player->rdr.hitCap * sizeof( b3RecRecordedHit ) );
	}
	if ( player->rdr.tags != NULL )
	{
		b3Free( player->rdr.tags, (size_t)player->rdr.tagCapacity * sizeof( b3RecTag ) );
	}
	if ( player->rdr.tagMap != NULL )
	{
		b3RecTagLookup_cleanup( (b3RecTagLookup*)player->rdr.tagMap );
		b3Free( player->rdr.tagMap, sizeof( b3RecTagLookup ) );
	}

	// Free the per-frame query store.
	if ( player->frameQueries != NULL )
	{
		b3Free( player->frameQueries, (size_t)player->frameQueryCap * sizeof( b3RecDrawQuery ) );
	}
	if ( player->frameHits != NULL )
	{
		b3Free( player->frameHits, (size_t)player->frameHitCap * sizeof( b3RecRecordedHit ) );
	}

	// Free keyframe ring.
	for ( int i = 0; i < player->keyframeCount; ++i )
	{
		b3FreeKeyframe( player->keyframes + i );
	}
	if ( player->keyframes != NULL )
	{
		b3Free( player->keyframes, (size_t)player->keyframeCapacity * sizeof( b3RecKeyframe ) );
	}

	// The keyframe recording owns only its buffer and registry; b3DestroyRecording frees both.
	if ( player->keyframeRec != NULL )
	{
		b3DestroyRecording( player->keyframeRec );
	}

	// Free the outliner body lists.
	if ( player->bodyIds != NULL )
	{
		b3Free( player->bodyIds, (size_t)player->bodyIdCap * sizeof( b3BodyId ) );
	}
	if ( player->frame0BodyIds != NULL )
	{
		b3Free( player->frame0BodyIds, (size_t)player->frame0BodyIdCount * sizeof( b3BodyId ) );
	}

	// frame0Image points into the owned data copy, not separately allocated.

	b3Free( player->data, (size_t)player->size );

	// Restore the global length scale.
	b3SetLengthUnitsPerMeter( player->previousLengthScale );

	b3Free( player, sizeof( b3RecPlayer ) );
}

bool b3RecPlayer_StepFrame( b3RecPlayer* player )
{
	// This is never true when full stepping
	player->atPreStep = false;

	if ( player->atEnd )
	{
		return false;
	}

	// Reset the per-frame query store before this frame's records are dispatched.
	player->frameQueryCount = 0;
	player->frameHitCount = 0;

	// A frame is its leading inputs (queries and between-step mutators), one Step, and the Step's
	// trailing StateHash. Queries are recorded before the Step they belong to, so they stash here
	// against the world state they were computed for.
	bool stepped = false;
	for ( ;; )
	{
		if ( player->rdr.cursor >= player->registryEnd || !player->rdr.ok )
		{
			player->atEnd = true;
			return stepped;
		}

		// Once stepped, the StateHash is the only record still belonging to this frame. Anything else
		// begins the next frame, so stop and let the next StepFrame consume it. Capture a keyframe at
		// the boundary.
		if ( stepped && player->rdr.data[player->rdr.cursor] != b3_recOpStateHash )
		{
			if ( player->frame > player->lastKeyframeFrame && player->frame % player->keyframeInterval == 0 )
			{
				b3RecCaptureKeyframe( player );
			}
			return true;
		}

		int op = b3RecDispatchOne( &player->rdr );
		if ( op < 0 )
		{
			player->atEnd = true;
			return stepped;
		}
		if ( op == b3_recOpDestroyWorld ) // end of recording
		{
			player->atEnd = true;
			return stepped;
		}
		if ( op == b3_recOpStep )
		{
			player->frame += 1;
			stepped = true;
		}
		else if ( op == b3_recOpStateHash ) // trailing record of the frame just stepped
		{
			// Latch the first frame whose state hash diverged. The hash belongs to the frame Step just
			// advanced, so latch against the current frame, not the next Step which would be one late.
			if ( player->divergeFrame < 0 && player->rdr.diverged )
			{
				player->divergeFrame = player->frame;
			}
		}
	}
}

void b3RecPlayer_SubStepFrame( b3RecPlayer* player )
{
	if ( player->atEnd )
	{
		return;
	}

	// Reset the per-frame query store before this frame's records are dispatched.
	if ( player->atPreStep == false )
	{
		player->frameQueryCount = 0;
		player->frameHitCount = 0;
	}

	// A frame is its leading inputs (queries and between-step mutators), one Step, and the Step's
	// trailing StateHash. Queries are recorded before the Step they belong to, so they stash here
	// against the world state they were computed for.
	bool stepped = false;
	bool haveCreateBodyOp = false;
	for ( ;; )
	{
		if ( player->rdr.cursor >= player->registryEnd || !player->rdr.ok )
		{
			player->atEnd = true;
			player->atPreStep = false;
			return;
		}

		// Once stepped, the StateHash is the only record still belonging to this frame. Anything else
		// begins the next frame, so stop and let the next StepFrame consume it. Capture a keyframe at
		// the boundary.
		uint8_t currentOpCode = player->rdr.data[player->rdr.cursor];
		if ( stepped && currentOpCode != b3_recOpStateHash )
		{
			if ( player->frame > player->lastKeyframeFrame && player->frame % player->keyframeInterval == 0 )
			{
				b3RecCaptureKeyframe( player );
			}
			return;
		}

		if ( player->atPreStep == false && haveCreateBodyOp == true && currentOpCode == b3_recOpStep )
		{
			player->atPreStep = true;
			return;
		}

		int op = b3RecDispatchOne( &player->rdr );
		if ( op < 0 )
		{
			player->atEnd = true;
			player->atPreStep = false;
			return;
		}
		if ( op == b3_recOpDestroyWorld ) // end of recording
		{
			player->atEnd = true;
			player->atPreStep = false;
			return;
		}

		if ( op == b3_recOpCreateBody )
		{
			B3_ASSERT( player->atPreStep == false );
			haveCreateBodyOp = true;
		}

		if ( op == b3_recOpStep )
		{
			player->atPreStep = false;
			player->frame += 1;
			stepped = true;
		}
		else if ( op == b3_recOpStateHash ) // trailing record of the frame just stepped
		{
			// Latch the first frame whose state hash diverged. The hash belongs to the frame Step just
			// advanced, so latch against the current frame, not the next Step which would be one late.
			if ( player->divergeFrame < 0 && player->rdr.diverged )
			{
				player->divergeFrame = player->frame;
			}
		}
	}
}

void b3RecPlayer_Restart( b3RecPlayer* player )
{
	// Restore the frame-0 image in place so the replay world id stays stable across a restart or
	// backward scrub. Stepping resumes at the first Step, which rebuilds the body list deterministically.
	b3World* world = b3GetWorldFromId( player->rdr.replayWorldId );
	if ( b3DeserializeIntoShell( player->frame0Image, player->frame0Size, world, &player->rdr ) == false )
	{
		player->rdr.ok = false;
		return;
	}
	player->rdr.cursor = player->headerEnd;
	player->rdr.ok = true;
	player->rdr.diverged = false;
	player->frame = 0;
	player->divergeFrame = -1;
	player->atEnd = false;
	player->atPreStep = false;

	// Frame 0 is the pre-step snapshot with no recorded queries, so clear the per-frame store. This
	// keeps the last stepped frame's queries from lingering on a restart or a backward scrub to 0.
	player->frameQueryCount = 0;
	player->frameHitCount = 0;

	// Roll the outliner body list back to its frame-0 contents.
	b3RecGrow( (void**)&player->bodyIds, &player->bodyIdCap, player->frame0BodyIdCount, 0, (int)sizeof( b3BodyId ) );
	player->bodyIdCount = player->frame0BodyIdCount;
	if ( player->frame0BodyIdCount > 0 )
	{
		memcpy( player->bodyIds, player->frame0BodyIds, (size_t)player->frame0BodyIdCount * sizeof( b3BodyId ) );
	}
}

void b3RecPlayer_SeekFrame( b3RecPlayer* player, int targetFrame )
{
	if ( player == NULL )
	{
		return;
	}

	player->atPreStep = false;

	if ( targetFrame < 0 )
	{
		targetFrame = 0;
	}

	// Find the best keyframe strictly before the target.
	const b3RecKeyframe* best = NULL;
	for ( int i = 0; i < player->keyframeCount; ++i )
	{
		const b3RecKeyframe* kf = player->keyframes + i;
		if ( kf->frame < targetFrame && ( best == NULL || kf->frame > best->frame ) )
		{
			best = kf;
		}
	}

	if ( targetFrame < player->frame )
	{
		// Backward seek: restore keyframe or restart from frame 0.
		if ( best != NULL )
		{
			b3RecPlayerRestoreKeyframe( player, best );
		}
		else
		{
			b3RecPlayer_Restart( player );
		}
	}
	else if ( best != NULL && best->frame > player->frame )
	{
		// Forward seek that can skip ahead via a keyframe.
		b3RecPlayerRestoreKeyframe( player, best );
	}

	while ( player->frame < targetFrame && b3RecPlayer_StepFrame( player ) )
	{
	}
}

b3WorldId b3RecPlayer_GetWorldId( const b3RecPlayer* player )
{
	return player != NULL ? player->rdr.replayWorldId : b3_nullWorldId;
}

int b3RecPlayer_GetFrame( const b3RecPlayer* player )
{
	return player != NULL ? player->frame : 0;
}

int b3RecPlayer_GetFrameCount( const b3RecPlayer* player )
{
	return player != NULL ? player->frameCount : 0;
}

bool b3RecPlayer_IsAtEnd( const b3RecPlayer* player )
{
	return player != NULL ? player->atEnd : true;
}

bool b3RecPlayer_IsAtPreStep( const b3RecPlayer* player )
{
	return player != NULL ? player->atPreStep : false;
}

bool b3RecPlayer_HasDiverged( const b3RecPlayer* player )
{
	return player != NULL ? player->rdr.diverged : false;
}

b3RecPlayerInfo b3RecPlayer_GetInfo( const b3RecPlayer* player )
{
	b3RecPlayerInfo info = { 0 };
	if ( player != NULL )
	{
		info.frameCount = player->frameCount;
		info.workerCount = player->recordedWorkerCount;
		info.timeStep = player->recordedDt;
		info.subStepCount = player->recordedSubStepCount;
		info.lengthScale = player->lengthScale;
		info.bounds = player->bounds;
	}
	return info;
}

int b3RecPlayer_GetDivergeFrame( const b3RecPlayer* player )
{
	return player != NULL ? player->divergeFrame : -1;
}

void b3RecPlayer_SetWorkerCount( b3RecPlayer* player, int count )
{
	if ( player == NULL )
	{
		return;
	}

	player->recordedWorkerCount = b3ClampInt( count, 1, B3_MAX_WORKERS );

	// Apply to the live world now so the next steps re-partition without a rebuild. Worker count is
	// host state, not part of a keyframe image, so it survives an in-place restore. A rebuild on
	// Restart or deep backward seek picks the count back up through b3RecPlayerCreateWorld.
	if ( b3World_IsValid( player->rdr.replayWorldId ) )
	{
		b3World_SetWorkerCount( player->rdr.replayWorldId, player->recordedWorkerCount );
	}
}

void b3RecPlayer_SetKeyframePolicy( b3RecPlayer* player, size_t budgetBytes, int minIntervalFrames )
{
	if ( player == NULL )
	{
		return;
	}
	if ( budgetBytes > 0 )
	{
		player->keyframeBudget = budgetBytes;
	}
	if ( minIntervalFrames > 0 )
	{
		player->keyframeMinInterval = minIntervalFrames;
	}

	// Drop the ring so it repopulates under the new policy on the next replay.
	for ( int i = 0; i < player->keyframeCount; ++i )
	{
		b3FreeKeyframe( player->keyframes + i );
	}
	player->keyframeCount = 0;
	player->keyframeBytes = 0;
	player->keyframeInterval = player->keyframeMinInterval;
	player->lastKeyframeFrame = 0;
}

size_t b3RecPlayer_GetKeyframeBudget( const b3RecPlayer* player )
{
	return player != NULL ? player->keyframeBudget : 0;
}

int b3RecPlayer_GetKeyframeMinInterval( const b3RecPlayer* player )
{
	return player != NULL ? player->keyframeMinInterval : 0;
}

int b3RecPlayer_GetKeyframeInterval( const b3RecPlayer* player )
{
	return player != NULL ? player->keyframeInterval : 0;
}

size_t b3RecPlayer_GetKeyframeBytes( const b3RecPlayer* player )
{
	return player != NULL ? player->keyframeBytes : 0;
}

int b3RecPlayer_GetBodyCount( const b3RecPlayer* player )
{
	return player != NULL ? player->bodyIdCount : 0;
}

b3BodyId b3RecPlayer_GetBodyId( const b3RecPlayer* player, int index )
{
	if ( player == NULL || index < 0 || index >= player->bodyIdCount )
	{
		return b3_nullBodyId;
	}
	return player->bodyIds[index];
}

// A selected query draws in one reserved color so it stands out when every query is drawn at once.
static b3HexColor b3RecQuerySelColor( bool selected, b3HexColor base )
{
	return selected ? b3_colorPlum : base;
}

// Highlight each reported overlap shape by its AABB. Skip any destroyed since the query, per the
// b3Shape_GetAABB contract that overlap results may contain stale shapes.
static void b3RecDrawHitBounds( const b3RecPlayer* player, const b3RecDrawQuery* q, b3DebugDraw* draw, b3HexColor color )
{
	if ( draw->DrawBoundsFcn == NULL )
	{
		return;
	}
	for ( int hi = q->hitStart; hi < q->hitStart + q->hitCount; ++hi )
	{
		b3ShapeId id = player->frameHits[hi].id;
		if ( b3Shape_IsValid( id ) == false )
		{
			continue;
		}
		draw->DrawBoundsFcn( b3Shape_GetAABB( id ), color, draw->context );
	}
}

// Draw a recorded shape proxy at basePos. A lone point with no radius draws a fat point, a lone point
// with a radius draws a translucent sphere, and a multi-point cloud draws its points. Capsule and hull
// proxies are rare and fall through to the point cloud for now.
static void b3RecDrawProxy( b3DebugDraw* draw, b3Pos basePos, const b3RecDrawQuery* q, b3HexColor color )
{
	if ( q->proxyCount == 1 )
	{
		b3Pos p = b3OffsetPos( basePos, q->proxyPoints[0] );
		if ( q->proxyRadius > 0.0f )
		{
			if ( draw->DrawSphereFcn )
			{
				draw->DrawSphereFcn( p, q->proxyRadius, color, 0.5f, draw->context );
			}
		}
		else if ( draw->DrawPointFcn )
		{
			draw->DrawPointFcn( p, 10.0f, color, draw->context );
		}
	}
	else if ( q->proxyCount == 2 && q->proxyRadius > 0.0f )
	{
		if ( draw->DrawCapsuleFcn )
		{
			b3Pos p1 = b3OffsetPos( basePos, q->proxyPoints[0] );
			b3Pos p2 = b3OffsetPos( basePos, q->proxyPoints[1] );
			draw->DrawCapsuleFcn( p1, p2, q->proxyRadius, color, 0.5f, draw->context );
		}
	}
	else if ( q->proxyCount >= 2 && draw->DrawPointFcn )
	{
		for ( int i = 0; i < q->proxyCount; ++i )
		{
			draw->DrawPointFcn( b3OffsetPos( basePos, q->proxyPoints[i] ), 6.0f, color, draw->context );
		}
	}
}

void b3RecPlayer_DrawFrameQueries( b3RecPlayer* player, b3DebugDraw* draw, int queryIndex, int selectedIndex )
{
	if ( player == NULL || draw == NULL )
	{
		return;
	}

	// queryIndex < 0 draws every query, otherwise just the one selected in the viewer. The query at
	// selectedIndex draws in one reserved color and is labeled, so it stands out among the rest.
	for ( int qi = 0; qi < player->frameQueryCount; ++qi )
	{
		if ( queryIndex >= 0 && qi != queryIndex )
		{
			continue;
		}

		const b3RecDrawQuery* q = &player->frameQueries[qi];
		bool selected = ( qi == selectedIndex );

		switch ( q->kind )
		{
			case B3_RECQ_CAST_RAY:
			case B3_RECQ_CAST_RAY_CLOSEST:
			{
				b3Pos origin = q->origin;
				b3Pos end = b3OffsetPos( origin, q->translation );
				if ( draw->DrawSegmentFcn )
				{
					draw->DrawSegmentFcn( origin, end, b3RecQuerySelColor( selected, b3_colorYellow ), draw->context );
				}
				for ( int hi = q->hitStart; hi < q->hitStart + q->hitCount; ++hi )
				{
					const b3RecRecordedHit* h = &player->frameHits[hi];
					if ( draw->DrawPointFcn )
					{
						draw->DrawPointFcn( h->point, 4.0f, b3RecQuerySelColor( selected, b3_colorYellow ), draw->context );
					}
					if ( draw->DrawSegmentFcn )
					{
						draw->DrawSegmentFcn( h->point, b3OffsetPos( h->point, b3MulSV( 0.2f, h->normal ) ),
											  b3RecQuerySelColor( selected, b3_colorYellowGreen ), draw->context );
					}
				}
				break;
			}
			case B3_RECQ_CAST_SHAPE:
			{
				// Draw the cast line and the proxy at its start, then each hit point and normal.
				if ( draw->DrawSegmentFcn )
				{
					draw->DrawSegmentFcn( q->origin, b3OffsetPos( q->origin, q->translation ),
										  b3RecQuerySelColor( selected, b3_colorSkyBlue ), draw->context );
				}
				b3RecDrawProxy( draw, q->origin, q, b3RecQuerySelColor( selected, b3_colorLightGreen ) );
				for ( int hi = q->hitStart; hi < q->hitStart + q->hitCount; ++hi )
				{
					const b3RecRecordedHit* h = &player->frameHits[hi];
					if ( draw->DrawPointFcn )
					{
						draw->DrawPointFcn( h->point, 4.0f, b3RecQuerySelColor( selected, b3_colorSkyBlue ), draw->context );
					}
					if ( draw->DrawSegmentFcn )
					{
						draw->DrawSegmentFcn( h->point, b3OffsetPos( h->point, b3MulSV( 0.2f, h->normal ) ),
											  b3RecQuerySelColor( selected, b3_colorLightSkyBlue ), draw->context );
					}
					if ( draw->DrawSphereFcn )
					{
						b3Pos p = b3OffsetPos( q->origin, b3MulSV( h->fraction, q->translation ) );
						b3RecDrawProxy( draw, p, q, b3RecQuerySelColor( selected, b3_colorSkyBlue ) );
					}
				}
				break;
			}
			case B3_RECQ_CAST_MOVER:
			{
				b3Pos c1 = b3OffsetPos( q->origin, q->mover.center1 );
				b3Pos c2 = b3OffsetPos( q->origin, q->mover.center2 );
				b3HexColor c = b3_colorLightSkyBlue;
				if ( draw->DrawCapsuleFcn )
				{
					draw->DrawCapsuleFcn( c1, c2, q->mover.radius, b3RecQuerySelColor( selected, c ), 0.6f, draw->context );

					if ( q->castFraction > 0.01f )
					{
						b3Vec3 d = b3MulSV( q->castFraction, q->translation );
						c1 = b3OffsetPos( c1, d );
						c2 = b3OffsetPos( c2, d );
						draw->DrawCapsuleFcn( c1, c2, q->mover.radius, c, 0.3f, draw->context );
					}
				}
				break;
			}

			case B3_RECQ_COLLIDE_MOVER:
			{
				b3Pos c1 = b3OffsetPos( q->origin, q->mover.center1 );
				b3Pos c2 = b3OffsetPos( q->origin, q->mover.center2 );
				b3HexColor c = b3_colorTan;
				if ( draw->DrawCapsuleFcn )
				{
					draw->DrawCapsuleFcn( c1, c2, q->mover.radius, b3RecQuerySelColor( selected, c ), 0.6f, draw->context );
				}

				for ( int hi = q->hitStart; hi < q->hitStart + q->hitCount; ++hi )
				{
					const b3RecRecordedHit* h = &player->frameHits[hi];
					b3Pos point = b3OffsetPos( q->origin, h->plane.point );
					if ( draw->DrawSegmentFcn )
					{
						draw->DrawSegmentFcn( point, b3OffsetPos( point, b3MulSV( 0.2f, h->plane.plane.normal ) ),
											  b3RecQuerySelColor( selected, b3_colorOrange ), draw->context );
					}
				}
				break;
			}

			case B3_RECQ_OVERLAP_AABB:
			{
				if ( draw->DrawBoundsFcn )
				{
					draw->DrawBoundsFcn( q->aabb, b3RecQuerySelColor( selected, b3_colorLimeGreen ), draw->context );
				}
				b3RecDrawHitBounds( player, q, draw, b3RecQuerySelColor( selected, b3_colorMagenta ) );
				break;
			}
			case B3_RECQ_OVERLAP_SHAPE:
			{
				// The overlap proxy sits at the origin; draw it, then the overlapping shape bounds.
				b3RecDrawProxy( draw, q->origin, q, b3RecQuerySelColor( selected, b3_colorLimeGreen ) );
				b3RecDrawHitBounds( player, q, draw, b3RecQuerySelColor( selected, b3_colorMagenta ) );
				break;
			}
			default:
				break;
		}

		// Label the selected query at its origin so it reads by name among the others. The overlap AABB
		// has no origin, so anchor at the box center. Untagged queries (no key) rely on the color alone.
		if ( selected && q->key != 0 && draw->DrawStringFcn != NULL )
		{
			const char* name = NULL;
			uint64_t id = 0;
			if ( player->rdr.tagMap != NULL )
			{
				b3RecTagLookup_itr it = b3RecTagLookup_get( (b3RecTagLookup*)player->rdr.tagMap, q->key );
				if ( b3RecTagLookup_is_end( it ) == false )
				{
					const b3RecTag* tag = &player->rdr.tags[it.data->val];
					name = tag->queryName;
					id = tag->id;
				}
			}
			char label[64];
			if ( name != NULL && name[0] != '\0' && id != 0 )
			{
				snprintf( label, sizeof( label ), "%.40s (%" PRIu64 ")", name, id );
			}
			else if ( name != NULL && name[0] != '\0' )
			{
				snprintf( label, sizeof( label ), "%.40s", name );
			}
			else
			{
				snprintf( label, sizeof( label ), "#%" PRIu64, id );
			}
			b3Pos labelPos = q->origin;
			if ( q->kind == B3_RECQ_OVERLAP_AABB )
			{
				labelPos = b3ToPos( b3AABB_Center( q->aabb ) );
			}
			else if ( q->kind == B3_RECQ_CAST_MOVER || q->kind == B3_RECQ_COLLIDE_MOVER )
			{
				// Sit the label just past the center2 end cap, which for an upright mover is above it.
				b3Pos c1 = b3OffsetPos( q->origin, q->mover.center1 );
				b3Pos c2 = b3OffsetPos( q->origin, q->mover.center2 );
				b3Vec3 dir = b3Normalize( b3SubPos( c2, c1 ) );
				labelPos = b3OffsetPos( c2, b3MulSV( 1.25f * q->mover.radius, dir ) );
			}
			draw->DrawStringFcn( labelPos, label, b3_colorWhite, draw->context );
		}
	}
}

// The internal b3RecQueryKind values match the public b3RecQueryType, so the kind copies across as a
// plain cast. Pin the first and last kinds to catch enum drift.
_Static_assert( b3_recQueryOverlapAABB == 0 && B3_RECQ_OVERLAP_AABB == 0, "query type enum drift" );
_Static_assert( b3_recQueryCollideMover == 6 && B3_RECQ_COLLIDE_MOVER == 6, "query type enum drift" );

int b3RecPlayer_GetFrameQueryCount( const b3RecPlayer* player )
{
	return player != NULL ? player->frameQueryCount : 0;
}

b3RecQueryInfo b3RecPlayer_GetFrameQuery( const b3RecPlayer* player, int index )
{
	b3RecQueryInfo info = { 0 };
	if ( player == NULL || index < 0 || index >= player->frameQueryCount )
	{
		return info;
	}

	const b3RecDrawQuery* q = &player->frameQueries[index];
	info.type = (b3RecQueryType)q->kind;
	info.filter = q->filter;
	info.aabb = q->aabb;
	info.origin = q->origin;
	info.translation = q->translation;
	info.hitCount = q->hitCount;
	info.key = q->key;
	info.id = 0;
	info.name = NULL;
	if ( q->key != 0 && player->rdr.tagMap != NULL )
	{
		b3RecTagLookup_itr it = b3RecTagLookup_get( (b3RecTagLookup*)player->rdr.tagMap, q->key );
		if ( b3RecTagLookup_is_end( it ) == false )
		{
			const b3RecTag* tag = &player->rdr.tags[it.data->val];
			info.id = tag->id;
			// An id-only tag interns an empty name; report it as none so the viewer shows the id alone.
			info.name = tag->queryName[0] != '\0' ? tag->queryName : NULL;
		}
	}
	return info;
}

b3RecQueryHit b3RecPlayer_GetFrameQueryHit( const b3RecPlayer* player, int queryIndex, int hitIndex )
{
	b3RecQueryHit hit = { 0 };
	if ( player == NULL || queryIndex < 0 || queryIndex >= player->frameQueryCount )
	{
		return hit;
	}

	const b3RecDrawQuery* q = &player->frameQueries[queryIndex];
	if ( hitIndex < 0 || hitIndex >= q->hitCount )
	{
		return hit;
	}

	const b3RecRecordedHit* h = &player->frameHits[q->hitStart + hitIndex];
	hit.shape = h->id;
	hit.point = h->point;
	hit.normal = h->normal;
	hit.fraction = h->fraction;
	return hit;
}

void b3RecPlayer_SetDebugShapeCallbacks( b3RecPlayer* player, b3CreateDebugShapeCallback* createDebugShape,
										 b3DestroyDebugShapeCallback* destroyDebugShape, void* context )
{
	if ( player == NULL )
	{
		return;
	}

	player->createDebugShape = createDebugShape;
	player->destroyDebugShape = destroyDebugShape;
	player->debugShapeContext = context;

	// A world fixes its debug-shape callbacks at creation, so rebuild frame 0 under the new
	// wiring. The old world held no adapter shapes (its callbacks were NULL), so the tear-down
	// is balanced. Geometry slots are byte blobs reused as-is, the same path Restart relies on.
	if ( b3World_IsValid( player->rdr.replayWorldId ) )
	{
		b3DestroyWorld( player->rdr.replayWorldId );
	}
	player->rdr.replayWorldId = b3RecPlayerCreateWorld( player );
	player->rdr.cursor = player->headerEnd;
	player->rdr.ok = true;
	player->rdr.diverged = false;
	player->frame = 0;
	player->divergeFrame = -1;
	player->atEnd = false;

	// Re-seed the world so its shapes are recreated through the new callbacks.
	b3World* world = b3GetWorldFromId( player->rdr.replayWorldId );
	if ( b3DeserializeIntoShell( player->frame0Image, player->frame0Size, world, &player->rdr ) == false )
	{
		player->rdr.ok = false;
		return;
	}
	player->rdr.cursor = player->headerEnd;

	// Rebuild the outliner from the frame-0 world that was just stood up under the new callbacks.
	b3RecSeedFrame0BodyIds( player );
}
