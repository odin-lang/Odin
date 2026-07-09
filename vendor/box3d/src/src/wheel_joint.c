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

void b3WheelJoint_EnableSuspension( b3JointId jointId, bool enableSpring )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointEnableSuspension, jointId, enableSpring );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );

	if ( enableSpring != joint->wheelJoint.enableSuspensionSpring )
	{
		joint->wheelJoint.enableSuspensionSpring = enableSpring;
		joint->wheelJoint.suspensionSpringImpulse = 0.0f;
	}
}

bool b3WheelJoint_IsSuspensionEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.enableSuspensionSpring;
}

void b3WheelJoint_SetSuspensionHertz( b3JointId jointId, float hertz )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSuspensionHertz, jointId, hertz );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.suspensionHertz = hertz;
}

float b3WheelJoint_GetSuspensionHertz( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.suspensionHertz;
}

void b3WheelJoint_SetSuspensionDampingRatio( b3JointId jointId, float dampingRatio )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSuspensionDampingRatio, jointId, dampingRatio );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.suspensionDampingRatio = dampingRatio;
}

float b3WheelJoint_GetSuspensionDampingRatio( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.suspensionDampingRatio;
}

void b3WheelJoint_EnableSuspensionLimit( b3JointId jointId, bool enableLimit )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointEnableSuspensionLimit, jointId, enableLimit );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	if ( joint->wheelJoint.enableSuspensionLimit != enableLimit )
	{
		joint->wheelJoint.lowerSuspensionImpulse = 0.0f;
		joint->wheelJoint.upperSuspensionImpulse = 0.0f;
		joint->wheelJoint.enableSuspensionLimit = enableLimit;
	}
}

bool b3WheelJoint_IsSuspensionLimitEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.enableSuspensionLimit;
}

float b3WheelJoint_GetLowerSuspensionLimit( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.lowerSuspensionLimit;
}

float b3WheelJoint_GetUpperSuspensionLimit( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.upperSuspensionLimit;
}

void b3WheelJoint_SetSuspensionLimits( b3JointId jointId, float lower, float upper )
{
	B3_ASSERT( lower <= upper );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSuspensionLimits, jointId, lower, upper );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	if ( lower != joint->wheelJoint.lowerSuspensionLimit || upper != joint->wheelJoint.upperSuspensionLimit )
	{
		joint->wheelJoint.lowerSuspensionLimit = lower;
		joint->wheelJoint.upperSuspensionLimit = upper;
		joint->wheelJoint.lowerSuspensionImpulse = 0.0f;
		joint->wheelJoint.upperSuspensionImpulse = 0.0f;
	}
}

void b3WheelJoint_EnableSpinMotor( b3JointId jointId, bool enableMotor )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointEnableSpinMotor, jointId, enableMotor );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	if ( joint->wheelJoint.enableSpinMotor != enableMotor )
	{
		joint->wheelJoint.spinImpulse = 0.0f;
		joint->wheelJoint.enableSpinMotor = enableMotor;
	}
}

bool b3WheelJoint_IsSpinMotorEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.enableSpinMotor;
}

void b3WheelJoint_SetSpinMotorSpeed( b3JointId jointId, float motorSpeed )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSpinMotorSpeed, jointId, motorSpeed );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.spinSpeed = motorSpeed;
}

float b3WheelJoint_GetSpinMotorSpeed( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.spinSpeed;
}

void b3WheelJoint_SetMaxSpinTorque( b3JointId jointId, float torque )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetMaxSpinTorque, jointId, torque );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.maxSpinTorque = torque;
}

float b3WheelJoint_GetMaxSpinTorque( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.maxSpinTorque;
}

void b3WheelJoint_EnableSteering( b3JointId jointId, bool flag )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointEnableSteering, jointId, flag );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	if ( joint->wheelJoint.enableSteering != flag )
	{
		joint->wheelJoint.angularImpulse = (b3Vec2){ 0.0f, 0.0f };
		joint->wheelJoint.enableSteering = flag;
	}
}

bool b3WheelJoint_IsSteeringEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.enableSteering;
}

void b3WheelJoint_SetSteeringHertz( b3JointId jointId, float hertz )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSteeringHertz, jointId, hertz );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.steeringHertz = hertz;
}

float b3WheelJoint_GetSteeringHertz( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.steeringHertz;
}

void b3WheelJoint_SetSteeringDampingRatio( b3JointId jointId, float dampingRatio )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSteeringDampingRatio, jointId, dampingRatio );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.steeringDampingRatio = dampingRatio;
}

float b3WheelJoint_GetSteeringDampingRatio( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.steeringDampingRatio;
}

void b3WheelJoint_SetMaxSteeringTorque( b3JointId jointId, float maxTorque )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetMaxSteeringTorque, jointId, maxTorque );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.maxSteeringTorque = maxTorque;
}

float b3WheelJoint_GetMaxSteeringTorque( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.maxSteeringTorque;
}

void b3WheelJoint_EnableSteeringLimit( b3JointId jointId, bool flag )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointEnableSteeringLimit, jointId, flag );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	if ( joint->wheelJoint.enableSteeringLimit != flag )
	{
		joint->wheelJoint.lowerSteeringImpulse = 0.0f;
		joint->wheelJoint.upperSteeringImpulse = 0.0f;
		joint->wheelJoint.enableSteeringLimit = flag;
	}
}

bool b3WheelJoint_IsSteeringLimitEnabled( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.enableSteeringLimit;
}

float b3WheelJoint_GetLowerSteeringLimit( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.lowerSteeringLimit;
}

float b3WheelJoint_GetUpperSteeringLimit( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.upperSteeringLimit;
}

void b3WheelJoint_SetSteeringLimits( b3JointId jointId, float lowerRadians, float upperRadians )
{
	B3_ASSERT( lowerRadians <= upperRadians );
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetSteeringLimits, jointId, lowerRadians, upperRadians );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.lowerSteeringLimit = lowerRadians;
	joint->wheelJoint.upperSteeringLimit = upperRadians;
}

void b3WheelJoint_SetTargetSteeringAngle( b3JointId jointId, float radians )
{
	b3World* world = b3GetWorld( jointId.world0 );
	B3_REC( world, WheelJointSetTargetSteeringAngle, jointId, radians );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	joint->wheelJoint.targetSteeringAngle = radians;
}

float b3WheelJoint_GetTargetSteeringAngle( b3JointId jointId )
{
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return joint->wheelJoint.targetSteeringAngle;
}

float b3WheelJoint_GetSpinSpeed( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_wheelJoint );

	int idA = base->bodyIdA;
	int idB = base->bodyIdB;

	b3Body* bodyA = b3Array_Get( world->bodies, idA  );
	b3Body* bodyB = b3Array_Get( world->bodies, idB  );

	b3SolverSet* setB = b3Array_Get( world->solverSets, bodyB->setIndex  );
	int localIndexB = bodyB->localIndex;
	b3BodySim* bodySimB = b3Array_Get( setB->bodySims, localIndexB  );

	b3Quat quatB = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	b3Vec3 spinAxis = b3RotateVector( quatB, b3Vec3_axisZ );

	b3Vec3 wA = b3Vec3_zero;
	b3BodyState* stateA = b3GetBodyState( world, bodyA );
	if ( stateA != NULL )
	{
		wA = stateA->angularVelocity;
	}

	b3Vec3 wB = b3Vec3_zero;
	b3BodyState* stateB = b3GetBodyState( world, bodyB );
	if ( stateB != NULL )
	{
		wB = stateB->angularVelocity;
	}

	float speed = b3Dot( b3Sub( wB, wA ), spinAxis );
	return speed;
}

float b3WheelJoint_GetSpinTorque( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return world->inv_h * joint->wheelJoint.spinImpulse;
}

float b3WheelJoint_GetSteeringAngle( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* base = b3GetJointSimCheckType( jointId, b3_wheelJoint );

	int idA = base->bodyIdA;
	int idB = base->bodyIdB;

	b3Body* bodyA = b3Array_Get( world->bodies, idA  );
	b3Body* bodyB = b3Array_Get( world->bodies, idB  );

	b3SolverSet* setA = b3Array_Get( world->solverSets, bodyA->setIndex  );
	b3SolverSet* setB = b3Array_Get( world->solverSets, bodyB->setIndex  );

	int localIndexA = bodyA->localIndex;
	int localIndexB = bodyB->localIndex;

	b3BodySim* bodySimA = b3Array_Get( setA->bodySims, localIndexA  );
	b3BodySim* bodySimB = b3Array_Get( setB->bodySims, localIndexB  );

	b3Quat quatA = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	b3Quat quatB = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( quatA );
	b3Matrix3 matrixB = b3MakeMatrixFromQuat( quatB );

	// Twist around x-axis
	float cs = b3Dot( matrixB.cz, matrixA.cz );
	float ss = -b3Dot( matrixB.cz, matrixA.cy );

	return b3Atan2( ss, cs );
}

float b3WheelJoint_GetSteeringTorque( b3JointId jointId )
{
	b3World* world = b3GetWorld( jointId.world0 );
	b3JointSim* joint = b3GetJointSimCheckType( jointId, b3_wheelJoint );
	return world->inv_h * joint->wheelJoint.steeringSpringImpulse;
}

b3Vec3 b3GetWheelJointForce( b3World* world, b3JointSim* base )
{
	b3WorldTransform transformA = b3GetBodyTransform( world, base->bodyIdA );
	b3WheelJoint* joint = &base->wheelJoint;

	// impulse in joint space
	b3Vec3 impulse = {
		joint->linearImpulse.x,
		joint->linearImpulse.y,
		joint->lowerSuspensionLimit + joint->upperSuspensionImpulse + joint->suspensionSpringImpulse,
	};

	// convert impulse to force
	b3Vec3 force = b3MulSV( world->inv_h, impulse );

	// convert to body space
	force = b3RotateVector( base->localFrameA.q, force );

	// convert to world space
	force = b3RotateVector( transformA.q, force );
	return force;
}

b3Vec3 b3GetWheelJointTorque( b3World* world, b3JointSim* base )
{
	B3_ASSERT( base->type == b3_wheelJoint );

	// chase body id to the solver set where the body lives
	int idA = base->bodyIdA;
	// int idB = base->bodyIdB;

	b3Body* bodyA = b3Array_Get( world->bodies, idA  );
	// b3Body* bodyB = b3Array_Get( world->bodies, idB  );

	b3SolverSet* setA = b3Array_Get( world->solverSets, bodyA->setIndex  );
	// b3SolverSet* setB = b3Array_Get( world->solverSets, bodyB->setIndex  );

	int localIndexA = bodyA->localIndex;
	// int localIndexB = bodyB->localIndex;

	b3BodySim* bodySimA = b3Array_Get( setA->bodySims, localIndexA  );
	// b3BodySim* bodySimB = b3Array_Get( setB->bodySims, localIndexB  );

	b3Quat qA = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( qA );

	return b3MulSV( world->inv_h * base->wheelJoint.spinImpulse, matrixA.cz );
}

// See constraints.pdf

void b3PrepareWheelJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_wheelJoint );

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

	b3WheelJoint* joint = &base->wheelJoint;

	joint->indexA = bodyA->setIndex == b3_awakeSet ? localIndexA : B3_NULL_INDEX;
	joint->indexB = bodyB->setIndex == b3_awakeSet ? localIndexB : B3_NULL_INDEX;

	// Compute joint anchor frames with world space rotation, relative to center of mass
	joint->frameA.q = b3MulQuat( bodySimA->transform.q, base->localFrameA.q );
	joint->frameA.p = b3RotateVector( bodySimA->transform.q, b3Sub( base->localFrameA.p, bodySimA->localCenter ) );
	joint->frameB.q = b3MulQuat( bodySimB->transform.q, base->localFrameB.q );
	joint->frameB.p = b3RotateVector( bodySimB->transform.q, b3Sub( base->localFrameB.p, bodySimB->localCenter ) );

	// Compute the initial center delta. Incremental position updates are relative to this.
	joint->deltaCenter = b3SubPos( bodySimB->center, bodySimA->center );

	b3Vec3 rA = joint->frameA.p;
	b3Vec3 rB = joint->frameB.p;

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( joint->frameA.q );
	b3Matrix3 matrixB = b3MakeMatrixFromQuat( joint->frameB.q );

	// todo use fresh effective masses in the sub-step to avoid divergence like I saw for the prismatic joint

	{
		b3Vec3 suspensionAxis = matrixA.cx;
		b3Vec3 rAn = b3Cross( rA, suspensionAxis );
		b3Vec3 rBn = b3Cross( rB, suspensionAxis );

		float k = base->invMassA + base->invMassB + b3Dot( rAn, b3MulMV( base->invIA, rAn ) ) +
				  b3Dot( rBn, b3MulMV( base->invIB, rBn ) );
		joint->suspensionMass = k > 0.0f ? 1.0f / k : 0.0f;
	}

	joint->suspensionSoftness = b3MakeSoft( joint->suspensionHertz, joint->suspensionDampingRatio, context->h );
	joint->steeringSoftness = b3MakeSoft( joint->steeringHertz, joint->steeringDampingRatio, context->h );

	{
		// Rotation axis is the z-axis of body A.
		b3Vec3 spinAxis = matrixB.cz;
		float k = b3Dot( spinAxis, b3MulMV( invInertiaSum, spinAxis ) );
		joint->spinMass = k > 0.0f ? 1.0f / k : 0.0f;
	}

	{
		// Twist constraint around x-axis
		float cs = b3Dot( matrixB.cz, matrixA.cz );
		float ss = -b3Dot( matrixB.cz, matrixA.cy );
		float den = cs * cs + ss * ss;
		den = den > 0.0f ? 1.0f / den : 0.0f;
		b3Vec3 steeringAxis =
			b3MulSV( den, b3Cross( matrixB.cz, b3Sub( b3MulSV( -cs, matrixA.cy ), b3MulSV( ss, matrixA.cz ) ) ) );

		float k = b3Dot( steeringAxis, b3MulMV( invInertiaSum, steeringAxis ) );
		joint->steeringMass = k > 0.0f ? 1.0f / k : 0.0f;
	}

	if ( context->enableWarmStarting == false )
	{
		joint->linearImpulse = (b3Vec2){ 0.0f, 0.0f };
		joint->angularImpulse = (b3Vec2){ 0.0f, 0.0f };
		joint->spinImpulse = 0.0f;
		joint->suspensionSpringImpulse = 0.0f;
		joint->lowerSuspensionImpulse = 0.0f;
		joint->upperSuspensionImpulse = 0.0f;
		joint->steeringSpringImpulse = 0.0f;
		joint->lowerSteeringImpulse = 0.0f;
		joint->upperSteeringImpulse = 0.0f;
	}
}

void b3WarmStartWheelJoint( b3JointSim* base, b3StepContext* context )
{
	B3_ASSERT( base->type == b3_wheelJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3WheelJoint* joint = &base->wheelJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	b3Vec3 d = b3Add( b3Add( b3Sub( stateB->deltaPosition, stateA->deltaPosition ), joint->deltaCenter ), b3Sub( rB, rA ) );

	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );
	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the rotation angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( quatA );
	b3Matrix3 matrixB = b3MakeMatrixFromQuat( quatB );

	b3Vec3 sAx = b3Cross( b3Add( d, rA ), matrixA.cx );
	b3Vec3 sBx = b3Cross( rB, matrixA.cx );
	b3Vec3 sAy = b3Cross( b3Add( d, rA ), matrixA.cy );
	b3Vec3 sBy = b3Cross( rB, matrixA.cy );
	b3Vec3 sAz = b3Cross( b3Add( d, rA ), matrixA.cz );
	b3Vec3 sBz = b3Cross( rB, matrixA.cz );

	float suspensionImpulse = joint->suspensionSpringImpulse + joint->lowerSuspensionImpulse - joint->upperSuspensionImpulse;

	float linearImpulseY = joint->linearImpulse.x;
	float linearImpulseZ = joint->linearImpulse.y;
	float angularImpulseX = joint->angularImpulse.x;
	float angularImpulseY = joint->angularImpulse.y;

	b3Vec3 linearImpulse = b3Blend3( suspensionImpulse, matrixA.cx, linearImpulseY, matrixA.cy, linearImpulseZ, matrixA.cz );
	b3Vec3 angularImpulseA = b3Blend3( suspensionImpulse, sAx, linearImpulseY, sAy, linearImpulseZ, sAz );
	b3Vec3 angularImpulseB = b3Blend3( suspensionImpulse, sBx, linearImpulseY, sBy, linearImpulseZ, sBz );
	b3Vec3 angularImpulse = b3MulSV( joint->spinImpulse, matrixA.cz );

	b3Vec3 spinAxis = matrixB.cz;

	if ( joint->enableSteering )
	{
		// Twist constraint around x-axis
		float cs = b3Dot( matrixB.cz, matrixA.cz );
		float ss = -b3Dot( matrixB.cz, matrixA.cy );
		float den = cs * cs + ss * ss;
		den = den > 0.0f ? 1.0f / den : 0.0f;
		b3Vec3 steeringAxis =
			b3MulSV( den, b3Cross( matrixB.cz, b3Sub( b3MulSV( -cs, matrixA.cy ), b3MulSV( ss, matrixA.cz ) ) ) );

		b3Vec3 perpAxis = b3Cross( spinAxis, matrixA.cx );
		float steeringImpulse = joint->steeringSpringImpulse + joint->lowerSteeringImpulse - joint->upperSteeringImpulse;
		angularImpulse = b3Blend3( angularImpulseX, perpAxis, joint->spinImpulse, spinAxis, steeringImpulse, steeringAxis );
	}
	else
	{
		b3Quat relQ = b3InvMulQuat( quatA, quatB );
		b3Vec3 perpAxisX = b3MulSV(
			0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
		b3Vec3 perpAxisY = b3MulSV(
			0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );
		angularImpulse = b3Add(
			angularImpulse,
			b3Blend3( angularImpulseX, perpAxisX, angularImpulseY, perpAxisY, joint->spinImpulse, spinAxis ) );
	}

	if ( stateA->flags & b3_dynamicFlag )
	{
		stateA->linearVelocity = b3MulSub( stateA->linearVelocity, mA, linearImpulse );
		stateA->angularVelocity = b3Sub( stateA->angularVelocity, b3MulMV( iA, b3Add( angularImpulseA, angularImpulse ) ) );
	}

	if ( stateB->flags & b3_dynamicFlag )
	{
		stateB->linearVelocity = b3MulAdd( stateB->linearVelocity, mB, linearImpulse );
		stateB->angularVelocity = b3Add( stateB->angularVelocity, b3MulMV( iB, b3Add( angularImpulseB, angularImpulse ) ) );
	}
}

void b3SolveWheelJoint( b3JointSim* base, b3StepContext* context, bool useBias )
{
	B3_ASSERT( base->type == b3_wheelJoint );

	float mA = base->invMassA;
	float mB = base->invMassB;
	b3Matrix3 iA = base->invIA;
	b3Matrix3 iB = base->invIB;

	// dummy state for static bodies
	b3BodyState dummyState = b3_identityBodyState;

	b3WheelJoint* joint = &base->wheelJoint;

	b3BodyState* stateA = joint->indexA == B3_NULL_INDEX ? &dummyState : context->states + joint->indexA;
	b3BodyState* stateB = joint->indexB == B3_NULL_INDEX ? &dummyState : context->states + joint->indexB;

	b3Vec3 vA = stateA->linearVelocity;
	b3Vec3 wA = stateA->angularVelocity;
	b3Vec3 vB = stateB->linearVelocity;
	b3Vec3 wB = stateB->angularVelocity;

	bool fixedRotation = base->fixedRotation;

	// current anchors
	b3Vec3 rA = b3RotateVector( stateA->deltaRotation, joint->frameA.p );
	b3Vec3 rB = b3RotateVector( stateB->deltaRotation, joint->frameB.p );

	b3Quat quatA = b3MulQuat( stateA->deltaRotation, joint->frameA.q );
	b3Quat quatB = b3MulQuat( stateB->deltaRotation, joint->frameB.q );

	if ( b3DotQuat( quatA, quatB ) < 0.0f )
	{
		// this keeps the rotation angle in the range [-pi, pi]
		quatB = b3NegateQuat( quatB );
	}

	b3Quat relQ = b3InvMulQuat( quatA, quatB );
	b3Matrix3 matrixA = b3MakeMatrixFromQuat( quatA );
	b3Matrix3 matrixB = b3MakeMatrixFromQuat( quatB );

	// b3Vec3 spinAxis = b3RotateVector( quatB, b3Vec3_axisZ );

	b3Vec3 d = b3Add( b3Add( b3Sub( stateB->deltaPosition, stateA->deltaPosition ), joint->deltaCenter ), b3Sub( rB, rA ) );
	b3Vec3 sAx = b3Cross( b3Add( d, rA ), matrixA.cx );
	b3Vec3 sBx = b3Cross( rB, matrixA.cx );
	b3Vec3 sAy = b3Cross( b3Add( d, rA ), matrixA.cy );
	b3Vec3 sBy = b3Cross( rB, matrixA.cy );
	b3Vec3 sAz = b3Cross( b3Add( d, rA ), matrixA.cz );
	b3Vec3 sBz = b3Cross( rB, matrixA.cz );

	float translation = b3Dot( matrixA.cx, d );

	// Steering param ib = cz_b, ia = cz_a, ja = -cy_a
	float cs = b3Dot( matrixB.cz, matrixA.cz );
	float ss = -b3Dot( matrixB.cz, matrixA.cy );
	float den = cs * cs + ss * ss;
	den = den > 0.0f ? 1.0f / den : 0.0f;
	b3Vec3 steeringAxis =
		b3MulSV( den, b3Cross( matrixB.cz, b3Sub( b3MulSV( -cs, matrixA.cy ), b3MulSV( ss, matrixA.cz ) ) ) );

	// motor constraint
	if ( joint->enableSpinMotor && fixedRotation == false )
	{
		b3Vec3 spinAxis = matrixB.cz;
		float cdot = b3Dot( b3Sub( wB, wA ), spinAxis ) - joint->spinSpeed;
		float impulse = -joint->spinMass * cdot;
		float oldImpulse = joint->spinImpulse;
		float maxImpulse = context->h * joint->maxSpinTorque;
		joint->spinImpulse = b3ClampFloat( joint->spinImpulse + impulse, -maxImpulse, maxImpulse );
		impulse = joint->spinImpulse - oldImpulse;

		wA = b3Sub( wA, b3MulMV( iA, b3MulSV( impulse, spinAxis ) ) );
		wB = b3Add( wB, b3MulMV( iB, b3MulSV( impulse, spinAxis ) ) );
	}

	// suspension
	if ( joint->enableSuspensionSpring )
	{
		// This is a real spring and should be applied even during relax
		float c = translation;
		float bias = joint->suspensionSoftness.biasRate * c;
		float massScale = joint->suspensionSoftness.massScale;
		float impulseScale = joint->suspensionSoftness.impulseScale;

		float cdot = b3Dot( matrixA.cx, b3Sub( vB, vA ) ) + b3Dot( sBx, wB ) - b3Dot( sAx, wA );
		float impulse = -massScale * joint->suspensionMass * ( cdot + bias ) - impulseScale * joint->suspensionSpringImpulse;
		joint->suspensionSpringImpulse += impulse;

		b3Vec3 linearImpulse = b3MulSV( impulse, matrixA.cx );
		b3Vec3 angularImpulseA = b3MulSV( impulse, sAx );
		b3Vec3 angularImpulseB = b3MulSV( impulse, sBx );

		vA = b3MulSub( vA, mA, linearImpulse );
		wA = b3Sub( wA, b3MulMV( iA, angularImpulseA ) );
		vB = b3MulAdd( vB, mB, linearImpulse );
		wB = b3Add( wB, b3MulMV( iB, angularImpulseB ) );
	}

	// steering
	if ( joint->enableSteering && fixedRotation == false )
	{
		float steeringAngle = b3Atan2( ss, cs );

		{
			// This is a real spring and should be applied even during relax
			float c = steeringAngle - joint->targetSteeringAngle;
			float bias = joint->steeringSoftness.biasRate * c;
			float massScale = joint->steeringSoftness.massScale;
			float impulseScale = joint->steeringSoftness.impulseScale;

			float cdot = b3Dot( steeringAxis, b3Sub( wB, wA ) );
			float oldImpulse = joint->steeringSpringImpulse;
			float impulse = -massScale * joint->steeringMass * ( cdot + bias ) - impulseScale * oldImpulse;
			float maxImpulse = context->h * joint->maxSteeringTorque;
			joint->steeringSpringImpulse = b3ClampFloat( oldImpulse + impulse, -maxImpulse, maxImpulse );
			impulse = joint->steeringSpringImpulse - oldImpulse;

			wA = b3Sub( wA, b3MulMV( iA, b3MulSV( impulse, steeringAxis ) ) );
			wB = b3Add( wB, b3MulMV( iB, b3MulSV( impulse, steeringAxis ) ) );
		}

		if ( joint->enableSteeringLimit )
		{
			// Lower limit
			{
				float c = steeringAngle - joint->lowerSteeringLimit;
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

				float cdot = b3Dot( steeringAxis, b3Sub( wB, wA ) );
				float oldImpulse = joint->lowerSteeringImpulse;
				float impulse = -massScale * joint->steeringMass * ( cdot + bias ) - impulseScale * oldImpulse;
				joint->lowerSteeringImpulse = b3MaxFloat( oldImpulse + impulse, 0.0f );
				impulse = joint->lowerSteeringImpulse - oldImpulse;

				wA = b3Sub( wA, b3MulMV( iA, b3MulSV( impulse, steeringAxis ) ) );
				wB = b3Add( wB, b3MulMV( iB, b3MulSV( impulse, steeringAxis ) ) );
			}

			// Upper limit
			// Note: signs are flipped to keep c positive when the constraint is satisfied.
			// This also keeps the impulse positive when the limit is active.
			{
				// sign flipped
				float c = joint->upperSteeringLimit - steeringAngle;
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

				// sign flipped on cdot
				float cdot = b3Dot( steeringAxis, b3Sub( wA, wB ) );
				float oldImpulse = joint->upperSteeringImpulse;
				float impulse = -massScale * joint->steeringMass * ( cdot + bias ) - impulseScale * oldImpulse;
				joint->upperSteeringImpulse = b3MaxFloat( oldImpulse + impulse, 0.0f );
				impulse = joint->upperSteeringImpulse - oldImpulse;

				// sign flipped on applied impulse
				wA = b3Add( wA, b3MulMV( iA, b3MulSV( impulse, steeringAxis ) ) );
				wB = b3Sub( wB, b3MulMV( iB, b3MulSV( impulse, steeringAxis ) ) );
			}
		}
	}

	if ( joint->enableSuspensionLimit )
	{
		// Lower limit
		{
			float c = translation - joint->lowerSuspensionLimit;
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

			float cdot = b3Dot( matrixA.cx, b3Sub( vB, vA ) ) + b3Dot( sBx, wB ) - b3Dot( sAx, wA );
			float impulse = -massScale * joint->suspensionMass * ( cdot + bias ) - impulseScale * joint->lowerSuspensionImpulse;
			float oldImpulse = joint->lowerSuspensionImpulse;
			joint->lowerSuspensionImpulse = b3MaxFloat( oldImpulse + impulse, 0.0f );
			impulse = joint->lowerSuspensionImpulse - oldImpulse;

			b3Vec3 linearImpulse = b3MulSV( impulse, matrixA.cx );
			b3Vec3 angularImpulseA = b3MulSV( impulse, sAx );
			b3Vec3 angularImpulseB = b3MulSV( impulse, sBx );

			vA = b3MulSub( vA, mA, linearImpulse );
			wA = b3Sub( wA, b3MulMV( iA, angularImpulseA ) );
			vB = b3MulAdd( vB, mB, linearImpulse );
			wB = b3Add( wB, b3MulMV( iB, angularImpulseB ) );
		}

		// Upper limit
		// Note: signs are flipped to keep c positive when the constraint is satisfied.
		// This also keeps the impulse positive when the limit is active.
		{
			// sign flipped
			float c = joint->upperSuspensionLimit - translation;
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

			// sign flipped on cdot
			float cdot = b3Dot( matrixA.cx, b3Sub( vA, vB ) ) + b3Dot( sAx, wA ) - b3Dot( sBx, wB );
			float impulse = -massScale * joint->suspensionMass * ( cdot + bias ) - impulseScale * joint->upperSuspensionImpulse;
			float oldImpulse = joint->upperSuspensionImpulse;
			joint->upperSuspensionImpulse = b3MaxFloat( oldImpulse + impulse, 0.0f );
			impulse = joint->upperSuspensionImpulse - oldImpulse;

			b3Vec3 linearImpulse = b3MulSV( impulse, matrixA.cx );
			b3Vec3 angularImpulseA = b3MulSV( impulse, sAx );
			b3Vec3 angularImpulseB = b3MulSV( impulse, sBx );

			// sign flipped on applied impulse
			vA = b3MulAdd( vA, mA, linearImpulse );
			wA = b3Add( wA, b3MulMV( iA, angularImpulseA ) );
			vB = b3MulSub( vB, mB, linearImpulse );
			wB = b3Sub( wB, b3MulMV( iB, angularImpulseB ) );
		}
	}

	// Collinearity constraint
	if ( fixedRotation == false )
	{
		if ( joint->enableSteering == true )
		{
			float bias = 0.0f;
			float massScale = 1.0f;
			float impulseScale = 0.0f;
			if ( useBias )
			{
				float c = b3Dot( matrixA.cx, matrixB.cz );

				bias = base->constraintSoftness.biasRate * c;
				massScale = base->constraintSoftness.massScale;
				impulseScale = base->constraintSoftness.impulseScale;
			}

			b3Vec3 u = b3Cross( matrixB.cz, matrixA.cx );
			float cdot = b3Dot( b3Sub( wB, wA ), u );

			b3Matrix3 invInertiaSum = b3AddMM( iA, iB );
			float k = b3Dot( u, b3MulMV( invInertiaSum, u ) );
			float perpMass = k > 0.0f ? 1.0f / k : 0.0f;

			float deltaImpulse = -massScale * perpMass * ( cdot + bias ) - impulseScale * joint->angularImpulse.x;
			joint->angularImpulse.x += deltaImpulse;

			wA = b3MulSub( wA, deltaImpulse, b3MulMV( iA, u ) );
			wB = b3MulAdd( wB, deltaImpulse, b3MulMV( iB, u ) );
		}
		else
		{
			b3Vec2 bias = { 0.0f, 0.0f };
			float massScale = 1.0f;
			float impulseScale = 0.0f;

			if ( useBias )
			{
				b3Vec2 c = { relQ.v.x, relQ.v.y };
				bias = (b3Vec2){ base->constraintSoftness.biasRate * c.x, base->constraintSoftness.biasRate * c.y };
				massScale = base->constraintSoftness.massScale;
				impulseScale = base->constraintSoftness.impulseScale;
			}

			// Collinearity constraint as 2-by-2
			b3Vec3 perpAxisX = b3MulSV(
				0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisX ), b3Cross( relQ.v, b3Vec3_axisX ) ) ) );
			b3Vec3 perpAxisY = b3MulSV(
				0.5f, b3RotateVector( quatA, b3Add( b3MulSV( relQ.s, b3Vec3_axisY ), b3Cross( relQ.v, b3Vec3_axisY ) ) ) );

			b3Matrix3 invInertiaSum = b3AddMM( iA, iB );
			float kxx = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisX ) );
			float kyy = b3Dot( perpAxisY, b3MulMV( invInertiaSum, perpAxisY ) );
			float kxy = b3Dot( perpAxisX, b3MulMV( invInertiaSum, perpAxisY ) );

			b3Matrix2 k = { { kxx, kxy }, { kxy, kyy } };

			b3Vec3 wRel = b3Sub( wB, wA );
			b3Vec2 cdot = { b3Dot( wRel, perpAxisX ), b3Dot( wRel, perpAxisY ) };
			b3Vec2 oldImpulse = joint->angularImpulse;
			b3Vec2 cdotPlusBias = { cdot.x + bias.x, cdot.y + bias.y };
			b3Vec2 sol = b3Solve2( k, cdotPlusBias );
			b3Vec2 deltaImpulse = {
				-massScale * sol.x - impulseScale * oldImpulse.x,
				-massScale * sol.y - impulseScale * oldImpulse.y,
			};
			joint->angularImpulse = (b3Vec2){ oldImpulse.x + deltaImpulse.x, oldImpulse.y + deltaImpulse.y };

			b3Vec3 angularImpulse = b3Blend2( deltaImpulse.x, perpAxisX, deltaImpulse.y, perpAxisY );
			wA = b3Sub( wA, b3MulMV( iA, angularImpulse ) );
			wB = b3Add( wB, b3MulMV( iB, angularImpulse ) );
		}
	}

	// Solve point-to-line constraint
	{
		b3Vec3 perpY = matrixA.cy;
		b3Vec3 perpZ = matrixA.cz;

		b3Vec2 bias = { 0.0f, 0.0f };
		float massScale = 1.0f;
		float impulseScale = 0.0f;
		if ( useBias )
		{
			b3Vec2 c = { b3Dot( perpY, d ), b3Dot( perpZ, d ) };
			bias = (b3Vec2){ base->constraintSoftness.biasRate * c.x, base->constraintSoftness.biasRate * c.y };
			massScale = base->constraintSoftness.massScale;
			impulseScale = base->constraintSoftness.impulseScale;
		}

		b3Vec3 vRel = b3Sub( b3Sub( b3Add( vB, b3Cross( wB, rB ) ), vA ), b3Cross( wA, b3Add( rA, d ) ) );
		b3Vec2 cdot = { b3Dot( perpY, vRel ), b3Dot( perpZ, vRel ) };

		//// K = [(1/m1 + 1/m2) * eye(2) - skew(r1) * invI1 * skew(r1) - skew(r2) * invI2 * skew(r2)]
		///// Jx = [-perpX, -cross(d + rA, perpX), perpX, cross(rB, perpX)]

		float kyy = mA + mB + b3Dot( sAy, b3MulMV( iA, sAy ) ) + b3Dot( sBy, b3MulMV( iB, sBy ) );
		float kyz = b3Dot( sAy, b3MulMV( iA, sAz ) ) + b3Dot( sBy, b3MulMV( iB, sBz ) );
		float kzz = mA + mB + b3Dot( sAz, b3MulMV( iA, sAz ) ) + b3Dot( sBz, b3MulMV( iB, sBz ) );

		b3Matrix2 k = { { kyy, kyz }, { kyz, kzz } };

		b3Vec2 oldImpulse = joint->linearImpulse;
		b3Vec2 cdotPlusBias = { cdot.x + bias.x, cdot.y + bias.y };
		b3Vec2 sol = b3Solve2( k, cdotPlusBias );
		b3Vec2 deltaImpulse = {
			-massScale * sol.x - impulseScale * oldImpulse.x,
			-massScale * sol.y - impulseScale * oldImpulse.y,
		};
		joint->linearImpulse = (b3Vec2){ oldImpulse.x + deltaImpulse.x, oldImpulse.y + deltaImpulse.y };

		b3Vec3 linearImpulse = b3Blend2( deltaImpulse.x, perpY, deltaImpulse.y, perpZ );

		vA = b3MulSub( vA, mA, linearImpulse );
		wA = b3Sub( wA, b3MulMV( iA, b3Blend2( deltaImpulse.x, sAy, deltaImpulse.y, sAz ) ) );
		vB = b3MulAdd( vB, mB, linearImpulse );
		wB = b3Add( wB, b3MulMV( iB, b3Blend2( deltaImpulse.x, sBy, deltaImpulse.y, sBz ) ) );
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

#if 0
void b3WheelJoint_Dump()
{
	int32 indexA = joint->bodyA->joint->islandIndex;
	int32 indexB = joint->bodyB->joint->islandIndex;

	b3Dump("  b3WheelJointDef jd;\n");
	b3Dump("  jd.bodyA = sims[%d];\n", indexA);
	b3Dump("  jd.bodyB = sims[%d];\n", indexB);
	b3Dump("  jd.collideConnected = bool(%d);\n", joint->collideConnected);
	b3Dump("  jd.localAnchorA.Set(%.9g, %.9g);\n", joint->localAnchorA.x, joint->localAnchorA.y);
	b3Dump("  jd.localAnchorB.Set(%.9g, %.9g);\n", joint->localAnchorB.x, joint->localAnchorB.y);
	b3Dump("  jd.referenceAngle = %.9g;\n", joint->referenceAngle);
	b3Dump("  jd.enableLimit = bool(%d);\n", joint->enableLimit);
	b3Dump("  jd.lowerAngle = %.9g;\n", joint->lowerAngle);
	b3Dump("  jd.upperAngle = %.9g;\n", joint->upperAngle);
	b3Dump("  jd.enableMotor = bool(%d);\n", joint->enableMotor);
	b3Dump("  jd.motorSpeed = %.9g;\n", joint->motorSpeed);
	b3Dump("  jd.maxMotorTorque = %.9g;\n", joint->maxMotorTorque);
	b3Dump("  joints[%d] = joint->world->CreateJoint(&jd);\n", joint->index);
}
#endif

void b3DrawWheelJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale )
{
	B3_ASSERT( base->type == b3_wheelJoint );

	b3WheelJoint* joint = &base->wheelJoint;

	b3WorldTransform frameA = b3MulWorldTransforms( transformA, base->localFrameA );
	b3WorldTransform frameB = b3MulWorldTransforms( transformB, base->localFrameB );

	b3Matrix3 matrixA = b3MakeMatrixFromQuat( frameA.q );
	b3Matrix3 matrixB = b3MakeMatrixFromQuat( frameB.q );

	draw->DrawSegmentFcn( frameA.p, frameB.p, b3_colorBlue, draw->context );

	if ( joint->enableSuspensionLimit )
	{
		b3Pos lower = b3OffsetPos( frameA.p, b3MulSV( joint->lowerSuspensionLimit, matrixA.cx ) );
		b3Pos upper = b3OffsetPos( frameA.p, b3MulSV( joint->upperSuspensionLimit, matrixA.cx ) );
		b3Vec3 perp = matrixA.cy;
		draw->DrawSegmentFcn( lower, upper, b3_colorGray, draw->context );
		draw->DrawSegmentFcn( b3OffsetPos( lower, b3MulSV( -0.1f * scale, perp ) ), b3OffsetPos( lower, b3MulSV( 0.1f * scale, perp ) ),
							  b3_colorGreen, draw->context );
		draw->DrawSegmentFcn( b3OffsetPos( upper, b3MulSV( -0.1f * scale, perp ) ), b3OffsetPos( upper, b3MulSV( 0.1f * scale, perp ) ),
							  b3_colorRed, draw->context );
	}
	else
	{
		draw->DrawSegmentFcn( b3OffsetPos( frameA.p, b3MulSV( -1.0f * scale, matrixA.cx ) ),
							  b3OffsetPos( frameA.p, b3MulSV( 1.0f * scale, matrixA.cx ) ), b3_colorGray, draw->context );
	}

	if ( joint->enableSteering && joint->enableSteeringLimit )
	{
		// b3Quat quatA = frameA.q;
		// b3Quat quatB = frameB.q;

		// if ( b3DotQuat( quatA, quatB ) < 0.0f )
		//{
		//	// this keeps the twist angle in the range [-pi, pi]
		//	quatB = -quatB;
		// }

		// b3Quat relQ = b3InvMulQuat( quatA, quatB );

		b3WorldTransform frame = {
			.p = frameB.p,
			.q = frameA.q,
		};

		const float radius = 0.5f * scale;
		const int sliceCount = 16;
		float lower = joint->lowerSteeringLimit;
		float upper = joint->upperSteeringLimit;

		b3CosSin cs = b3ComputeCosSin( lower );
		b3Pos vertex1 = b3TransformWorldPoint( frame, (b3Vec3){ 0.0f, -radius * cs.sine, radius * cs.cosine } );

		for ( int index = 0; index < sliceCount; ++index )
		{
			float t2 = ( index + 1.0f ) / sliceCount;
			float phi = b3LerpFloat( lower, upper, t2 );

			cs = b3ComputeCosSin( phi );
			b3Pos vertex2 = b3TransformWorldPoint( frame, (b3Vec3){ 0.0f, -radius * cs.sine, radius * cs.cosine } );

			if ( index == 0 )
			{
				draw->DrawSegmentFcn( frame.p, vertex1, b3_colorCyan, draw->context );
			}

			if ( index == sliceCount - 1 )
			{
				draw->DrawSegmentFcn( vertex2, frame.p, b3_colorCyan, draw->context );
			}
			draw->DrawSegmentFcn( vertex1, vertex2, b3_colorCyan, draw->context );

			vertex1 = vertex2;
		}
	}

	draw->DrawSegmentFcn( b3OffsetPos( frameB.p, b3MulSV( -0.5f * scale, matrixB.cz ) ),
						  b3OffsetPos( frameB.p, b3MulSV( 0.5f * scale, matrixB.cz ) ), b3_colorMagenta, draw->context );

	draw->DrawPointFcn( frameA.p, 5.0f, b3_colorGray, draw->context );
	draw->DrawPointFcn( frameB.p, 5.0f, b3_colorDimGray, draw->context );
}
