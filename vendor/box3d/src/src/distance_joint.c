// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "body.h"
#include "core.h"
#include "joint.h"
#include "physics_world.h"
#include "recording.h"
#include "solver.h"
#include "solver_set.h"

// needed for dll export
#include "box3d/box3d.h"

void b3DistanceJoint_SetLength( b3JointId jointId, float length )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetLength, jointId, length );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;

	joint->length = b3ClampFloat( length, B3_LINEAR_SLOP, B3_HUGE );
	joint->impulse = 0.0f;
	joint->lowerImpulse = 0.0f;
	joint->upperImpulse = 0.0f;
}

float b3DistanceJoint_GetLength( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	return joint->length;
}

void b3DistanceJoint_EnableLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointEnableLimit, jointId, enableLimit );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	joint->enableLimit = enableLimit;
}

bool b3DistanceJoint_IsLimitEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return joint->distanceJoint.enableLimit;
}

void b3DistanceJoint_SetLengthRange( b3JointId jointId, float minLength, float maxLength )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetLengthRange, jointId, minLength, maxLength );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;

	minLength = b3ClampFloat( minLength, B3_LINEAR_SLOP, B3_HUGE );
	maxLength = b3ClampFloat( maxLength, B3_LINEAR_SLOP, B3_HUGE );
	joint->minLength = b3MinFloat( minLength, maxLength );
	joint->maxLength = b3MaxFloat( minLength, maxLength );
	joint->impulse = 0.0f;
	joint->lowerImpulse = 0.0f;
	joint->upperImpulse = 0.0f;
}

float b3DistanceJoint_GetMinLength( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	return joint->minLength;
}

float b3DistanceJoint_GetMaxLength( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	return joint->maxLength;
}

float b3DistanceJoint_GetCurrentLength( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );

	b3World* world = b3GetUnlockedWorld( jointId.world0 );
	if ( world == NULL )
	{
		return 0.0f;
	}

	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform transformB = b3GetBodyTransform( world, base->bodyIdB );

	b3Pos pA = b3TransformWorldPoint( transformA, base->localFrameA.p );
	b3Pos pB = b3TransformWorldPoint( transformB, base->localFrameB.p );
	b3Vec3 d = b3SubPos( pB, pA );
	float length = b3Length( d );
	return length;
}

void b3DistanceJoint_EnableSpring( b3JointId jointId, bool enableSpring )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointEnableSpring, jointId, enableSpring );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	base->distanceJoint.enableSpring = enableSpring;
}

bool b3DistanceJoint_IsSpringEnabled( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return base->distanceJoint.enableSpring;
}


void b3DistanceJoint_SetSpringForceRange( b3JointId jointId, float lowerForce, float upperForce )
{
	B3_ASSERT( lowerForce <= upperForce );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetSpringForceRange, jointId, lowerForce, upperForce );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	base->distanceJoint.lowerSpringForce = lowerForce;
	base->distanceJoint.upperSpringForce = upperForce;
}

void b3DistanceJoint_GetSpringForceRange( b3JointId jointId, float* lowerForce, float* upperForce )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	*lowerForce = base->distanceJoint.lowerSpringForce;
	*upperForce = base->distanceJoint.upperSpringForce;
}

void b3DistanceJoint_SetSpringHertz( b3JointId jointId, float hertz )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetSpringHertz, jointId, hertz );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	base->distanceJoint.hertz = hertz;
}

void b3DistanceJoint_SetSpringDampingRatio( b3JointId jointId, float dampingRatio )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetSpringDampingRatio, jointId, dampingRatio );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	base->distanceJoint.dampingRatio = dampingRatio;
}

float b3DistanceJoint_GetSpringHertz( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	return joint->hertz;
}

float b3DistanceJoint_GetSpringDampingRatio( b3JointId jointId )
{
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	b3DistanceJoint* joint = &base->distanceJoint;
	return joint->dampingRatio;
}

void b3DistanceJoint_EnableMotor( b3JointId jointId, bool enableMotor )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointEnableMotor, jointId, enableMotor );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	if ( enableMotor != joint->distanceJoint.enableMotor )
	{
		joint->distanceJoint.enableMotor = enableMotor;
		joint->distanceJoint.motorImpulse = 0.0f;
	}
}

bool b3DistanceJoint_IsMotorEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return joint->distanceJoint.enableMotor;
}

void b3DistanceJoint_SetMotorSpeed( b3JointId jointId, float motorSpeed )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetMotorSpeed, jointId, motorSpeed );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	joint->distanceJoint.motorSpeed = motorSpeed;
}

float b3DistanceJoint_GetMotorSpeed( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return joint->distanceJoint.motorSpeed;
}

float b3DistanceJoint_GetMotorForce( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return world->inv_h * base->distanceJoint.motorImpulse;
}

void b3DistanceJoint_SetMaxMotorForce( b3JointId jointId, float force )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, DistanceJointSetMaxMotorForce, jointId, force );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	joint->distanceJoint.maxMotorForce = force;
}

float b3DistanceJoint_GetMaxMotorForce( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_distanceJoint );
	return joint->distanceJoint.maxMotorForce;
}

b3Vec3 b3GetDistanceJointForce( b3World* world, b3JointSim* base )
{
	b3DistanceJoint* joint = &base->distanceJoint;

	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WorldTransform transformB = b3GetBodyTransform( world, base->bodyIdB );

	b3Pos pA = b3TransformWorldPoint( transformA, base->localFrameA.p );
	b3Pos pB = b3TransformWorldPoint( transformB, base->localFrameB.p );
	b3Vec3 d = b3SubPos( pB, pA );
	b3Vec3 axis = b3Normalize( d );
	float force = ( joint->impulse + joint->lowerImpulse - joint->upperImpulse + joint->motorImpulse ) * world->inv_h;
	return b3MulSV( force, axis );
}

// 1-D constrained system
// m (v2 - v1) = lambda
// v2 + (beta/h) * x1 + gamma * lambda = 0, gamma has units of inverse mass.
// x2 = x1 + h * v2

// 1-D mass-damper-spring system
// m (v2 - v1) + h * d * v2 + h * k *

// C = norm(p2 - p1) - L
// u = (p2 - p1) / norm(p2 - p1)
// Cdot = dot(u, v2 + cross(w2, r2) - v1 - cross(w1, r1))
// J = [-u -cross(r1, u) u cross(r2, u)]
// K = J * invM * JT
//   = invMass1 + invI1 * cross(r1, u)^2 + invMass2 + invI2 * cross(r2, u)^2

void b3PrepareDistanceJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_distanceJoint );

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

	float mA = bodySimA->invMass;
	b3Matrix3 iA = bodySimA->invInertiaWorld;
	float mB = bodySimB->invMass;
	b3Matrix3 iB = bodySimB->invInertiaWorld;

	base->invMassA = mA;
	base->invMassB = mB;
	base->invIA = iA;
	base->invIB = iB;

	b3DistanceJoint* joint = &base->distanceJoint;

	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// initial anchors in world space
	joint->anchorA = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->anchorB = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );
	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );

	b3Vec3 rA = joint->anchorA;
	b3Vec3 rB = joint->anchorB;
	b3Vec3 separation = b3Add( b3Sub( rB, rA ), joint->deltaCenter );
	b3Vec3 axis = b3Normalize( separation );

	// compute effective mass
	b3Vec3 crA = b3Cross( rA, axis );
	b3Vec3 crB = b3Cross( rB, axis );
	float k = mA + mB + b3Dot( crA, b3MulMV( iA, crA ) ) + b3Dot( crB, b3MulMV( iB, crB ) );
	joint->axialMass = k > 0.0f ? 1.0f / k : 0.0f;

	joint->distanceSoftness = b3MakeSoft( joint->hertz, joint->dampingRatio, context->h );

	if ( context->enableWarmStarting == false )
	{
		joint->impulse = 0.0f;
		joint->lowerImpulse = 0.0f;
		joint->upperImpulse = 0.0f;
		joint->motorImpulse = 0.0f;
	}
}

void b3WarmStartDistanceJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_distanceJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3DistanceJoint* joint = &base->distanceJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->anchorA );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->anchorB );

	b3Vec3 ds = b3Add( b3Sub( stateB->deltaPosition, stateA->deltaPosition ), b3Sub( rB, rA ) );
	b3Vec3 separation = b3Add( joint->deltaCenter, ds );
	b3Vec3 axis = b3Normalize( separation );

	float axialImpulse = joint->impulse + joint->lowerImpulse - joint->upperImpulse + joint->motorImpulse;
	b3Vec3 P = b3MulSV( axialImpulse, axis );

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->linearVelocity = b3MulSub( stateA->linearVelocity, mA, P );
		stateA->angularVelocity = b3Sub( stateA->angularVelocity, b3MulMV( iA, b3Cross( rA, P ) ) );
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->linearVelocity = b3MulAdd( stateB->linearVelocity, mB, P );
		stateB->angularVelocity = b3Add( stateB->angularVelocity, b3MulMV( iB, b3Cross( rB, P ) ) );
	}
}

void b3SolveDistanceJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	B3_ASSERT( base->type == b3_distanceJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3DistanceJoint* joint = &base->distanceJoint;
	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	// current anchors
	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->anchorA );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->anchorB );

	// current separation
	b3Vec3 ds = b3Add( b3Sub( stateB->deltaPosition, stateA->deltaPosition ), b3Sub( rB, rA ) );
	b3Vec3 separation = b3Add( joint->deltaCenter, ds );

	float length = b3Length( separation );
	b3Vec3 axis = b3Normalize( separation );

	// joint is soft if
	// - spring is enabled
	// - and (joint limit is disabled or limits are not equal)
	if ( joint->enableSpring && ( joint->minLength < joint->maxLength || joint->enableLimit == false ) )
	{
		// spring
		if ( joint->hertz > 0.0f )
		{
			// Cdot = dot(u, v + cross(w, r))
			b3Vec3 vr = b3Add( b3Sub( vB, vA ), b3Sub( b3Cross( wB, rB ), b3Cross( wA, rA ) ) );
			float Cdot = b3Dot( axis, vr );
			float C = length - joint->length;
			float bias = joint->distanceSoftness.biasRate * C;

			float m = joint->distanceSoftness.massScale * joint->axialMass;
			float oldImpulse = joint->impulse;
			float impulse = -m * ( Cdot + bias ) - joint->distanceSoftness.impulseScale * oldImpulse;
			float h = context->h;
			joint->impulse = b3ClampFloat( joint->impulse + impulse, joint->lowerSpringForce * h, joint->upperSpringForce * h );
			impulse = joint->impulse - oldImpulse;

			b3Vec3 P = b3MulSV( impulse, axis );
			vA = b3MulSub( vA, mA, P );
			wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, P ) ) );
			vB = b3MulAdd( vB, mB, P );
			wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, P ) ) );
		}

		if ( joint->enableLimit )
		{
			// lower limit
			{
				b3Vec3 vr = b3Add( b3Sub( vB, vA ), b3Sub( b3Cross( wB, rB ), b3Cross( wA, rA ) ) );
				float Cdot = b3Dot( axis, vr );

				float C = length - joint->minLength;

				float bias = 0.0f;
				float massCoeff = 1.0f;
				float impulseCoeff = 0.0f;
				if ( C > 0.0f )
				{
					// speculative
					bias = C * context->inv_h;
				}
				else if ( useBias )
				{
					bias = base->constraintSoftness.biasRate * C;
					massCoeff = base->constraintSoftness.massScale;
					impulseCoeff = base->constraintSoftness.impulseScale;
				}

				float impulse = -massCoeff * joint->axialMass * ( Cdot + bias ) - impulseCoeff * joint->lowerImpulse;
				float newImpulse = b3MaxFloat( 0.0f, joint->lowerImpulse + impulse );
				impulse = newImpulse - joint->lowerImpulse;
				joint->lowerImpulse = newImpulse;

				b3Vec3 P = b3MulSV( impulse, axis );
				vA = b3MulSub( vA, mA, P );
				wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, P ) ) );
				vB = b3MulAdd( vB, mB, P );
				wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, P ) ) );
			}

			// upper
			{
				b3Vec3 vr = b3Add( b3Sub( vA, vB ), b3Sub( b3Cross( wA, rA ), b3Cross( wB, rB ) ) );
				float Cdot = b3Dot( axis, vr );

				float C = joint->maxLength - length;

				float bias = 0.0f;
				float massScale = 1.0f;
				float impulseScale = 0.0f;
				if ( C > 0.0f )
				{
					// speculative
					bias = C * context->inv_h;
				}
				else if ( useBias )
				{
					bias = base->constraintSoftness.biasRate * C;
					massScale = base->constraintSoftness.massScale;
					impulseScale = base->constraintSoftness.impulseScale;
				}

				float impulse = -massScale * joint->axialMass * ( Cdot + bias ) - impulseScale * joint->upperImpulse;
				float newImpulse = b3MaxFloat( 0.0f, joint->upperImpulse + impulse );
				impulse = newImpulse - joint->upperImpulse;
				joint->upperImpulse = newImpulse;

				b3Vec3 P = b3MulSV( -impulse, axis );
				vA = b3MulSub( vA, mA, P );
				wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, P ) ) );
				vB = b3MulAdd( vB, mB, P );
				wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, P ) ) );
			}
		}

		if ( joint->enableMotor )
		{
			b3Vec3 vr = b3Add( b3Sub( vB, vA ), b3Sub( b3Cross( wB, rB ), b3Cross( wA, rA ) ) );
			float Cdot = b3Dot( axis, vr );
			float impulse = joint->axialMass * ( joint->motorSpeed - Cdot );
			float oldImpulse = joint->motorImpulse;
			float maxImpulse = context->h * joint->maxMotorForce;
			joint->motorImpulse = b3ClampFloat( joint->motorImpulse + impulse, -maxImpulse, maxImpulse );
			impulse = joint->motorImpulse - oldImpulse;

			b3Vec3 P = b3MulSV( impulse, axis );
			vA = b3MulSub( vA, mA, P );
			wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, P ) ) );
			vB = b3MulAdd( vB, mB, P );
			wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, P ) ) );
		}
	}
	else
	{
		// rigid constraint
		b3Vec3 vr = b3Add( b3Sub( vB, vA ), b3Sub( b3Cross( wB, rB ), b3Cross( wA, rA ) ) );
		float Cdot = b3Dot( axis, vr );

		float C = length - joint->length;

		float bias = 0.0f;
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias )
		{
			bias = base->constraintSoftness.biasRate * C;
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		float impulse = -massScale * joint->axialMass * ( Cdot + bias ) - impulseScale * joint->impulse;
		joint->impulse += impulse;

		b3Vec3 P = b3MulSV( impulse, axis );
		vA = b3MulSub( vA, mA, P );
		wA = b3Sub( wA, b3MulMV( iA, b3Cross( rA, P ) ) );
		vB = b3MulAdd( vB, mB, P );
		wB = b3Add( wB, b3MulMV( iB, b3Cross( rB, P ) ) );
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

void b3DrawDistanceJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB )
{
	B3_ASSERT( base->type == b3_distanceJoint );

	b3DistanceJoint* joint = &base->distanceJoint;

	b3Pos pA = b3TransformWorldPoint( transformA, base->localFrameA.p );
	b3Pos pB = b3TransformWorldPoint( transformB, base->localFrameB.p );

	b3Vec3 axis = b3Normalize( b3SubPos( pB, pA ) );

	if ( joint->minLength < joint->maxLength && joint->enableLimit )
	{
		b3Pos pMin = b3OffsetPos( pA, b3MulSV( joint->minLength, axis ) );
		b3Pos pMax = b3OffsetPos( pA, b3MulSV( joint->maxLength, axis ) );

		if ( joint->minLength > B3_LINEAR_SLOP )
		{
			draw->DrawPointFcn( pMin, 6.0f, b3_colorLightGreen, draw->context );
		}

		if ( joint->maxLength < B3_HUGE )
		{
			draw->DrawPointFcn(pMax, 6.0f, b3_colorRed, draw->context);
		}

		if ( joint->minLength > B3_LINEAR_SLOP && joint->maxLength < B3_HUGE )
		{
			draw->DrawSegmentFcn( pMin, pMax, b3_colorGray, draw->context );
		}
	}

	draw->DrawSegmentFcn( pA, pB, b3_colorWhite, draw->context );
	draw->DrawPointFcn( pA, 4.0f, b3_colorWhite, draw->context );
	draw->DrawPointFcn( pB, 4.0f, b3_colorWhite, draw->context );

	if ( joint->hertz > 0.0f && joint->enableSpring )
	{
		b3Pos pRest = b3OffsetPos( pA, b3MulSV( joint->length, axis ) );
		draw->DrawPointFcn( pRest, 4.0f, b3_colorBlue, draw->context );
	}
}
