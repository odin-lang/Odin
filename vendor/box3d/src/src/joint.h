// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "math_internal.h"
#include "solver.h"

#include "box3d/types.h"

typedef struct b3DebugDraw b3DebugDraw;
typedef struct b3StepContext b3StepContext;
typedef struct b3World b3World;

/// A joint edge is used to connect bodies and joints together
/// in a joint graph where each body is a node and each joint
/// is an edge. A joint edge belongs to a doubly linked list
/// maintained in each attached body. Each joint has two joint
/// nodes, one for each attached body.
typedef struct b3JointEdge
{
	int bodyId;
	int prevKey;
	int nextKey;
} b3JointEdge;

// Map from b3JointId to b3Joint in the solver sets
typedef struct b3Joint
{
	void* userData;

	// index of simulation set stored in b3World
	// B3_NULL_INDEX when slot is free
	int setIndex;

	// index into the constraint graph color array, may be B3_NULL_INDEX for sleeping/disabled joints
	// B3_NULL_INDEX when slot is free
	int colorIndex;

	// joint index within set or graph color
	// B3_NULL_INDEX when slot is free
	int localIndex;

	b3JointEdge edges[2];

	int jointId;
	int islandId;

	// Index into the island's joints array for O(1) swap-removal.
	// B3_NULL_INDEX when not in an island.
	int islandIndex;

	float drawScale;

	b3JointType type;

	// This is monotonically advanced when a body is allocated in this slot
	// Used to check for invalid b3JointId
	uint16_t generation;

	bool collideConnected;
} b3Joint;

typedef struct b3DistanceJoint
{
	float length;
	float hertz;
	float dampingRatio;
	float lowerSpringForce;
	float upperSpringForce;
	float minLength;
	float maxLength;

	float maxMotorForce;
	float motorSpeed;

	float impulse;
	float lowerImpulse;
	float upperImpulse;
	float motorImpulse;

	int indexA;
	int indexB;
	b3Vec3 anchorA;
	b3Vec3 anchorB;
	b3Vec3 deltaCenter;
	b3Softness distanceSoftness;
	float axialMass;

	bool enableSpring;
	bool enableLimit;
	bool enableMotor;
} b3DistanceJoint;

typedef struct b3MotorJoint
{
	b3Vec3 linearVelocity;
	b3Vec3 angularVelocity;
	float maxVelocityForce;
	float maxVelocityTorque;
	float linearHertz;
	float linearDampingRatio;
	float maxSpringForce;
	float angularHertz;
	float angularDampingRatio;
	float maxSpringTorque;

	b3Vec3 linearVelocityImpulse;
	b3Vec3 angularVelocityImpulse;
	b3Vec3 linearSpringImpulse;
	b3Vec3 angularSpringImpulse;

	b3Softness linearSpring;
	b3Softness angularSpring;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 deltaCenter;
	b3Matrix3 angularMass;
} b3MotorJoint;

typedef struct b3ParallelJoint
{
	float hertz;
	float dampingRatio;
	float maxTorque;

	b3Vec2 perpImpulse;
	b3Vec3 perpAxisX;
	b3Vec3 perpAxisY;

	b3Quat quatA;
	b3Quat quatB;
	int indexA;
	int indexB;
	b3Softness softness;
} b3ParallelJoint;

typedef struct b3PrismaticJoint
{
	b3Vec2 perpImpulse;
	b3Vec3 angularImpulse;
	float springImpulse;
	float motorImpulse;
	float lowerImpulse;
	float upperImpulse;
	float hertz;
	float dampingRatio;
	float maxMotorForce;
	float motorSpeed;
	float targetTranslation;
	float lowerTranslation;
	float upperTranslation;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 jointAxis;
	b3Vec3 perpAxisY;
	b3Vec3 perpAxisZ;
	b3Vec3 deltaCenter;
	float deltaAngle;
	b3Matrix3 rotationMass;
	b3Softness springSoftness;

	bool enableSpring;
	bool enableLimit;
	bool enableMotor;
} b3PrismaticJoint;

typedef struct b3RevoluteJoint
{
	b3Vec3 linearImpulse;
	b3Vec2 perpImpulse;
	float springImpulse;
	float motorImpulse;
	float lowerImpulse;
	float upperImpulse;
	float hertz;
	float dampingRatio;
	float maxMotorTorque;
	float motorSpeed;
	float targetAngle;
	float lowerAngle;
	float upperAngle;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 rotationAxisZ;
	b3Vec3 perpAxisX;
	b3Vec3 perpAxisY;
	b3Vec3 deltaCenter;
	float deltaAngle;
	float axialMass;
	b3Softness springSoftness;

	bool enableSpring;
	bool enableMotor;
	bool enableLimit;
} b3RevoluteJoint;

typedef struct b3SphericalJoint
{
	b3Vec3 linearImpulse;
	b3Vec3 springImpulse;
	b3Vec3 motorImpulse;
	float lowerTwistImpulse;
	float upperTwistImpulse;
	float swingImpulse;
	float hertz;
	float dampingRatio;
	float maxMotorTorque;
	b3Vec3 motorVelocity;
	float lowerTwistAngle;
	float upperTwistAngle;
	float coneAngle;
	b3Quat targetRotation;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 deltaCenter;
	b3Vec3 swingAxis;
	b3Vec3 twistJacobian;

	b3Matrix3 rotationMass;
	float swingMass;
	float twistMass;
	b3Softness springSoftness;

	bool enableSpring;
	bool enableMotor;
	bool enableConeLimit;
	bool enableTwistLimit;
} b3SphericalJoint;

typedef struct b3WeldJoint
{
	float linearHertz;
	float linearDampingRatio;
	float angularHertz;
	float angularDampingRatio;

	b3Softness linearSpring;
	b3Softness angularSpring;
	b3Vec3 linearImpulse;
	b3Vec3 angularImpulse;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 deltaCenter;

	b3Matrix3 angularMass;
} b3WeldJoint;

typedef struct b3WheelJoint
{
	b3Vec2 linearImpulse;
	b3Vec2 angularImpulse;
	float spinImpulse;
	float maxSpinTorque;
	float spinSpeed;
	float suspensionSpringImpulse;
	float lowerSuspensionImpulse;
	float upperSuspensionImpulse;
	float lowerSuspensionLimit;
	float upperSuspensionLimit;
	float suspensionHertz;
	float suspensionDampingRatio;
	float steeringSpringImpulse;
	float lowerSteeringImpulse;
	float upperSteeringImpulse;
	float lowerSteeringLimit;
	float upperSteeringLimit;
	float targetSteeringAngle;
	float maxSteeringTorque;
	float steeringHertz;
	float steeringDampingRatio;

	int indexA;
	int indexB;
	b3Transform frameA;
	b3Transform frameB;
	b3Vec3 deltaCenter;
	float spinMass;
	float suspensionMass;
	float steeringMass;
	b3Softness suspensionSoftness;
	b3Softness steeringSoftness;

	bool enableSpinMotor;
	bool enableSuspensionSpring;
	bool enableSuspensionLimit;
	bool enableSteering;
	bool enableSteeringLimit;
	bool enableSteeringMotor;
} b3WheelJoint;

/// The base joint class. Joints are used to constraint two bodies together in
/// various fashions. Some joints also feature limits and motors.
typedef struct b3JointSim
{
	int jointId;

	int bodyIdA;
	int bodyIdB;

	b3JointType type;

	// Joint frames local to body origin
	b3Transform localFrameA;
	b3Transform localFrameB;

	float invMassA, invMassB;
	b3Matrix3 invIA, invIB;

	float constraintHertz;
	float constraintDampingRatio;

	b3Softness constraintSoftness;

	float forceThreshold;
	float torqueThreshold;

	bool fixedRotation;

	union
	{
		b3DistanceJoint distanceJoint;
		b3MotorJoint motorJoint;
		b3ParallelJoint parallelJoint;
		b3RevoluteJoint revoluteJoint;
		b3SphericalJoint sphericalJoint;
		b3PrismaticJoint prismaticJoint;
		b3WeldJoint weldJoint;
		b3WheelJoint wheelJoint;
	};
} b3JointSim;

void b3DestroyJointInternal( b3World* world, b3Joint* joint, bool wakeBodies );

b3Joint* b3GetJointFullId( b3World* world, b3JointId jointId );
b3JointSim* b3GetJointSim( b3World* world, b3Joint* joint );
b3JointSim* b3GetJointSimCheckType( b3JointId jointId, b3JointType type );

void b3PrepareJoint( b3JointSim* joint, b3StepContext* context );
void b3WarmStartJoint( b3JointSim* joint, b3StepContext* context );
void b3SolveJoint( b3JointSim* joint, b3StepContext* context, bool useBias );

void b3PrepareJoints_Overflow( b3StepContext* context );
void b3WarmStartJoints_Overflow( b3StepContext* context );
void b3SolveJoints_Overflow( b3StepContext* context, bool useBias );

void b3GetJointReaction( b3World* world, b3JointSim* sim, float invTimeStep, float* force, float* torque );

void b3DrawJoint( b3DebugDraw* draw, b3World* world, b3Joint* joint );

b3Vec3 b3GetDistanceJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetMotorJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetPrismaticJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetRevoluteJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetSphericalJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetWeldJointForce( b3World* world, b3JointSim* base );
b3Vec3 b3GetWheelJointForce( b3World* world, b3JointSim* base );

b3Vec3 b3GetMotorJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetParallelJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetPrismaticJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetRevoluteJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetSphericalJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetWeldJointTorque( b3World* world, b3JointSim* base );
b3Vec3 b3GetWheelJointTorque( b3World* world, b3JointSim* base );

void b3PrepareDistanceJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareMotorJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareParallelJoint( b3JointSim* base, b3StepContext* context );
void b3PreparePrismaticJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareRevoluteJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareSphericalJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareWeldJoint( b3JointSim* base, b3StepContext* context );
void b3PrepareWheelJoint( b3JointSim* base, b3StepContext* context );

void b3WarmStartDistanceJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartMotorJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartParallelJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartPrismaticJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartRevoluteJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartSphericalJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartWeldJoint( b3JointSim* base, b3StepContext* context );
void b3WarmStartWheelJoint( b3JointSim* base, b3StepContext* context );

void b3SolveDistanceJoint( b3JointSim* base, b3StepContext* context, bool useBias );
void b3SolveMotorJoint( b3JointSim* base, b3StepContext* context );
void b3SolveParallelJoint( b3JointSim* base, b3StepContext* context );
void b3SolvePrismaticJoint( b3JointSim* base, b3StepContext* context, bool useBias );
void b3SolveRevoluteJoint( b3JointSim* base, b3StepContext* context, bool useBias );
void b3SolveSphericalJoint( b3JointSim* base, b3StepContext* context, bool useBias );
void b3SolveWeldJoint( b3JointSim* base, b3StepContext* context, bool useBias );
void b3SolveWheelJoint( b3JointSim* base, b3StepContext* context, bool useBias );

void b3DrawDistanceJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB );
void b3DrawParallelJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
void b3DrawPrismaticJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
void b3DrawRevoluteJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
void b3DrawSphericalJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
void b3DrawWeldJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
void b3DrawWheelJoint( b3DebugDraw* draw, b3JointSim* base, b3WorldTransform transformA, b3WorldTransform transformB, float scale );
