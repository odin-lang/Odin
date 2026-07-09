// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "body.h"
#include "joint.h"
#include "physics_world.h"
#include "solver.h"
#include "solver_set.h"
#include "recording.h"

// needed for dll export
#include "box3d/box3d.h"

void b3WeldJoint_SetLinearHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WeldJointSetLinearHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	base->weldJoint.linearHertz = hertz;
}

float b3WeldJoint_GetLinearHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	return base->weldJoint.linearHertz;
}

void b3WeldJoint_SetLinearDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WeldJointSetLinearDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	base->weldJoint.linearDampingRatio = dampingRatio;
}

float b3WeldJoint_GetLinearDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	return base->weldJoint.linearDampingRatio;
}

void b3WeldJoint_SetAngularHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WeldJointSetAngularHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	base->weldJoint.angularHertz = hertz;
}

float b3WeldJoint_GetAngularHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	return base->weldJoint.angularHertz;
}

void b3WeldJoint_SetAngularDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WeldJointSetAngularDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	base->weldJoint.angularDampingRatio = dampingRatio;
}

float b3WeldJoint_GetAngularDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_weldJoint );
	return base->weldJoint.angularDampingRatio;
}

b3Vec3 b3GetWeldJointForce( b3World* world, b3JointSim* base )
{
	b3Vec3 force = b3MulSV( world->inv_h, base->weldJoint.linearImpulse );
	return force;
}

b3Vec3 b3GetWeldJointTorque( b3World* world, b3JointSim* base )
{
	return b3MulSV( world->inv_h, base->weldJoint.angularImpulse );
}

void b3PrepareWeldJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_weldJoint );

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

	b3WeldJoint* joint = &base->weldJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );
	joint->angularMass = b3InvertMatrix( invInertiaSum );

	if ( joint->linearHertz == 0.0f )
	{
		joint->linearSpring = base->constraintSoftness;
	}
	else
	{
		joint->linearSpring = b3MakeSoft( joint->linearHertz, joint->linearDampingRatio, context->h );
	}

	if ( joint->angularHertz == 0.0f )
	{
		joint->angularSpring = base->constraintSoftness;
	}
	else
	{
		joint->angularSpring = b3MakeSoft( joint->angularHertz, joint->angularDampingRatio, context->h );
	}

	if ( context->enableWarmStarting == false )
	{
		joint->linearImpulse = b3Vec3_zero;
		joint->angularImpulse = b3Vec3_zero;
	}
}

void b3WarmStartWeldJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_weldJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3WeldJoint* joint = &base->weldJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	vA = b3MulSub( vA, mA, joint->linearImpulse );
	wA = b3Sub( wA, b3MulMV( iA, b3Add( b3Cross( rA, joint->linearImpulse ), joint->angularImpulse ) ) );

	vB = b3MulAdd( vB, mB, joint->linearImpulse );
	wB = b3Add( wB, b3MulMV( iB, b3Add( b3Cross( rB, joint->linearImpulse ), joint->angularImpulse ) ) );

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

void b3SolveWeldJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3WeldJoint* joint = &base->weldJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	bool fixedRotation = base->fixedRotation;
	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the rotation angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	// angular constraint
	if ( fixedRotation == false )
	{
		b3Vec3 bias = b3Vec3_zero;
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias || joint->angularHertz > 0.0f )
		{
			b3Quat targetQuat = b3Quat_identity;
			b3Vec3 deltaRotation = b3DeltaQuatToRotation( relQ, targetQuat );
			b3Vec3 c = b3Neg( b3RotateVector( quatA, deltaRotation ) );

			bias = b3MulSV( joint->angularSpring.biasRate, c );
			massScale = joint->angularSpring.massScale;
			impulseScale = joint->angularSpring.impulseScale;
		}

		b3Vec3 cdot = b3Sub( wB, wA );
		b3Vec3 impulse = b3MulSub( b3MulSV( -massScale, b3MulMV( joint->angularMass, b3Add( cdot, bias ) ) ), impulseScale, joint->angularImpulse );
		joint->angularImpulse = b3Add( joint->angularImpulse, impulse );

		wA = b3Sub( wA, b3MulMV( iA, impulse ) );
		wB = b3Add( wB, b3MulMV( iB, impulse ) );
	}

	// linear constraint
	{
		b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
		b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

		b3Vec3 cdot = b3Sub( b3Add( vB, b3Cross( wB, rB ) ), b3Add( vA, b3Cross( wA, rA ) ) );

		b3Vec3 bias = b3Vec3_zero;
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias || joint->linearHertz > 0.0f )
		{
			b3Vec3 dcA = stateA->deltaPosition;
			b3Vec3 dcB = stateB->deltaPosition;

			b3Vec3 separation = b3Add( b3Add( b3Sub( dcB, dcA ), b3Sub( rB, rA ) ), joint->deltaCenter );

			bias = b3MulSV( joint->linearSpring.biasRate, separation );
			massScale = joint->linearSpring.massScale;
			impulseScale = joint->linearSpring.impulseScale;
		}

		//// K = [(1/m1 + 1/m2) * eye(2) - skew(r1) * invI1 * skew(r1) - skew(r2) * invI2 * skew(r2)]
		b3Matrix3 sA = b3Skew( rA );
		b3Matrix3 sB = b3Skew( rB );
		b3Matrix3 kA = b3MulMM( sA, b3MulMM( base->invIA, sA ) );
		b3Matrix3 kB = b3MulMM( sB, b3MulMM( base->invIB, sB ) );
		b3Matrix3 k = b3NegateMat3( b3AddMM( kA, kB ) );
		k.cx.x += mA + mB;
		k.cy.y += mA + mB;
		k.cz.z += mA + mB;

		b3Vec3 b = b3Solve3( k, b3Add( cdot, bias ) );

		b3Vec3 impulse = b3MulSub( b3MulSV( -massScale, b ), impulseScale, joint->linearImpulse );
		joint->linearImpulse = b3Add( joint->linearImpulse, impulse );

		vA = b3MulSub( vA, mA, impulse );
		wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, impulse ) ) );
		vB = b3MulAdd( vB, mB, impulse );
		wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, impulse ) ) );
	}

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

void b3DrawWeldJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
{
	b3WorldTransform frameA = b3MulWorldTransforms( transformA, base->localFrameA );
	b3WorldTransform frameB = b3MulWorldTransforms( transformB, base->localFrameB );

	b3Vec3 extents = { 0.1f * scale, 0.05f * scale, 0.025f * scale };
	draw->DrawBoxFcn( extents, frameA, b3_colorDarkOrange, draw->context );
	draw->DrawBoxFcn( extents, frameB, b3_colorDarkCyan, draw->context );
}
