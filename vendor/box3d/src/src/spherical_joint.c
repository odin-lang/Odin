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

void b3SphericalJoint_EnableConeLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointEnableConeLimit, jointId, enableLimit );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	if ( enableLimit != base->sphericalJoint.enableConeLimit )
	{
		base->sphericalJoint.swingImpulse = 0.0f;
	}
	base->sphericalJoint.enableConeLimit = enableLimit;
}

bool b3SphericalJoint_IsConeLimitEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.enableConeLimit;
}

float b3SphericalJoint_GetConeLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.coneAngle;
}

void b3SphericalJoint_SetConeLimit( b3JointId jointId, float angleRadians )
{
	B3_ASSERT( b3IsValidFloat( angleRadians ) && 0 <= angleRadians && angleRadians <= 0.5f * B3_PI );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetConeLimit, jointId, angleRadians );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.coneAngle = angleRadians;
}

float b3SphericalJoint_GetConeAngle( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform transformB = b3GetBodyTransform( world, base->bodyIdB );

	b3Quat quatA = b3MulQuat( transformA.q, base->localFrameA.q );
	b3Quat quatB = b3MulQuat( transformB.q, base->localFrameB.q );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the swing angle in the range [0, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	return b3GetSwingAngle( relQ );
}

void b3SphericalJoint_EnableTwistLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointEnableTwistLimit, jointId, enableLimit );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	if ( enableLimit != base->sphericalJoint.enableTwistLimit )
	{
		base->sphericalJoint.lowerTwistImpulse = 0.0f;
		base->sphericalJoint.upperTwistImpulse = 0.0f;
	}
	base->sphericalJoint.enableTwistLimit = enableLimit;
}

bool b3SphericalJoint_IsTwistLimitEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.enableTwistLimit;
}

float b3SphericalJoint_GetLowerTwistLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.lowerTwistAngle;
}

float b3SphericalJoint_GetUpperTwistLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.upperTwistAngle;
}

void b3SphericalJoint_SetTwistLimits( b3JointId jointId, float lowerLimitRadians, float upperLimitRadians )
{
	B3_ASSERT( b3IsValidFloat( lowerLimitRadians ) && b3IsValidFloat( upperLimitRadians ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetTwistLimits, jointId, lowerLimitRadians, upperLimitRadians );

	float lowerAngle = b3MinFloat( lowerLimitRadians, upperLimitRadians );
	float upperAngle = b3MaxFloat( lowerLimitRadians, upperLimitRadians );

	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.lowerTwistAngle = b3ClampFloat( lowerAngle, -0.99f * B3_PI, 0.99f * B3_PI );
	base->sphericalJoint.upperTwistAngle = b3ClampFloat( upperAngle, -0.99f * B3_PI, 0.99f * B3_PI );
}

float b3SphericalJoint_GetTwistAngle( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform transformB = b3GetBodyTransform( world, base->bodyIdB );

	b3Quat quatA = b3MulQuat( transformA.q, base->localFrameA.q );
	b3Quat quatB = b3MulQuat( transformB.q, base->localFrameB.q );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the twist angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	return b3GetTwistAngle( relQ );
}

void b3SphericalJoint_EnableSpring( b3JointId jointId, bool enableSpring )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointEnableSpring, jointId, enableSpring );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	if ( enableSpring != base->sphericalJoint.enableSpring )
	{
		base->sphericalJoint.springImpulse = b3Vec3_zero;
	}
	base->sphericalJoint.enableSpring = enableSpring;
}

bool b3SphericalJoint_IsSpringEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.enableSpring;
}

void b3SphericalJoint_SetTargetRotation( b3JointId jointId, b3Quat targetRotation )
{
	B3_ASSERT( b3IsValidQuat( targetRotation ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetTargetRotation, jointId, targetRotation );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.targetRotation = targetRotation;
}

b3Quat b3SphericalJoint_GetTargetRotation( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.targetRotation;
}

void b3SphericalJoint_SetSpringHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetSpringHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.hertz = hertz;
}

float b3SphericalJoint_GetSpringHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.hertz;
}

void b3SphericalJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetSpringDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.dampingRatio = dampingRatio;
}

float b3SphericalJoint_GetSpringDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.dampingRatio;
}

void b3SphericalJoint_EnableMotor( b3JointId jointId, bool enableMotor )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointEnableMotor, jointId, enableMotor );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	if ( enableMotor != base->sphericalJoint.enableMotor )
	{
		base->sphericalJoint.motorImpulse = b3Vec3_zero;
	}
	base->sphericalJoint.enableMotor = enableMotor;
}

bool b3SphericalJoint_IsMotorEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.enableMotor;
}

void b3SphericalJoint_SetMotorVelocity( b3JointId jointId, b3Vec3 motorVelocity )
{
	B3_ASSERT( b3IsValidVec3( motorVelocity ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetMotorVelocity, jointId, motorVelocity );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.motorVelocity = motorVelocity;
}

b3Vec3 b3SphericalJoint_GetMotorVelocity( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.motorVelocity;
}

void b3SphericalJoint_SetMaxMotorTorque( b3JointId jointId, float maxForce )
{
	B3_ASSERT( b3IsValidFloat( maxForce ) && maxForce >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, SphericalJointSetMaxMotorTorque, jointId, maxForce );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	base->sphericalJoint.maxMotorTorque = maxForce;
}

float b3SphericalJoint_GetMaxMotorTorque( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return base->sphericalJoint.maxMotorTorque;
}

b3Vec3 b3SphericalJoint_GetMotorTorque( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_sphericalJoint );
	return b3MulSV( world->inv_h, base->sphericalJoint.motorImpulse );
}

b3Vec3 b3GetSphericalJointForce( b3World* world, b3JointSim* base )
{
	b3Vec3 force = b3MulSV( world->inv_h, base->sphericalJoint.linearImpulse );
	return force;
}

b3Vec3 b3GetSphericalJointTorque( b3World* world, b3JointSim* base )
{
	b3WorldTransform xfA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform xfB = b3GetBodyTransform( world, base->bodyIdB );
	b3Quat qA = b3MulQuat( xfA.q, base->localFrameA.q );
	b3Quat qB = b3MulQuat( xfB.q, base->localFrameB.q );

	// Cone axis is the z-axis of body A.
	b3Vec3 coneAxis = b3RotateVector( qA, b3Vec3_axisZ );
	b3Vec3 twistAxis = b3RotateVector( qB, b3Vec3_axisZ );
	b3Vec3 swingAxis = b3Normalize( b3Cross( coneAxis, twistAxis ) );

	b3SphericalJoint* joint = &base->sphericalJoint;
	b3Vec3 impulse = b3Add( joint->springImpulse, joint->motorImpulse );
	impulse = b3MulAdd( impulse, joint->lowerTwistImpulse - joint->upperTwistImpulse, twistAxis );
	impulse = b3MulAdd( impulse, joint->swingImpulse, swingAxis );
	b3Vec3 torque = b3MulSV( world->inv_h, impulse );
	return torque;
}

// Point-to-point constraint
// C = p2 - p1
// Cdot = v2 - v1
//      = v2 + cross(w2, r2) - v1 - cross(w1, r1)
// J = [-I r1_skew I -r2_skew ]
// K = J * invM * transpose(J)
// transpose(skew(r)) = -skew(r)
// K = diag(1/m1 + 1/m2) - r1_skew * invI1 * r1_skew - r2_skew * invI2 * r2_skew

// r_skew = R * skew(r_local) * RT
// invI = R * invI_local * RT
// r_skew * invI * r_skew = R * skew(r_local) * RT * R * invI_local * RT * R * r_skew * RT
//                        = R * ( skew(r_local) * invI_local * skew(r_local) ) * RT

void b3PrepareSphericalJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_sphericalJoint );

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

	b3SphericalJoint* joint = &base->sphericalJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );

	// Cone axis is the z-axis of body A.
	b3Vec3 coneAxis = b3RotateVector( joint->frameA.q, b3Vec3_axisZ );

	// Twist axis is the z-axis of body B.
	b3Vec3 twistAxis = b3RotateVector( joint->frameB.q, b3Vec3_axisZ );

	if ( joint->enableConeLimit )
	{
		// Swing axis may be zero
		b3Vec3 swingAxis = b3Normalize( b3Cross( coneAxis, twistAxis ) );
		float k = b3Dot( swingAxis, b3MulMV( invInertiaSum, swingAxis ) );
		joint->swingMass = k > 0.0f ? 1.0f / k : 0.0f;
		joint->swingAxis = swingAxis;
	}

	if ( joint->enableTwistLimit )
	{
		b3Quat relQ = b3InvMulQuat( joint->frameA.q, joint->frameB.q );
		float tanThetaOver2 = sqrtf( ( relQ.v.x * relQ.v.x + relQ.v.y * relQ.v.y ) / ( relQ.v.z * relQ.v.z + relQ.s * relQ.s ) );

		// todo verify this Jacobian using a finite difference, unit test?
		b3Vec3 swingAxis = b3Normalize( b3Cross( coneAxis, twistAxis ) );
		b3Vec3 perpAxis = b3Cross( swingAxis, coneAxis );
		b3Vec3 twistJacobian = b3MulAdd( coneAxis, tanThetaOver2, perpAxis );
		float k = b3Dot( twistJacobian, b3MulMV( invInertiaSum, twistJacobian ) );
		joint->twistMass = k > 0.0f ? 1.0f / k : 0.0f;
		joint->twistJacobian = twistJacobian;
	}

	if ( base->fixedRotation == false )
	{
		joint->rotationMass = b3InvertMatrix( invInertiaSum );
	}
	else
	{
		joint->rotationMass = b3Mat3_zero;
	}

	joint->springSoftness = b3MakeSoft( joint->hertz, joint->dampingRatio, context->h );

	if ( context->enableWarmStarting == false )
	{
		joint->linearImpulse = b3Vec3_zero;
		joint->motorImpulse = b3Vec3_zero;
		joint->springImpulse = b3Vec3_zero;
		joint->swingImpulse = 0.0f;
		joint->lowerTwistImpulse = 0.0f;
		joint->upperTwistImpulse = 0.0f;
	}
}

void b3WarmStartSphericalJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_sphericalJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3SphericalJoint* joint = &base->sphericalJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	b3Vec3 angularImpulse = b3Add( joint->springImpulse, joint->motorImpulse );
	angularImpulse = b3MulSub( angularImpulse, joint->swingImpulse, joint->swingAxis );
	angularImpulse = b3MulAdd( angularImpulse, joint->lowerTwistImpulse - joint->upperTwistImpulse, joint->twistJacobian );

	vA = b3MulSub( vA, mA, joint->linearImpulse );
	wA = b3Sub( wA, b3MulMV( iA, b3Add( b3Cross( rA, joint->linearImpulse ), angularImpulse ) ) );

	vB = b3MulAdd( vB, mB, joint->linearImpulse );
	wB = b3Add( wB, b3MulMV( iB, b3Add( b3Cross( rB, joint->linearImpulse ), angularImpulse ) ) );

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

void b3SolveSphericalJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3SphericalJoint* joint = &base->sphericalJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	bool fixedRotation = base->fixedRotation;
	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );

	b3Quat relQ = b3InvMulQuat( quatA, quatB );

	// Solve spring
	if ( joint->enableSpring && fixedRotation == false )
	{
		// Rotation constraint error
		b3Vec3 deltaRotation = b3DeltaQuatToRotation( relQ, joint->targetRotation );
		b3Vec3 c = b3Neg( b3RotateVector( quatA, deltaRotation ) );

		b3Vec3 bias = b3MulSV( joint->springSoftness.biasRate, c );
		float massScale = joint->springSoftness.massScale;
		float impulseScale = joint->springSoftness.impulseScale;
		b3Vec3 cdot = b3Sub( wB, wA );

		b3Vec3 impulse = b3MulSub( b3MulSV( -massScale, b3MulMV( joint->rotationMass, b3Add( cdot, bias ) ) ),
								   impulseScale, joint->springImpulse );
		joint->springImpulse = b3Add( joint->springImpulse, impulse );

		wA = b3Sub( wA, b3MulMV( iA, impulse ) );
		wB = b3Add( wB, b3MulMV( iB, impulse ) );
	}

	if ( joint->enableMotor && fixedRotation == false )
	{
		b3Vec3 cdot = b3Sub( wB, wA );

		b3Vec3 lambda = b3Neg( b3MulMV( joint->rotationMass, b3Sub( cdot, joint->motorVelocity ) ) );
		b3Vec3 newImpulse = b3Add( joint->motorImpulse, lambda );
		float length = b3Length( newImpulse );
		float maxImpulse = joint->maxMotorTorque * context->h;
		if ( length > maxImpulse )
		{
			newImpulse = b3MulSV( maxImpulse / length, newImpulse );
		}

		lambda = b3Sub( newImpulse, joint->motorImpulse );
		joint->motorImpulse = newImpulse;

		wA = b3Sub( wA, b3MulMV( iA, lambda ) );
		wB = b3Add( wB, b3MulMV( iB, lambda ) );
	}

	if ( joint->enableTwistLimit && fixedRotation == false )
	{
		float twistAngle = b3GetTwistAngle( relQ );

		// todo does an updated twist axis help?

		b3Vec3 twistJacobian = joint->twistJacobian;

		// Lower limit
		{
			float c = twistAngle - joint->lowerTwistAngle;
			float bias = 0.0f;
			float massScale = 1.0f;
			float impulseScale = 0.0f;
			if ( c > 0.0f )
			{
				// speculation
				bias = c * context->inv_h;
			}
			else if ( useBias )
			{
				bias = base->constraintSoftness.biasRate * c;
				massScale = base->constraintSoftness.massScale;
				impulseScale = base->constraintSoftness.impulseScale;
			}

			float cdot = b3Dot( b3Sub( wB, wA ), twistJacobian );
			float oldImpulse = joint->lowerTwistImpulse;
			float deltaImpulse = -massScale * joint->twistMass * ( cdot + bias ) - impulseScale * oldImpulse;
			joint->lowerTwistImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
			deltaImpulse = joint->lowerTwistImpulse - oldImpulse;

			wA = b3MulSub( wA, deltaImpulse, b3MulMV( iA, twistJacobian ) );
			wB = b3MulAdd( wB, deltaImpulse, b3MulMV( iB, twistJacobian ) );
		}

		// Upper limit
		{
			float c = joint->upperTwistAngle - twistAngle;
			float bias = 0.0f;
			float massScale = 1.0f;
			float impulseScale = 0.0f;
			if ( c > 0.0f )
			{
				// speculation
				bias = c * context->inv_h;
			}
			else if ( useBias )
			{
				bias = base->constraintSoftness.biasRate * c;
				massScale = base->constraintSoftness.massScale;
				impulseScale = base->constraintSoftness.impulseScale;
			}

			// sign flipped on Cdot
			float cdot = b3Dot( b3Sub( wA, wB ), twistJacobian );
			float oldImpulse = joint->upperTwistImpulse;
			float deltaImpulse = -massScale * joint->twistMass * ( cdot + bias ) - impulseScale * oldImpulse;
			joint->upperTwistImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
			deltaImpulse = joint->upperTwistImpulse - oldImpulse;

			// sign flipped on applied impulse
			wA = b3MulAdd( wA, deltaImpulse, b3MulMV( iA, twistJacobian ) );
			wB = b3MulSub( wB, deltaImpulse, b3MulMV( iB, twistJacobian ) );
		}
	}

	if ( joint->enableConeLimit && fixedRotation == false )
	{
		float swingAngle = b3GetSwingAngle( relQ );

		// todo does an updated swing axis help?
		// b3Vec3 axisA = b3RotateVector( quatA, b3Vec3_axisZ );
		// b3Vec3 axisB = b3RotateVector( quatB, b3Vec3_axisZ );
		// b3Vec3 swingAxis = b3Normalize( b3Cross( axisA, axisB ) );
		// joint->swingAxis = swingAxis;

		b3Vec3 swingAxis = joint->swingAxis;

		float c = joint->coneAngle - swingAngle;
		float bias = 0.0f;
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( c > 0.0f )
		{
			// speculation
			bias = c * context->inv_h;
		}
		else if ( useBias )
		{
			bias = base->constraintSoftness.biasRate * c;
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		// sign flipped on Cdot
		float cdot = b3Dot( b3Sub( wA, wB ), swingAxis );
		float oldImpulse = joint->swingImpulse;
		float deltaImpulse = -massScale * joint->swingMass * ( cdot + bias ) - impulseScale * oldImpulse;
		joint->swingImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
		deltaImpulse = joint->swingImpulse - oldImpulse;

		// sign flipped on applied impulse
		wA = b3MulAdd( wA, deltaImpulse, b3MulMV( iA, swingAxis ) );
		wB = b3MulSub( wB, deltaImpulse, b3MulMV( iB, swingAxis ) );
	}

	// Solve point-to-point constraint
	{
		b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
		b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

		b3Vec3 cdot = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, rA ) );

		b3Vec3 bias = b3Vec3_zero;
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias )
		{
			b3Vec3 dcA = stateA->deltaPosition;
			b3Vec3 dcB = stateB->deltaPosition;

			b3Vec3 separation = b3Add( b3Sub( dcB, dcA ), b3Sub( rB, rA ) );
			separation = b3Add( separation, joint->deltaCenter );

			bias = b3MulSV( base->constraintSoftness.biasRate, separation );
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
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

void b3DrawSphericalJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
{
	b3WorldTransform frameA = b3MulWorldTransforms( transformA, base->localFrameA );

	float length1 = 0.1f * scale;
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( length1, b3RotateVector( frameA.q, b3Vec3_axisX ) ) ), b3_colorRed,
						  draw->context );
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( length1, b3RotateVector( frameA.q, b3Vec3_axisY ) ) ), b3_colorGreen,
						  draw->context );
	draw->DrawSegmentFcn( frameA.p, b3OffsetPos( frameA.p, b3MulSV( length1, b3RotateVector( frameA.q, b3Vec3_axisZ ) ) ), b3_colorBlue,
						  draw->context );

	b3WorldTransform frameB = b3MulWorldTransforms( transformB, base->localFrameB );

	float length2 = 0.2f * scale;
	draw->DrawSegmentFcn( frameB.p, b3OffsetPos( frameB.p, b3MulSV( length2, b3RotateVector( frameB.q, b3Vec3_axisZ ) ) ), b3_colorOrange,
						  draw->context );

	b3SphericalJoint* joint = &base->sphericalJoint;
	enum { kSliceCount = 16 };

	// Twist limit
	if ( joint->enableTwistLimit )
	{
		b3Quat quatA = frameA.q;
		b3Quat quatB = frameB.q;

		if ( b3DotQuat( quatA, quatB ) < 0.0f )
		{
			// this keeps the twist angle in the range [-pi, pi]
			quatB = b3NegateQuat( quatB );
		}

		b3Quat relQ = b3InvMulQuat( quatA, quatB );

		const float wedgeRadius = 0.1f * scale;
		for ( int index = 0; index < kSliceCount; ++index )
		{
			float t1 = (float)( index + 0 ) / kSliceCount;
			float alpha1 = ( 1.0f - t1 ) * joint->lowerTwistAngle + t1 * joint->upperTwistAngle;
			float t2 = (float)( index + 1 ) / kSliceCount;
			float alpha2 = ( 1.0f - t2 ) * joint->lowerTwistAngle + t2 * joint->upperTwistAngle;

			b3Vec3 vertex1 = { wedgeRadius * b3Cos( alpha1 ), wedgeRadius * b3Sin( alpha1 ), 0.0f };
			b3Vec3 vertex2 = { wedgeRadius * b3Cos( alpha2 ), wedgeRadius * b3Sin( alpha2 ), 0.0f };

			if ( index == 0 )
			{
				draw->DrawSegmentFcn( frameA.p, b3TransformWorldPoint( frameA, vertex1 ), b3_colorCyan, draw->context );
			}

			if ( index == kSliceCount - 1 )
			{
				draw->DrawSegmentFcn( b3TransformWorldPoint( frameA, vertex2 ), frameA.p, b3_colorCyan, draw->context );
			}
			draw->DrawSegmentFcn( b3TransformWorldPoint( frameA, vertex1 ), b3TransformWorldPoint( frameA, vertex2 ), b3_colorCyan,
								  draw->context );
		}

		float twistAngle = b3GetTwistAngle( relQ );
		b3Vec3 p2 = { wedgeRadius * b3Cos( twistAngle ), wedgeRadius * b3Sin( twistAngle ), 0.0f };
		draw->DrawSegmentFcn( frameA.p, b3TransformWorldPoint( frameA, p2 ), b3_colorYellow, draw->context );
	}

	// Swing limit
	if ( joint->enableConeLimit )
	{
		const float radius = 0.1f * scale;
		float coneRadius = radius * b3Sin( joint->coneAngle );
		float coneHeight = radius * b3Cos( joint->coneAngle );

		for ( int index = 0; index < kSliceCount; ++index )
		{
			float phi1 = 2.0f * ( index + 0 ) / kSliceCount * B3_PI;
			float phi2 = 2.0f * ( index + 1 ) / kSliceCount * B3_PI;

			b3Vec3 vertex1 = { coneRadius * b3Cos( phi1 ), coneRadius * b3Sin( phi1 ), coneHeight };
			b3Vec3 vertex2 = { coneRadius * b3Cos( phi2 ), coneRadius * b3Sin( phi2 ), coneHeight };

			draw->DrawSegmentFcn( frameA.p, b3TransformWorldPoint( frameA, vertex1 ), b3_colorCyan, draw->context );
			draw->DrawSegmentFcn( b3TransformWorldPoint( frameA, vertex1 ), b3TransformWorldPoint( frameA, vertex2 ), b3_colorCyan,
								  draw->context );
		}
	}
}
