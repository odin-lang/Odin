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

void b3ParallelJoint_SetSpringHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, ParallelJointSetSpringHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	base->parallelJoint.hertz = hertz;
}

float b3ParallelJoint_GetSpringHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	return base->parallelJoint.hertz;
}

void b3ParallelJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, ParallelJointSetSpringDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	base->parallelJoint.dampingRatio = dampingRatio;
}

float b3ParallelJoint_GetSpringDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	return base->parallelJoint.dampingRatio;
}

void b3ParallelJoint_SetMaxTorque( b3JointId jointId, float maxForce )
{
	B3_ASSERT( b3IsValidFloat( maxForce ) && maxForce >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, ParallelJointSetMaxTorque, jointId, maxForce );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	base->parallelJoint.maxTorque = maxForce;
}

float b3ParallelJoint_GetMaxTorque( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_parallelJoint );
	return base->parallelJoint.maxTorque;
}

b3Vec3 b3GetParallelJointTorque( b3World* world, b3JointSim* base )
{
	b3ParallelJoint* joint = &base->parallelJoint;

	b3Quat relQ = b3InvMulQuat( joint->quatA, joint->quatB );
	joint->perpAxisX = b3MulSV( 0.5f, b3RotateVector( joint->quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
	joint->perpAxisY = b3MulSV( 0.5f, b3RotateVector( joint->quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );

	b3Vec3 angularImpulse = b3Blend2( joint->perpImpulse.x, joint->perpAxisX, joint->perpImpulse.y, joint->perpAxisY );
	b3Vec3 torque = b3MulSV( world->inv_h, angularImpulse );
	return torque;
}

void b3PrepareParallelJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_parallelJoint );

	b3World* world = context->world;

	b3Body* bodyA = b3Array_Get( world->bodies, base->bodyIdA  );
	b3Body* bodyB = b3Array_Get( world->bodies, base->bodyIdB  );

	B3_ASSERT( bodyA->setIndex == b3_awakeSet || bodyB->setIndex == b3_awakeSet );
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

	b3ParallelJoint* joint = &base->parallelJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->quatA = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->quatB = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );

	b3Quat relQ = b3InvMulQuat( joint->quatA, joint->quatB );

	{
		// These are needed for warm starting
		joint->perpAxisX = b3MulSV( 0.5f, b3RotateVector( joint->quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
		joint->perpAxisY = b3MulSV( 0.5f, b3RotateVector( joint->quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );
	}

	joint->softness = b3MakeSoft( joint->hertz, joint->dampingRatio, context->h );

	if ( context->enableWarmStarting == false )
	{
		joint->perpImpulse = (b3Vec2){ 0.0f, 0.0f };
	}
}

void b3WarmStartParallelJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_parallelJoint );

	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3ParallelJoint* joint = &base->parallelJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	b3Vec3 angularImpulse = b3Blend2( joint->perpImpulse.x, joint->perpAxisX, joint->perpImpulse.y, joint->perpAxisY );

	wA = b3Sub( wA, b3MulMV( iA, angularImpulse ) );
	wB = b3Add( wB, b3MulMV( iB, angularImpulse ) );

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->angularVelocity = wA;
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->angularVelocity = wB;
	}
}

void b3SolveParallelJoint( b3JointSim* base, b3StepContext* context )
{
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3ParallelJoint* joint = &base->parallelJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	bool fixedRotation = base->fixedRotation;
	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->quatA );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->quatB );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the rotation angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	if ( fixedRotation == false && joint->maxTorque > 0.0f )
	{
		b3Vec2 c = { relQ.v.x, relQ.v.y };
		b3Vec2 bias = { joint->softness.biasRate * c.x, joint->softness.biasRate * c.y };
		float massScale = joint->softness.massScale;
		float impulseScale = joint->softness.impulseScale;

		// Collinearity constraint as 2-by-2
		b3Vec3 perpAxisX = b3MulSV( 0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
		b3Vec3 perpAxisY = b3MulSV( 0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );
		joint->perpAxisX = perpAxisX;
		joint->perpAxisY = perpAxisY;

		b3Matrix3 invInertiaSum = b3AddMM( iA, iB );
		float kxx = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisX ) );
		float kyy = b3Dot( perpAxisY, b3MulMV( invInertiaSum, perpAxisY ) );
		float kxy = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisY ) );

		b3Matrix2 k = { { kxx, kxy }, { kxy, kyy } };

		b3Vec3 wRel = b3Sub( wB, wA );
		b3Vec2 cdot = { b3Dot( wRel, perpAxisX ), b3Dot( wRel, perpAxisY ) };

		float maxImpulse = context->h * joint->maxTorque;
		b3Vec2 oldImpulse = joint->perpImpulse;
		b3Vec2 cdotPlusBias = { cdot.x + bias.x, cdot.y + bias.y };
		b3Vec2 sol = b3Solve2( k, cdotPlusBias );
		b3Vec2 deltaImpulse = {
			-massScale * sol.x - impulseScale * oldImpulse.x,
			-massScale * sol.y - impulseScale * oldImpulse.y,
		};
		joint->perpImpulse = (b3Vec2){ oldImpulse.x + deltaImpulse.x, oldImpulse.y + deltaImpulse.y };
		if ( b3LengthSquared2( joint->perpImpulse ) > maxImpulse * maxImpulse )
		{
			float s = maxImpulse / b3Length2( joint->perpImpulse );
			joint->perpImpulse = (b3Vec2){ s * joint->perpImpulse.x, s * joint->perpImpulse.y };
		}

		deltaImpulse = b3Sub2( joint->perpImpulse, oldImpulse );

		b3Vec3 angularImpulse = b3Blend2( deltaImpulse.x, perpAxisX, deltaImpulse.y, perpAxisY );
		wA = b3Sub( wA, b3MulMV( iA, angularImpulse ) );
		wB = b3Add( wB, b3MulMV( iB, angularImpulse ) );
	}

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->angularVelocity = wA;
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->angularVelocity = wB;
	}
}

void b3DrawParallelJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
{
	float length = 0.1f * scale;

	b3WorldTransform frameA = b3MulWorldTransforms( transformA, base->localFrameA );
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( length, b3RotateVector( frameA.q, b3Vec3_axisZ ) ) ), b3_colorGreen, draw->context );

	b3WorldTransform frameB = b3MulWorldTransforms( transformB, base->localFrameB );
	draw->DrawSegmentFcn( frameB.p, b3OffsetPos( frameB.p, b3MulSV( length, b3RotateVector( frameB.q, b3Vec3_axisZ ) ) ), b3_colorBlue, draw->context );
}
