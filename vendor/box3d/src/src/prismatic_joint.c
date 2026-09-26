// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "body.h"
#include "core.h"
#include "joint.h"
#include "math_internal.h"
#include "physics_world.h"
#include "solver.h"
#include "solver_set.h"
#include "recording.h"

// needed for dll export
#include "box3d/box3d.h"

// Linear constraint (point-to-line)
// joint axis is along joint frame A local z-axis
// perpX and perpY are world vectors fixed in A
//
// d = pB - pA = xB + rB - xA - rA
// Cx = dot(perpX, d)
// Cy = dot(perpY, d)

// CdotX = dot(d, cross(wA, perpX)) + dot(perpX, vB + cross(wB, rB) - vA - cross(wA, rA))
//      = -dot(perpX, vA) - dot(cross(d + rA, perpX), wA) + dot(perpX, vB) + dot(cross(rB, perpX), vB)
// Jx = [-perpX, -cross(d + rA, perpX), perpX, cross(rB, perpX)]
// similar for perpY
//
// Simplification dropping dot(d, cross(wA, perpX)) (todo needs testing)
// CdotXs = dot(perpX, vB + cross(wB, rB) - vA - cross(wA, rA))
// Jxs = [-perpX, -cross(rA, perpX), perpX, cross(rB, perpX)]

// Motor/limit/spring linear constraint
// axis is the world joint axis fixed in A

// C = dot(axis, d)
// Cdot = dot(d, cross(wA, axis)) + dot(axis, vB + cross(wB, rB) - vA - cross(wA, rA))
// Cdot = -dot(axis, vA) - dot(cross(d + rA, axis), wA) + dot(axis, vB) + dot(cross(rB, axis), vB)
// J = [-axis -cross(d + rA, axis) axis cross(rB, axis)]
//
// Simplified (todo needs testing)
// Cdot = -dot(axis, vA) - dot(cross(rA, axis), wA) + dot(axis, vB) + dot(cross(rB, axis), vB)
// J = [-axis -cross(rA, axis) axis cross(rB, axis)]

// Predictive limit is applied even when the limit is not active.
// Prevents a constraint speed that can lead to a constraint error in one time step.
// Want C2 = C1 + h * Cdot >= 0
// Or:
// Cdot + C1/h >= 0
// I do not apply a negative constraint error because that is handled in position correction.
// So:
// Cdot + max(C1, 0)/h >= 0

void b3PrismaticJoint_EnableLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointEnableLimit, jointId, enableLimit );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	if ( enableLimit != base->prismaticJoint.enableLimit )
	{
		base->prismaticJoint.lowerImpulse = 0.0f;
		base->prismaticJoint.upperImpulse = 0.0f;
	}
	base->prismaticJoint.enableLimit = enableLimit;
}

bool b3PrismaticJoint_IsLimitEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.enableLimit;
}

float b3PrismaticJoint_GetLowerLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.lowerTranslation;
}

float b3PrismaticJoint_GetUpperLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.upperTranslation;
}

void b3PrismaticJoint_SetLimits( b3JointId jointId, float lower, float upper )
{
	B3_ASSERT( b3IsValidFloat( lower ) && b3IsValidFloat( upper ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetLimits, jointId, lower, upper );
	float lowerAngle = b3MinFloat( lower, upper );
	float upperAngle = b3MaxFloat( lower, upper );

	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.lowerTranslation = lowerAngle;
	base->prismaticJoint.upperTranslation = upperAngle;
}

float b3PrismaticJoint_GetTranslation( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform transformB = b3GetBodyTransform( world, base->bodyIdB );

	b3Vec3 jointAxis = b3RotateVector( base->localFrameA.q, b3Vec3_axisX );
	jointAxis = b3RotateVector( transformA.q, jointAxis );

	b3Vec3 anchorA = b3RotateVector( transformA.q, base->localFrameA.p );
	b3Vec3 anchorB = b3RotateVector( transformB.q, base->localFrameB.p );
	b3Vec3 d = b3Add( b3SubPos( transformB.p, transformA.p ), b3Sub( anchorB, anchorA ) );
	float translation = b3Dot( d, jointAxis );
	return translation;
}

void b3PrismaticJoint_EnableSpring( b3JointId jointId, bool enableSpring )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointEnableSpring, jointId, enableSpring );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	if ( enableSpring != base->prismaticJoint.enableSpring )
	{
		base->prismaticJoint.springImpulse = 0.0f;
	}
	base->prismaticJoint.enableSpring = enableSpring;
}

bool b3PrismaticJoint_IsSpringEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.enableSpring;
}

void b3PrismaticJoint_SetTargetTranslation( b3JointId jointId, float targetTranslation )
{
	B3_ASSERT( b3IsValidFloat( targetTranslation ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetTargetTranslation, jointId, targetTranslation );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.targetTranslation = targetTranslation;
}

float b3PrismaticJoint_GetTargetTranslation( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.targetTranslation;
}

void b3PrismaticJoint_SetSpringHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetSpringHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.hertz = hertz;
}

float b3PrismaticJoint_GetSpringHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.hertz;
}

void b3PrismaticJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetSpringDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.dampingRatio = dampingRatio;
}

float b3PrismaticJoint_GetSpringDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.dampingRatio;
}

void b3PrismaticJoint_EnableMotor( b3JointId jointId, bool enableMotor )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointEnableMotor, jointId, enableMotor );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	if ( enableMotor != base->prismaticJoint.enableMotor )
	{
		base->prismaticJoint.motorImpulse = 0.0f;
	}
	base->prismaticJoint.enableMotor = enableMotor;
}

bool b3PrismaticJoint_IsMotorEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.enableMotor;
}

void b3PrismaticJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed )
{
	B3_ASSERT( b3IsValidFloat( motorSpeed ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetMotorSpeed, jointId, motorSpeed );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.motorSpeed = motorSpeed;
}

float b3PrismaticJoint_GetMotorSpeed( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.motorSpeed;
}

void b3PrismaticJoint_SetMaxMotorForce( b3JointId jointId, float maxForce )
{
	B3_ASSERT( b3IsValidFloat( maxForce ) && maxForce >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, PrismaticJointSetMaxMotorForce, jointId, maxForce );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	base->prismaticJoint.maxMotorForce = maxForce;
}

float b3PrismaticJoint_GetMaxMotorForce( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return base->prismaticJoint.maxMotorForce;
}

float b3PrismaticJoint_GetMotorForce( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );
	return world->inv_h * base->prismaticJoint.motorImpulse;
}

float b3PrismaticJoint_GetSpeed( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_prismaticJoint );

	b3Body* bodyA = b3Array_Get( world->bodies, base->bodyIdA );
	b3Body* bodyB = b3Array_Get( world->bodies, base->bodyIdB );
	b3BodySim* bodySimA = b3GetBodySim( world, bodyA );
	b3BodySim* bodySimB = b3GetBodySim( world, bodyB );
	b3BodyState* stateA = b3GetBodyState( world, bodyA );
	b3BodyState* stateB = b3GetBodyState( world, bodyB );

	b3Quat qA = bodySimA->transform.q;
	b3Quat qB = bodySimB->transform.q;

	b3Vec3 axisA = b3RotateVector( qA, b3RotateVector( base->localFrameA.q, b3Vec3_axisX ) );
	b3Vec3 rA = b3RotateVector( qA, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	b3Vec3 rB = b3RotateVector( qB, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	// Difference the centers in double so the speed stays exact far from the origin.
	b3Vec3 d = b3Add( b3SubPos( bodySimB->center, bodySimA->center ), b3Sub( rB, rA ) );

	b3Vec3 vA = stateA ? stateA->linearVelocity : b3Vec3_zero;
	b3Vec3 vB = stateB ? stateB->linearVelocity : b3Vec3_zero;
	b3Vec3 wA = stateA ? stateA->angularVelocity : b3Vec3_zero;
	b3Vec3 wB = stateB ? stateB->angularVelocity : b3Vec3_zero;

	b3Vec3 vRel = b3Sub( b3Add( vB, b3Cross( wB, rB ) ), b3Add( vA, b3Cross( wA, rA ) ) );

	// The axis moves with body A, so account for its rotation.
	float speed = b3Dot( d, b3Cross( wA, axisA ) ) + b3Dot( axisA, vRel );
	return speed;
}

b3Vec3 b3GetPrismaticJointForce( b3World* world, b3JointSim* base )
{
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3PrismaticJoint* joint = &base->prismaticJoint;

	// impulse in joint space
	b3Vec3 impulse = {
		joint->perpImpulse.x,
		joint->perpImpulse.y,
		joint->motorImpulse + joint->lowerImpulse + joint->upperImpulse + joint->springImpulse,
	};

	// convert impulse to force
	b3Vec3 force = b3MulSV( world->inv_h, impulse );

	// convert to body space
	force = b3RotateVector( base->localFrameA.q, force );

	// convert to world space
	force = b3RotateVector( transformA.q, force );
	return force;
}

b3Vec3 b3GetPrismaticJointTorque( b3World* world, b3JointSim* base )
{
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3PrismaticJoint* joint = &base->prismaticJoint;

	b3Vec3 torque = b3MulSV( world->inv_h, joint->angularImpulse );
	torque = b3RotateVector( base->localFrameA.q, torque );
	torque = b3RotateVector( transformA.q, torque );
	return torque;
}

void b3PreparePrismaticJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_prismaticJoint );

	b3World* world = context->world;

	b3Body* bodyA = b3Array_Get( world->bodies, base->bodyIdA  );
	b3Body* bodyB = b3Array_Get( world->bodies, base->bodyIdB  );

	B3_ASSERT( bodyB->setIndex == b3_awakeSet );
	b3SolverSet* setA = b3Array_Get( world->solverSets, bodyA->setIndex  );
	b3SolverSet* setB = b3Array_Get( world->solverSets, bodyB->setIndex  );

	int localIndexA = bodyA->localIndex;
	int localIndexB = bodyB->localIndex;

	b3BodySim* bodySimA = b3Array_Get( setA->bodySims, localIndexA  );
	b3BodySim* bodySimB = b3Array_Get( setB->bodySims, localIndexB  );

	base->invMassA = bodySimA->invMass;
	base->invMassB = bodySimB->invMass;
	base->invIA = bodySimA->invInertiaWorld;
	base->invIB = bodySimB->invInertiaWorld;

	b3Matrix3 invInertiaSum = b3AddMM( base->invIA, base->invIB );
	base->fixedRotation = b3Det( invInertiaSum ) < 1000.0f * FLT_MIN;

	b3PrismaticJoint* joint = &base->prismaticJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );
	joint->rotationMass = b3InvertMatrix( invInertiaSum );

	// Initial joint axes in world space
	b3Matrix3 matrixA = b3MakeMatrixFromQuat( joint->frameA.q );
	joint->jointAxis = matrixA.cx;
	joint->perpAxisY = matrixA.cy;
	joint->perpAxisZ = matrixA.cz;

	joint->springSoftness = b3MakeSoft( joint->hertz, joint->dampingRatio, context->h );

	if ( context->enableWarmStarting == false )
	{
		joint->perpImpulse = (b3Vec2){ 0.0f, 0.0f };
		joint->angularImpulse = (b3Vec3){ 0.0f, 0.0f, 0.0f };
		joint->motorImpulse = 0.0f;
		joint->springImpulse = 0.0f;
		joint->lowerImpulse = 0.0f;
		joint->upperImpulse = 0.0f;
	}
}

void b3WarmStartPrismaticJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_prismaticJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3PrismaticJoint* joint = &base->prismaticJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	// todo make this code and the wheel joint more similar

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );
	b3Vec3 d = b3Add( b3Add( b3Sub( stateB->deltaPosition, stateA->deltaPosition ), joint->deltaCenter ), b3Sub( rB, rA ) );
	b3Vec3 jointAxis = b3RotateVector( stateA->deltaRotation, joint->jointAxis );
	b3Vec3 sAx = b3Cross( b3Add( rA, d ), jointAxis );
	b3Vec3 sBx = b3Cross( rB, jointAxis );

	b3Vec3 perpY = b3RotateVector( stateA->deltaRotation, joint->perpAxisY );
	b3Vec3 perpZ = b3RotateVector( stateA->deltaRotation, joint->perpAxisZ );
	b3Vec3 sAy = b3Cross( b3Add( rA, d ), perpY );
	b3Vec3 sBy = b3Cross( rB, perpY );
	b3Vec3 sAz = b3Cross( b3Add( rA, d ), perpZ );
	b3Vec3 sBz = b3Cross( rB, perpZ );

	float axialImpulse = joint->springImpulse + joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse;
	b3Vec2 perpImpulse = joint->perpImpulse;

	b3Vec3 P = b3Blend3( axialImpulse, jointAxis, perpImpulse.x, perpY, perpImpulse.y, perpZ );
	b3Vec3 LA = b3Add( b3Blend3( axialImpulse, sAx, perpImpulse.x, sAy, perpImpulse.y, sAz ), joint->angularImpulse );
	b3Vec3 LB = b3Add( b3Blend3( axialImpulse, sBx, perpImpulse.x, sBy, perpImpulse.y, sBz ), joint->angularImpulse );

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;
	vA = b3MulSub( vA, mA, P );
	wA = b3Sub( wA, b3MulMV( iA, LA ) );
	vB = b3MulAdd( vB, mB, P );
	wB = b3Add( wB, b3MulMV( iB, LB ) );

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->linearVelocity = vA;
		stateA->angularVelocity = wA;
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->linearVelocity = vB;
		stateB->angularVelocity = wB;
	}
}

void b3SolvePrismaticJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3PrismaticJoint* joint = &base->prismaticJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	bool fixedRotation = base->fixedRotation;
	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	b3Vec3 dcA = stateA->deltaPosition;
	b3Vec3 dcB = stateB->deltaPosition;
	b3Vec3 d = b3Add( b3Add( b3Sub( dcB, dcA ), joint->deltaCenter ), b3Sub( rB, rA ) );

	b3Vec3 jointAxis = b3RotateVector( stateA->deltaRotation, joint->jointAxis );
	b3Vec3 sAx = b3Cross( b3Add( rA, d ), jointAxis );
	b3Vec3 sBx = b3Cross( rB, jointAxis );
	float jointTranslation = b3Dot( d, jointAxis );
	float targetTranslation = joint->targetTranslation;

	// The axial effective mass must be fresh to avoid divergence when the joint is stressed
	float ka = mA + mB + b3Dot( sAx, b3MulMV( iA, sAx ) ) + b3Dot( sBx, b3MulMV( iB, sBx ) );
	float axialMass = ka > 0.0f ? 1.0f / ka : 0.0f;

	// Solve spring
	if ( joint->enableSpring && fixedRotation == false )
	{
		// Get the substep relative rotation
		float c = jointTranslation - targetTranslation;

		float bias = joint->springSoftness.biasRate * c;
		float massScale = joint->springSoftness.massScale;
		float impulseScale = joint->springSoftness.impulseScale;

		b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
		float cdot = b3Dot( vRel, jointAxis );
		float deltaImpulse = -massScale * axialMass * ( cdot + bias ) - impulseScale * joint->springImpulse;
		joint->springImpulse += deltaImpulse;

		b3Vec3 P = b3MulSV( deltaImpulse, jointAxis );
		b3Vec3 LA = b3MulSV( deltaImpulse, sAx );
		b3Vec3 LB = b3MulSV( deltaImpulse, sBx );

		vA = b3MulSub( vA, mA, P );
		wA = b3Sub( wA, b3MulMV( iA, LA ) );
		vB = b3MulAdd( vB, mB, P );
		wB = b3Add( wB, b3MulMV( iB, LB ) );
	}

	if ( joint->enableMotor && fixedRotation == false )
	{
		b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
		float cdot = b3Dot( vRel, jointAxis ) - joint->motorSpeed;

		float deltaImpulse = -axialMass * cdot;
		float newImpulse = joint->motorImpulse + deltaImpulse;
		float maxImpulse = joint->maxMotorForce * context->h;
		newImpulse = b3ClampFloat( newImpulse, -maxImpulse, maxImpulse );
		deltaImpulse = newImpulse - joint->motorImpulse;
		joint->motorImpulse = newImpulse;

		b3Vec3 P = b3MulSV( deltaImpulse, jointAxis );
		b3Vec3 LA = b3MulSV( deltaImpulse, sAx );
		b3Vec3 LB = b3MulSV( deltaImpulse, sBx );

		vA = b3MulSub( vA, mA, P );
		wA = b3Sub( wA, b3MulMV( iA, LA ) );
		vB = b3MulAdd( vB, mB, P );
		wB = b3Add( wB, b3MulMV( iB, LB ) );
	}

	if ( joint->enableLimit && fixedRotation == false )
	{
		float speculativeDistance = 0.25f * ( joint->upperTranslation - joint->lowerTranslation );

		// Lower limit
		{
			float C = jointTranslation - joint->lowerTranslation;

			if ( C < speculativeDistance )
			{
				float bias = 0.0f;
				float massScale = 1.0f;
				float impulseScale = 0.0f;
				if ( C > 0.0f )
				{
					// speculation
					bias = C * context->inv_h;
				}
				else if ( useBias )
				{
					bias = base->constraintSoftness.biasRate * C;
					massScale = base->constraintSoftness.massScale;
					impulseScale = base->constraintSoftness.impulseScale;
				}

				b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
				float cdot = b3Dot( vRel, jointAxis );
				float oldImpulse = joint->lowerImpulse;
				float deltaImpulse = -massScale * axialMass * ( cdot + bias ) - impulseScale * oldImpulse;
				joint->lowerImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
				deltaImpulse = joint->lowerImpulse - oldImpulse;

				b3Vec3 P = b3MulSV( deltaImpulse, jointAxis );
				b3Vec3 LA = b3MulSV( deltaImpulse, sAx );
				b3Vec3 LB = b3MulSV( deltaImpulse, sBx );

				vA = b3MulSub( vA, mA, P );
				wA = b3Sub( wA, b3MulMV( iA, LA ) );
				vB = b3MulAdd( vB, mB, P );
				wB = b3Add( wB, b3MulMV( iB, LB ) );
			}
			else
			{
				joint->lowerImpulse = 0.0f;
			}
		}

		// Upper limit
		{
			float C = joint->upperTranslation - jointTranslation;

			if ( C < speculativeDistance )
			{
				float bias = 0.0f;
				float massScale = 1.0f;
				float impulseScale = 0.0f;
				if ( C > 0.0f )
				{
					// speculation
					bias = C * context->inv_h;
				}
				else if ( useBias )
				{
					bias = base->constraintSoftness.biasRate * C;
					massScale = base->constraintSoftness.massScale;
					impulseScale = base->constraintSoftness.impulseScale;
				}

				// sign flipped on Cdot
				b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
				float cdot = -b3Dot( vRel, jointAxis );
				float oldImpulse = joint->upperImpulse;
				float deltaImpulse = -massScale * axialMass * ( cdot + bias ) - impulseScale * oldImpulse;
				joint->upperImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );

				// sign flipped on applied impulse
				float negDeltaImpulse = oldImpulse - joint->upperImpulse;
				b3Vec3 P = b3MulSV( negDeltaImpulse, jointAxis );
				b3Vec3 LA = b3MulSV( negDeltaImpulse, sAx );
				b3Vec3 LB = b3MulSV( negDeltaImpulse, sBx );

				vA = b3MulSub( vA, mA, P );
				wA = b3Sub( wA, b3MulMV( iA, LA ) );
				vB = b3MulAdd( vB, mB, P );
				wB = b3Add( wB, b3MulMV( iB, LB ) );
			}
			else
			{
				joint->upperImpulse = 0.0f;
			}
		}
	}

	// Rotation constraint
	if ( fixedRotation == false )
	{
		b3Vec3 bias = { 0.0f, 0.0f, 0.0f };
		float massScale = 1.0f;
		float impulseScale = 0.0f;

		if ( useBias )
		{
			b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
			b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );

			b3Quat relQ = b3InvMulQuat( quatA, quatB );
			b3Quat targetQuat = b3Quat_identity;
			b3Vec3 deltaRotation = b3DeltaQuatToRotation( relQ, targetQuat );
			b3Vec3 c = b3Neg( b3RotateVector( quatA, deltaRotation ) );

			bias = b3MulSV( base->constraintSoftness.biasRate, c );
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		b3Vec3 cdot = b3Sub( wB, wA );
		b3Vec3 impulse = b3Sub(
			b3MulSV( -massScale, b3MulMV( joint->rotationMass, b3Add( cdot, bias ) ) ),
			b3MulSV( impulseScale, joint->angularImpulse ) );
		joint->angularImpulse = b3Add( joint->angularImpulse, impulse );

		wA = b3Sub( wA, b3MulMV( iA, impulse ) );
		wB = b3Add( wB, b3MulMV( iB, impulse ) );
	}

	// Solve point-to-line constraint
	{
		b3Vec3 perpY = b3RotateVector( stateA->deltaRotation, joint->perpAxisY );
		b3Vec3 perpZ = b3RotateVector( stateA->deltaRotation, joint->perpAxisZ );

		b3Vec2 bias = { 0.0f, 0.0f };
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias )
		{
			b3Vec2 c = { b3Dot( perpY, d ), b3Dot( perpZ, d ) };
			bias = b3MulSV2( base->constraintSoftness.biasRate, c );
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
		b3Vec2 cdot = { b3Dot( perpY, vRel ), b3Dot( perpZ, vRel ) };

		// K = [(1/mA + 1/mB) * eye(2) - skew(rA) * invIA * skew(rA) - skew(rB) * invIB * skew(rB)]
		// Jx = [-perpX, -cross(d + rA, perpX), perpX, cross(rB, perpX)]
		b3Vec3 sAy = b3Cross( b3Add( rA, d ), perpY );
		b3Vec3 sBy = b3Cross( rB, perpY );
		b3Vec3 sAz = b3Cross( b3Add( rA, d ), perpZ );
		b3Vec3 sBz = b3Cross( rB, perpZ );

		float kyy = mA + mB + b3Dot( sAy, b3MulMV( iA, sAy ) ) + b3Dot( sBy, b3MulMV( iB, sBy ) );
		float kyz = b3Dot( sAy, b3MulMV( iA, sAz ) ) + b3Dot( sBy, b3MulMV( iB, sBz ) );
		float kzz = mA + mB + b3Dot( sAz, b3MulMV( iA, sAz ) ) + b3Dot( sBz, b3MulMV( iB, sBz ) );

		b3Matrix2 K = { { kyy, kyz }, { kyz, kzz } };

		b3Vec2 oldImpulse = joint->perpImpulse;
		b3Vec2 sol = b3Solve2( K, b3Add2( cdot, bias ) );
		b3Vec2 deltaImpulse = b3Sub2( b3MulSV2( -massScale, sol ), b3MulSV2( impulseScale, oldImpulse ) );
		joint->perpImpulse = b3Add2( oldImpulse, deltaImpulse );

		b3Vec3 P = b3Blend2( deltaImpulse.x, perpY, deltaImpulse.y, perpZ );

		vA = b3MulSub( vA, mA, P );
		wA = b3Sub( wA, b3MulMV( iA, b3Blend2( deltaImpulse.x, sAy, deltaImpulse.y, sAz ) ) );
		vB = b3MulAdd( vB, mB, P );
		wB = b3Add( wB, b3MulMV( iB, b3Blend2( deltaImpulse.x, sBy, deltaImpulse.y, sBz ) ) );
	}

	B3_ASSERT( b3IsValidVec3( vA ) );
	B3_ASSERT( b3IsValidVec3( wA ) );
	B3_ASSERT( b3IsValidVec3( vB ) );
	B3_ASSERT( b3IsValidVec3( wB ) );

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->linearVelocity = vA;
		stateA->angularVelocity = wA;
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->linearVelocity = vB;
		stateB->angularVelocity = wB;
	}
}

void b3DrawPrismaticJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
{
	b3WorldTransform frameA = b3MulWorldTransforms( transformA, base->localFrameA );
	b3WorldTransform frameB = b3MulWorldTransforms( transformB, base->localFrameB );

	b3Matrix3 R = b3MakeMatrixFromQuat( frameA.q );
	b3Vec3 axis = R.cx;
	b3Vec3 perpY = R.cy;
	b3Vec3 perpZ = R.cz;

	float s = 0.2f * scale;
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( s, perpY ) ), b3_colorGreen, draw->context );
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( s, perpZ ) ), b3_colorBlue, draw->context );

	b3PrismaticJoint* joint = &base->prismaticJoint;
	if ( joint->enableLimit )
	{
		b3Pos p1 = b3OffsetPos( frameA.p, b3MulSV( joint->lowerTranslation, axis ) );
		b3Pos p2 = b3OffsetPos( frameA.p, b3MulSV( joint->upperTranslation, axis ) );
		draw->DrawSegmentFcn( p1, p2, b3_colorOrange, draw->context );
		draw->DrawPointFcn( p1, 10.0f, b3_colorGreen, draw->context );
		draw->DrawPointFcn( p2, 10.0f, b3_colorRed, draw->context );
	}
	else
	{
		b3Pos p1 = b3OffsetPos( frameA.p, b3MulSV( -0.5f * scale, axis ) );
		b3Pos p2 = b3OffsetPos( frameA.p, b3MulSV( 0.5f * scale, axis ) );
		draw->DrawSegmentFcn( p1, p2, b3_colorOrange, draw->context );
	}

	draw->DrawPointFcn( frameB.p, 8.0f, b3_colorViolet, draw->context );
}
