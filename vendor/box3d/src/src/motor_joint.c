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

void b3MotorJoint_SetLinearVelocity( b3JointId jointId, b3Vec3 velocity )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetLinearVelocity, jointId, velocity );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.linearVelocity = velocity;
}

b3Vec3 b3MotorJoint_GetLinearVelocity( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.linearVelocity;
}

void b3MotorJoint_SetAngularVelocity( b3JointId jointId, b3Vec3 velocity )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetAngularVelocity, jointId, velocity );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.angularVelocity = velocity;
}

b3Vec3 b3MotorJoint_GetAngularVelocity( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.angularVelocity;
}

void b3MotorJoint_SetMaxVelocityTorque( b3JointId jointId, float maxTorque )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetMaxVelocityTorque, jointId, maxTorque );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.maxVelocityTorque = maxTorque;
}

float b3MotorJoint_GetMaxVelocityTorque( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.maxVelocityTorque;
}

void b3MotorJoint_SetMaxVelocityForce( b3JointId jointId, float maxForce )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetMaxVelocityForce, jointId, maxForce );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.maxVelocityForce = maxForce;
}

float b3MotorJoint_GetMaxVelocityForce( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.maxVelocityForce;
}

void b3MotorJoint_SetLinearHertz( b3JointId jointId, float hertz )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetLinearHertz, jointId, hertz );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.linearHertz = hertz;
}

float b3MotorJoint_GetLinearHertz( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.linearHertz;
}

void b3MotorJoint_SetLinearDampingRatio( b3JointId jointId, float damping )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetLinearDampingRatio, jointId, damping );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.linearDampingRatio = damping;
}

float b3MotorJoint_GetLinearDampingRatio( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.linearDampingRatio;
}

void b3MotorJoint_SetAngularHertz( b3JointId jointId, float hertz )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetAngularHertz, jointId, hertz );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.angularHertz = hertz;
}

float b3MotorJoint_GetAngularHertz( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.angularHertz;
}

void b3MotorJoint_SetAngularDampingRatio( b3JointId jointId, float damping )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetAngularDampingRatio, jointId, damping );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.angularDampingRatio = damping;
}

float b3MotorJoint_GetAngularDampingRatio( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.angularDampingRatio;
}

void b3MotorJoint_SetMaxSpringForce( b3JointId jointId, float maxForce )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetMaxSpringForce, jointId, maxForce );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.maxSpringForce = b3MaxFloat( 0.0f, maxForce );
}

float b3MotorJoint_GetMaxSpringForce( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.maxSpringForce;
}

void b3MotorJoint_SetMaxSpringTorque( b3JointId jointId, float maxTorque )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, MotorJointSetMaxSpringTorque, jointId, maxTorque );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	joint->motorJoint.maxSpringTorque = b3MaxFloat( 0.0f, maxTorque );
}

float b3MotorJoint_GetMaxSpringTorque( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_motorJoint );
	return joint->motorJoint.maxSpringTorque;
}

b3Vec3 b3GetMotorJointForce( b3World* world, b3JointSim* base )
{
	b3Vec3 force = b3MulSV( world->inv_h, b3Add( base->motorJoint.linearVelocityImpulse, base->motorJoint.linearSpringImpulse ) );
	return force;
}

b3Vec3 b3GetMotorJointTorque( b3World* world, b3JointSim* base )
{
	return b3MulSV( world->inv_h, b3Add( base->motorJoint.angularVelocityImpulse, base->motorJoint.angularSpringImpulse ) );
}

// Point-to-point constraint
// C = p2 - p1
// Cdot = v2 - v1
//      = v2 + cross(w2, r2) - v1 - cross(w1, r1)
// J = [-I -r1_skew I r2_skew ]
// Identity used:
// w k % (rx i + ry j) = w * (-ry i + rx j)

// Angle constraint
// C = angle2 - angle1 - referenceAngle
// Cdot = w2 - w1
// J = [0 0 -1 0 0 1]
// K = invI1 + invI2

void b3PrepareMotorJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_motorJoint );

	// chase body id to the solver set where the body lives
	int idA = base->bodyIdA;
	int idB = base->bodyIdB;

	b3World* world = context->world;

	b3Body* bodyA = b3Array_Get( world->bodies, idA  );
	b3Body* bodyB = b3Array_Get( world->bodies, idB  );

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

	b3MotorJoint* joint = &base->motorJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	// Compute the initial center delta. Incremental position updates are relative to this.
	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );

	joint->linearSpring = b3MakeSoft( joint->linearHertz, joint->linearDampingRatio, context->h );
	joint->angularSpring = b3MakeSoft( joint->angularHertz, joint->angularDampingRatio, context->h );

	joint->angularMass = b3InvertMatrix( invInertiaSum );

	if ( context->enableWarmStarting == false )
	{
		joint->linearVelocityImpulse = b3Vec3_zero;
		joint->angularVelocityImpulse = b3Vec3_zero;
		joint->linearSpringImpulse = b3Vec3_zero;
		joint->angularSpringImpulse = b3Vec3_zero;
	}
}

void b3WarmStartMotorJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_motorJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	b3MotorJoint* joint = &base->motorJoint;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	b3Vec3 linearImpulse = b3Add( joint->linearVelocityImpulse, joint->linearSpringImpulse );
	b3Vec3 angularImpulse = b3Add( joint->angularVelocityImpulse, joint->angularSpringImpulse );

	stateA->linearVelocity = b3MulSub( stateA->linearVelocity, mA, linearImpulse );
	stateA->angularVelocity = b3Sub( stateA->angularVelocity, b3MulMV( iA, b3Add( b3Cross( rA, linearImpulse ), angularImpulse ) ) );
	stateB->linearVelocity = b3MulAdd( stateB->linearVelocity, mB, linearImpulse );
	stateB->angularVelocity = b3Add( stateB->angularVelocity, b3MulMV( iB, b3Add( b3Cross( rB, linearImpulse ), angularImpulse ) ) );
}

void b3SolveMotorJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_motorJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3MotorJoint* joint = &base->motorJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the rotation angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	// angular spring
	if ( joint->maxSpringTorque > 0.0f && joint->angularHertz > 0.0f )
	{
		b3Quat targetQuat = b3Quat_identity;
		b3Vec3 deltaRotation = b3DeltaQuatToRotation( relQ, targetQuat );
		b3Vec3 c = b3Neg( b3RotateVector( quatA, deltaRotation ) );

		b3Vec3 bias = b3MulSV( joint->angularSpring.biasRate, c );
		float massScale = joint->angularSpring.massScale;
		float impulseScale = joint->angularSpring.impulseScale;

		b3Vec3 cdot = b3Sub( wB, wA );

		float maxImpulse = context->h * joint->maxSpringTorque;
		b3Vec3 oldImpulse = joint->angularSpringImpulse;
		b3Vec3 impulse = b3MulSub( b3MulSV( -massScale, b3MulMV( joint->angularMass, b3Add( cdot, bias ) ) ), impulseScale, oldImpulse );
		joint->angularSpringImpulse = b3Add( oldImpulse, impulse );
		if ( b3LengthSquared( joint->angularSpringImpulse ) > maxImpulse * maxImpulse )
		{
			joint->angularSpringImpulse = b3MulSV( maxImpulse, b3Normalize( joint->angularSpringImpulse ) );
		}
		impulse = b3Sub( joint->angularSpringImpulse, oldImpulse );

		wA = b3Sub( wA, b3MulMV( iA, impulse ) );
		wB = b3Add( wB, b3MulMV( iB, impulse ) );
	}

	// angular velocity
	if ( joint->maxVelocityTorque > 0.0 )
	{
		b3Vec3 cdot = b3Sub( b3Sub( wB, wA ), joint->angularVelocity );
		b3Vec3 impulse = b3Neg( b3MulMV( joint->angularMass, cdot ) );

		float maxImpulse = context->h * joint->maxVelocityTorque;
		b3Vec3 oldImpulse = joint->angularVelocityImpulse;
		joint->angularVelocityImpulse = b3Add( oldImpulse, impulse );
		if ( b3LengthSquared( joint->angularVelocityImpulse ) > maxImpulse * maxImpulse )
		{
			joint->angularVelocityImpulse = b3MulSV( maxImpulse, b3Normalize( joint->angularVelocityImpulse ) );
		}
		impulse = b3Sub( joint->angularVelocityImpulse, oldImpulse );

		wA = b3Sub( wA, b3MulMV( iA, impulse ) );
		wB = b3Add( wB, b3MulMV( iB, impulse ) );
	}

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	// linear spring
	if ( joint->maxSpringForce > 0.0f && joint->linearHertz > 0.0f )
	{
		b3Vec3 dcA = stateA->deltaPosition;
		b3Vec3 dcB = stateB->deltaPosition;
		b3Vec3 c = b3Add( b3Add( b3Sub( dcB, dcA ), b3Sub( rB, rA ) ), joint->deltaCenter );

		b3Vec3 bias = b3MulSV( joint->linearSpring.biasRate, c );
		float massScale = joint->linearSpring.massScale;
		float impulseScale = joint->linearSpring.impulseScale;

		b3Vec3 cdot = b3Sub( b3Add( vB, b3Cross( wB, rB ) ), b3Add( vA, b3Cross( wA, rA ) ) );

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

		b3Vec3 oldImpulse = joint->linearSpringImpulse;
		b3Vec3 impulse = b3MulSub( b3MulSV( -massScale, b ), impulseScale, oldImpulse );
		float maxImpulse = context->h * joint->maxSpringForce;
		joint->linearSpringImpulse = b3Add( joint->linearSpringImpulse, impulse );

		if ( b3LengthSquared( joint->linearSpringImpulse ) > maxImpulse * maxImpulse )
		{
			joint->linearSpringImpulse = b3MulSV( maxImpulse, b3Normalize( joint->linearSpringImpulse ) );
		}

		impulse = b3Sub( joint->linearSpringImpulse, oldImpulse );

		vA = b3MulSub( vA, mA, impulse );
		wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, impulse ) ) );
		vB = b3MulAdd( vB, mB, impulse );
		wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, impulse ) ) );
	}

	// linear velocity
	if ( joint->maxVelocityForce > 0.0f )
	{
		b3Vec3 cdot = b3Sub( b3Add( vB, b3Cross( wB, rB ) ), b3Add( vA, b3Cross( wA, rA ) ) );
		cdot = b3Sub( cdot, joint->linearVelocity );
		//// K = [(1/m1 + 1/m2) * eye(2) - skew(r1) * invI1 * skew(r1) - skew(r2) * invI2 * skew(r2)]
		b3Matrix3 sA = b3Skew( rA );
		b3Matrix3 sB = b3Skew( rB );
		b3Matrix3 kA = b3MulMM( sA, b3MulMM( base->invIA, sA ) );
		b3Matrix3 kB = b3MulMM( sB, b3MulMM( base->invIB, sB ) );
		b3Matrix3 k = b3NegateMat3( b3AddMM( kA, kB ) );
		k.cx.x += mA + mB;
		k.cy.y += mA + mB;
		k.cz.z += mA + mB;

		b3Vec3 b = b3Solve3( k, cdot );
		b3Vec3 impulse = b3Neg( b );

		b3Vec3 oldImpulse = joint->linearVelocityImpulse;
		float maxImpulse = context->h * joint->maxVelocityForce;
		joint->linearVelocityImpulse = b3Add( joint->linearVelocityImpulse, impulse );

		if ( b3LengthSquared( joint->linearVelocityImpulse ) > maxImpulse * maxImpulse )
		{
			joint->linearVelocityImpulse = b3MulSV( maxImpulse, b3Normalize( joint->linearVelocityImpulse ) );
		}

		impulse = b3Sub( joint->linearVelocityImpulse, oldImpulse );

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
