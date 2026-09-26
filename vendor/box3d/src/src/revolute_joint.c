// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "body.h"
#include "joint.h"
#include "math_internal.h"
#include "physics_world.h"
#include "solver.h"
#include "solver_set.h"
#include "recording.h"

// needed for dll export
#include "box3d/box3d.h"

// Point-to-point linear constraint
// C = pB - pA
// Cdot = vB - vA
//      = vB + cross(wB, rB) - vA - cross(wA, rA)
// Cdot = J * v
// J = [-E -skew(rA) E skew(rB) ]
//
// K = J * invM * JT
//   = [(1/mA + 1/mB) * E - skew(rA) * invIA * skew(rA) - skew(rB) * invIB * skew(rB)]

// Perpendicularity constraint
// frameA = qA * localFrameA
// frameB = qB * localFrameB
// qRel = conj(frameA) * frameB
// C = [qRel.x; qRel.y]
// qRelDot = 0.5 * conj(frameA) * (wB - wA) * frameB
// Cdot = [qRelDot.x, qRelDot.y]
// Pulling out wB and wA
// sr = qRel.s
// vr = qRel.v
// Jx = 0.5 * rotate(frameA, sr * ex + cross(vr, ex))
// Jy = 0.5 * rotate(frameA, sr * ey + cross(vr, ey))

// Motor constraint
// Cdot = wB - wA
// J = [0 0 -E 0 0 E]
// K = invIA + invIB

void b3RevoluteJoint_EnableLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointEnableLimit, jointId, enableLimit );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	if ( enableLimit != base->revoluteJoint.enableLimit )
	{
		base->revoluteJoint.lowerImpulse = 0.0f;
		base->revoluteJoint.upperImpulse = 0.0f;
	}
	base->revoluteJoint.enableLimit = enableLimit;
}

bool b3RevoluteJoint_IsLimitEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.enableLimit;
}

float b3RevoluteJoint_GetLowerLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.lowerAngle;
}

float b3RevoluteJoint_GetUpperLimit( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.upperAngle;
}

void b3RevoluteJoint_SetLimits( b3JointId jointId, float lowerLimitRadians, float upperLimitRadians )
{
	B3_ASSERT( b3IsValidFloat( lowerLimitRadians ) && b3IsValidFloat( upperLimitRadians ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetLimits, jointId, lowerLimitRadians, upperLimitRadians );

	float lowerAngle = b3MinFloat( lowerLimitRadians, upperLimitRadians );
	float upperAngle = b3MaxFloat( lowerLimitRadians, upperLimitRadians );

	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.lowerAngle = b3ClampFloat( lowerAngle, -0.99f * B3_PI, 0.99f * B3_PI );
	base->revoluteJoint.upperAngle = b3ClampFloat( upperAngle, -0.99f * B3_PI, 0.99f * B3_PI );
}

float b3RevoluteJoint_GetAngle( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
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

void b3RevoluteJoint_EnableSpring( b3JointId jointId, bool enableSpring )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointEnableSpring, jointId, enableSpring );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	if ( enableSpring != base->revoluteJoint.enableSpring )
	{
		base->revoluteJoint.springImpulse = 0.0f;
	}
	base->revoluteJoint.enableSpring = enableSpring;
}

bool b3RevoluteJoint_IsSpringEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.enableSpring;
}

void b3RevoluteJoint_SetTargetAngle( b3JointId jointId, float targetRadians )
{
	B3_ASSERT( b3IsValidFloat( targetRadians ) && -B3_PI <= targetRadians && targetRadians <= B3_PI );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetTargetAngle, jointId, targetRadians );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.targetAngle = targetRadians;
}

float b3RevoluteJoint_GetTargetAngle( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.targetAngle;
}

void b3RevoluteJoint_SetSpringHertz( b3JointId jointId, float hertz )
{
	B3_ASSERT( b3IsValidFloat( hertz ) && hertz >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetSpringHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.hertz = hertz;
}

float b3RevoluteJoint_GetSpringHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.hertz;
}

void b3RevoluteJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio )
{
	B3_ASSERT( b3IsValidFloat( dampingRatio ) && dampingRatio >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetSpringDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.dampingRatio = dampingRatio;
}

float b3RevoluteJoint_GetSpringDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.dampingRatio;
}

void b3RevoluteJoint_EnableMotor( b3JointId jointId, bool enableMotor )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointEnableMotor, jointId, enableMotor );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	if ( enableMotor != base->revoluteJoint.enableMotor )
	{
		base->revoluteJoint.motorImpulse = 0.0f;
	}
	base->revoluteJoint.enableMotor = enableMotor;
}

bool b3RevoluteJoint_IsMotorEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.enableMotor;
}

void b3RevoluteJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed )
{
	B3_ASSERT( b3IsValidFloat( motorSpeed ) );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetMotorSpeed, jointId, motorSpeed );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.motorSpeed = motorSpeed;
}

float b3RevoluteJoint_GetMotorSpeed( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.motorSpeed;
}

void b3RevoluteJoint_SetMaxMotorTorque( b3JointId jointId, float maxForce )
{
	B3_ASSERT( b3IsValidFloat( maxForce ) && maxForce >= 0.0f );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, RevoluteJointSetMaxMotorTorque, jointId, maxForce );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	base->revoluteJoint.maxMotorTorque = maxForce;
}

float b3RevoluteJoint_GetMaxMotorTorque( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return base->revoluteJoint.maxMotorTorque;
}

float b3RevoluteJoint_GetMotorTorque( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_revoluteJoint );
	return world->inv_h * base->revoluteJoint.motorImpulse;
}

b3Vec3 b3GetRevoluteJointForce( b3World* world, b3JointSim* base )
{
	b3Vec3 force = b3MulSV( world->inv_h, base->revoluteJoint.linearImpulse );
	return force;
}

b3Vec3 b3GetRevoluteJointTorque( b3World* world, b3JointSim* base )
{
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3RevoluteJoint* joint = &base->revoluteJoint;
	b3Vec3 axis = b3RotateVector( base->localFrameA.q, b3Vec3_axisZ );
	axis = b3RotateVector( transformA.q, axis );

	b3Quat relQ = b3InvMulQuat( joint->frameA.q, joint->frameB.q );

	// These are needed for warm starting
	joint->perpAxisX = b3MulSV(
		0.5f, b3RotateVector( joint->frameA.q, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
	joint->perpAxisY = b3MulSV(
		0.5f, b3RotateVector( joint->frameA.q, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );

	float axialImpulse = joint->springImpulse + joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse;
	b3Vec3 angularImpulse =
		b3Add( b3MulSV( joint->perpImpulse.x, joint->perpAxisX ), b3MulSV( joint->perpImpulse.y, joint->perpAxisY ) );
	angularImpulse = b3MulAdd( angularImpulse, axialImpulse, joint->rotationAxisZ );

	// todo add pivot torque
	b3Vec3 impulse = b3MulAdd( angularImpulse,
							   joint->springImpulse + joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse, axis );
	b3Vec3 torque = b3MulSV( world->inv_h, impulse );
	return torque;
}

void b3PrepareRevoluteJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_revoluteJoint );

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

	b3RevoluteJoint* joint = &base->revoluteJoint;
	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	// Avoid round-off here as much as possible.
	// b3Vec3 pf = (xf.p - c) + rot(xf.q, f.p)
	// pf = xf.p - (xf.p + rot(xf.q, lc)) + rot(xf.q, f.p)
	// pf = rot(xf.q, f.p - lc)
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );

	{
		// Rotation axis is the z-axis of body A.
		b3Vec3 rotationAxisZ = b3RotateVector( joint->frameA.q, b3Vec3_axisZ );
		float k = b3Dot( rotationAxisZ, b3MulMV( invInertiaSum, rotationAxisZ ) );
		joint->axialMass = k > 0.0f ? 1.0f / k : 0.0f;
		joint->rotationAxisZ = rotationAxisZ;
	}

	b3Quat relQ = b3InvMulQuat( joint->frameA.q, joint->frameB.q );

	{
		// These are needed for warm starting
		joint->perpAxisX = b3MulSV(
			0.5f, b3RotateVector( joint->frameA.q, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
		joint->perpAxisY = b3MulSV(
			0.5f, b3RotateVector( joint->frameA.q, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );
	}

	joint->springSoftness = b3MakeSoft( joint->hertz, joint->dampingRatio, context->h );

	if ( context->enableWarmStarting == false )
	{
		joint->linearImpulse = b3Vec3_zero;
		joint->perpImpulse = (b3Vec2){ 0.0f, 0.0f };
		joint->motorImpulse = 0.0f;
		joint->springImpulse = 0.0f;
		joint->lowerImpulse = 0.0f;
		joint->upperImpulse = 0.0f;
	}
}

void b3WarmStartRevoluteJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_revoluteJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3RevoluteJoint* joint = &base->revoluteJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	float axialImpulse = joint->springImpulse + joint->motorImpulse + joint->lowerImpulse - joint->upperImpulse;
	b3Vec3 angularImpulse =
		b3Add( b3MulSV( joint->perpImpulse.x, joint->perpAxisX ), b3MulSV( joint->perpImpulse.y, joint->perpAxisY ) );
	angularImpulse = b3MulAdd( angularImpulse, axialImpulse, joint->rotationAxisZ );

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

void b3SolveRevoluteJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3RevoluteJoint* joint = &base->revoluteJoint;
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

	// Solve spring
	if ( joint->enableSpring && fixedRotation == false )
	{
		// Get the substep relative rotation
		float targetAngle = joint->targetAngle;
		float angle = b3GetTwistAngle( relQ );
		float c = angle - targetAngle;

		float bias = joint->springSoftness.biasRate * c;
		float massScale = joint->springSoftness.massScale;
		float impulseScale = joint->springSoftness.impulseScale;
		float cdot = b3Dot( b3Sub( wB, wA ), joint->rotationAxisZ );

		float deltaImpulse = -massScale * joint->axialMass * ( cdot + bias ) - impulseScale * joint->springImpulse;
		joint->springImpulse += deltaImpulse;

		wA = b3MulSub( wA, deltaImpulse, b3MulMV( iA, joint->rotationAxisZ ) );
		wB = b3MulAdd( wB, deltaImpulse, b3MulMV( iB, joint->rotationAxisZ ) );
	}

	if ( joint->enableMotor && fixedRotation == false )
	{
		float cdot = b3Dot( b3Sub( wB, wA ), joint->rotationAxisZ ) - joint->motorSpeed;

		float deltaImpulse = -joint->axialMass * cdot;
		float newImpulse = joint->motorImpulse + deltaImpulse;
		float maxImpulse = joint->maxMotorTorque * context->h;
		newImpulse = b3ClampFloat( newImpulse, -maxImpulse, maxImpulse );
		deltaImpulse = newImpulse - joint->motorImpulse;
		joint->motorImpulse = newImpulse;

		wA = b3MulSub( wA, deltaImpulse, b3MulMV( iA, joint->rotationAxisZ ) );
		wB = b3MulAdd( wB, deltaImpulse, b3MulMV( iB, joint->rotationAxisZ ) );
	}

	if ( joint->enableLimit && fixedRotation == false )
	{
		float angle = b3GetTwistAngle( relQ );

		// todo does an updated twist axis help?

		b3Vec3 axis = joint->rotationAxisZ;

		// Lower limit
		{
			float c = angle - joint->lowerAngle;
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

			float cdot = b3Dot( b3Sub( wB, wA ), axis );
			float oldImpulse = joint->lowerImpulse;
			float deltaImpulse = -massScale * joint->axialMass * ( cdot + bias ) - impulseScale * oldImpulse;
			joint->lowerImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
			deltaImpulse = joint->lowerImpulse - oldImpulse;

			wA = b3MulSub( wA, deltaImpulse, b3MulMV( iA, axis ) );
			wB = b3MulAdd( wB, deltaImpulse, b3MulMV( iB, axis ) );
		}

		// Upper limit
		{
			float c = joint->upperAngle - angle;
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
			float cdot = b3Dot( b3Sub( wA, wB ), axis );
			float oldImpulse = joint->upperImpulse;
			float deltaImpulse = -massScale * joint->axialMass * ( cdot + bias ) - impulseScale * oldImpulse;
			joint->upperImpulse = b3MaxFloat( oldImpulse + deltaImpulse, 0.0f );
			deltaImpulse = joint->upperImpulse - oldImpulse;

			// sign flipped on applied impulse
			wA = b3MulAdd( wA, deltaImpulse, b3MulMV( iA, axis ) );
			wB = b3MulSub( wB, deltaImpulse, b3MulMV( iB, axis ) );
		}
	}

	// Collinearity constraint
	if ( fixedRotation == false )
	{
		b3Vec2 bias = { 0.0f, 0.0f };
		float massScale = 1.0f;
		float impulseScale = 0.0f;

		if ( useBias )
		{
			b3Vec2 c = { relQ.v.x, relQ.v.y };
			bias = b3MulSV2( base->constraintSoftness.biasRate, c );
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		// Collinearity constraint as 2-by-2
		b3Vec3 perpAxisX =
			b3MulSV( 0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
		b3Vec3 perpAxisY =
			b3MulSV( 0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );
		joint->perpAxisX = perpAxisX;
		joint->perpAxisY = perpAxisY;

		b3Matrix3 invInertiaSum = b3AddMM( iA, iB );
		float kxx = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisX ) );
		float kyy = b3Dot( perpAxisY, b3MulMV( invInertiaSum, perpAxisY ) );
		float kxy = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisY ) );

		b3Matrix2 k = { { kxx, kxy }, { kxy, kyy } };

		b3Vec3 wRel = b3Sub( wB, wA );
		b3Vec2 cdot = { b3Dot( wRel, perpAxisX ), b3Dot( wRel, perpAxisY ) };
		b3Vec2 oldImpulse = joint->perpImpulse;
		b3Vec2 sol = b3Solve2( k, b3Add2( cdot, bias ) );
		b3Vec2 deltaImpulse = b3Sub2( b3MulSV2( -massScale, sol ), b3MulSV2( impulseScale, oldImpulse ) );
		joint->perpImpulse = b3Add2( joint->perpImpulse, deltaImpulse );

		b3Vec3 angularImpulse = b3Add( b3MulSV( deltaImpulse.x, perpAxisX ), b3MulSV( deltaImpulse.y, perpAxisY ) );
		wA = b3Sub( wA, b3MulMV( iA, angularImpulse ) );
		wB = b3Add( wB, b3MulMV( iB, angularImpulse ) );
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

			b3Vec3 separation = b3Add( b3Add( b3Sub( dcB, dcA ), b3Sub( rB, rA ) ), joint->deltaCenter );

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

		b3Vec3 impulse = b3Sub( b3MulSV( -massScale, b ), b3MulSV( impulseScale, joint->linearImpulse ) );
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

void b3DrawRevoluteJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
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

	b3RevoluteJoint* joint = &base->revoluteJoint;
	enum { kSliceCount = 16 };

	// Twist limit
	if ( joint->enableLimit )
	{
		b3Quat quatA = frameA.q;
		b3Quat quatB = frameB.q;

		if ( b3DotQuat( quatA, quatB ) < 0.0f )
		{
			// this keeps the twist angle in the range [-pi, pi]
			quatB = b3NegateQuat( quatB );
		}

		b3Quat relQ = b3InvMulQuat( quatA, quatB );

		const float wedgeRadius = 0.2f * scale;
		for ( int index = 0; index < kSliceCount; ++index )
		{
			float t1 = (float)( index + 0 ) / kSliceCount;
			float alpha1 = ( 1.0f - t1 ) * joint->lowerAngle + t1 * joint->upperAngle;
			float t2 = (float)( index + 1 ) / kSliceCount;
			float alpha2 = ( 1.0f - t2 ) * joint->lowerAngle + t2 * joint->upperAngle;

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
}
