// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// X-macro manifest for the recording system.
// Include with B3_REC_OP and ARG defined. No commas between ARG tokens.
//
// B3_REC_OP( opcode, Name, RET, ARGS )
//   RET in { RET_NONE, RET_BODYID, RET_SHAPEID, RET_JOINTID }
//   ARGS = zero or more ARG( TAG, fieldName ) tokens, NO commas between them
//
// Opcode ranges:
//   0x00-0x0F  world lifecycle and config
//   0x10-0x1F  body create/destroy
//   0x20-0x3F  body mutators
//   0x40-0x4F  shape create/destroy
//   0x50-0x6F  shape mutators
//   0x80       step
//   0x90-0xE7  joints (create, generic, per-type)
//   0xE8-0xEF  spatial queries
//   0xF0-0xFF  markers

// Recordings are seeded with a world snapshot, not a CreateWorld op. DestroyWorld stays as the
// end-of-session marker the viewer reads.
B3_REC_OP( 0x01, DestroyWorld, RET_NONE, ARG( WORLDID, world ) )
B3_REC_OP( 0x80, Step, RET_NONE, ARG( WORLDID, world ) ARG( F32, dt ) ARG( I32, subStepCount ) )

// World config. The world arg is informational; replay always targets its own world.
B3_REC_OP( 0x02, WorldEnableSleeping, RET_NONE, ARG( WORLDID, world ) ARG( BOOL, flag ) )
B3_REC_OP( 0x03, WorldEnableContinuous, RET_NONE, ARG( WORLDID, world ) ARG( BOOL, flag ) )
B3_REC_OP( 0x04, WorldSetRestitutionThreshold, RET_NONE, ARG( WORLDID, world ) ARG( F32, value ) )
B3_REC_OP( 0x05, WorldSetHitEventThreshold, RET_NONE, ARG( WORLDID, world ) ARG( F32, value ) )
B3_REC_OP( 0x06, WorldSetGravity, RET_NONE, ARG( WORLDID, world ) ARG( VEC3, gravity ) )
B3_REC_OP( 0x07, WorldExplode, RET_NONE, ARG( WORLDID, world ) ARG( EXPLOSIONDEF, def ) )
B3_REC_OP( 0x08, WorldSetContactTuning, RET_NONE,
		   ARG( WORLDID, world ) ARG( F32, hertz ) ARG( F32, dampingRatio ) ARG( F32, contactSpeed ) )
B3_REC_OP( 0x09, WorldSetContactRecycleDistance, RET_NONE, ARG( WORLDID, world ) ARG( F32, recycleDistance ) )
B3_REC_OP( 0x0A, WorldSetMaximumLinearSpeed, RET_NONE, ARG( WORLDID, world ) ARG( F32, maximumLinearSpeed ) )
B3_REC_OP( 0x0B, WorldEnableWarmStarting, RET_NONE, ARG( WORLDID, world ) ARG( BOOL, flag ) )
B3_REC_OP( 0x0C, WorldRebuildStaticTree, RET_NONE, ARG( WORLDID, world ) )
B3_REC_OP( 0x0D, WorldEnableSpeculative, RET_NONE, ARG( WORLDID, world ) ARG( BOOL, flag ) )

// Body
B3_REC_OP( 0x10, CreateBody, RET_BODYID, ARG( WORLDID, world ) ARG( BODYDEF, def ) )
B3_REC_OP( 0x11, DestroyBody, RET_NONE, ARG( BODYID, body ) )
B3_REC_OP( 0x20, BodySetTransform, RET_NONE, ARG( BODYID, body ) ARG( POSITION, position ) ARG( QUAT, rotation ) )
B3_REC_OP( 0x21, BodySetLinearVelocity, RET_NONE, ARG( BODYID, body ) ARG( VEC3, v ) )
B3_REC_OP( 0x22, BodySetType, RET_NONE, ARG( BODYID, body ) ARG( I32, type ) )
B3_REC_OP( 0x23, BodySetName, RET_NONE, ARG( BODYID, body ) ARG( STR, name ) )
B3_REC_OP( 0x24, BodySetAngularVelocity, RET_NONE, ARG( BODYID, body ) ARG( VEC3, w ) )
B3_REC_OP( 0x25, BodySetTargetTransform, RET_NONE, ARG( BODYID, body ) ARG( WORLDXF, target ) ARG( F32, timeStep ) ARG( BOOL, wake ) )
B3_REC_OP( 0x26, BodyApplyForce, RET_NONE, ARG( BODYID, body ) ARG( VEC3, force ) ARG( POSITION, point ) ARG( BOOL, wake ) )
B3_REC_OP( 0x27, BodyApplyForceToCenter, RET_NONE, ARG( BODYID, body ) ARG( VEC3, force ) ARG( BOOL, wake ) )
B3_REC_OP( 0x28, BodyApplyTorque, RET_NONE, ARG( BODYID, body ) ARG( VEC3, torque ) ARG( BOOL, wake ) )
B3_REC_OP( 0x29, BodyApplyLinearImpulse, RET_NONE, ARG( BODYID, body ) ARG( VEC3, impulse ) ARG( POSITION, point ) ARG( BOOL, wake ) )
B3_REC_OP( 0x2A, BodyApplyLinearImpulseToCenter, RET_NONE, ARG( BODYID, body ) ARG( VEC3, impulse ) ARG( BOOL, wake ) )
B3_REC_OP( 0x2B, BodyApplyAngularImpulse, RET_NONE, ARG( BODYID, body ) ARG( VEC3, impulse ) ARG( BOOL, wake ) )
B3_REC_OP( 0x2C, BodySetMassData, RET_NONE, ARG( BODYID, body ) ARG( MASSDATA, massData ) )
B3_REC_OP( 0x2D, BodyApplyMassFromShapes, RET_NONE, ARG( BODYID, body ) )
B3_REC_OP( 0x2E, BodySetLinearDamping, RET_NONE, ARG( BODYID, body ) ARG( F32, damping ) )
B3_REC_OP( 0x2F, BodySetAngularDamping, RET_NONE, ARG( BODYID, body ) ARG( F32, damping ) )
B3_REC_OP( 0x30, BodySetGravityScale, RET_NONE, ARG( BODYID, body ) ARG( F32, scale ) )
B3_REC_OP( 0x31, BodySetAwake, RET_NONE, ARG( BODYID, body ) ARG( BOOL, awake ) )
B3_REC_OP( 0x32, BodyEnableSleep, RET_NONE, ARG( BODYID, body ) ARG( BOOL, flag ) )
B3_REC_OP( 0x33, BodySetSleepThreshold, RET_NONE, ARG( BODYID, body ) ARG( F32, threshold ) )
B3_REC_OP( 0x34, BodyDisable, RET_NONE, ARG( BODYID, body ) )
B3_REC_OP( 0x35, BodyEnable, RET_NONE, ARG( BODYID, body ) )
B3_REC_OP( 0x36, BodySetMotionLocks, RET_NONE, ARG( BODYID, body ) ARG( LOCKS, locks ) )
B3_REC_OP( 0x37, BodySetBullet, RET_NONE, ARG( BODYID, body ) ARG( BOOL, flag ) )
B3_REC_OP( 0x38, BodyEnableContactRecycling, RET_NONE, ARG( BODYID, body ) ARG( BOOL, flag ) )
B3_REC_OP( 0x39, BodyEnableHitEvents, RET_NONE, ARG( BODYID, body ) ARG( BOOL, flag ) )

// Shape create/destroy
B3_REC_OP( 0x40, CreateSphereShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( SPHERE, sphere ) )
B3_REC_OP( 0x41, CreateCapsuleShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( CAPSULE, capsule ) )
B3_REC_OP( 0x42, CreateHullShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( GEOMID, geometryId ) )
B3_REC_OP( 0x43, CreateMeshShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( GEOMID, geometryId ) ARG( VEC3, scale ) )
B3_REC_OP( 0x44, CreateHeightFieldShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( GEOMID, geometryId ) )
B3_REC_OP( 0x45, CreateCompoundShape, RET_SHAPEID, ARG( BODYID, body ) ARG( SHAPEDEF, def ) ARG( GEOMID, geometryId ) )
B3_REC_OP( 0x46, DestroyShape, RET_NONE, ARG( SHAPEID, shape ) ARG( BOOL, updateBodyMass ) )

// Shape mutators
B3_REC_OP( 0x50, ShapeSetDensity, RET_NONE, ARG( SHAPEID, shape ) ARG( F32, density ) ARG( BOOL, updateBodyMass ) )
B3_REC_OP( 0x51, ShapeSetFriction, RET_NONE, ARG( SHAPEID, shape ) ARG( F32, friction ) )
B3_REC_OP( 0x52, ShapeSetRestitution, RET_NONE, ARG( SHAPEID, shape ) ARG( F32, restitution ) )
B3_REC_OP( 0x53, ShapeSetSurfaceMaterial, RET_NONE, ARG( SHAPEID, shape ) ARG( MATERIAL, material ) )
B3_REC_OP( 0x54, ShapeSetFilter, RET_NONE, ARG( SHAPEID, shape ) ARG( FILTER, filter ) ARG( BOOL, invokeContacts ) )
B3_REC_OP( 0x55, ShapeEnableSensorEvents, RET_NONE, ARG( SHAPEID, shape ) ARG( BOOL, flag ) )
B3_REC_OP( 0x56, ShapeEnableContactEvents, RET_NONE, ARG( SHAPEID, shape ) ARG( BOOL, flag ) )
B3_REC_OP( 0x57, ShapeEnablePreSolveEvents, RET_NONE, ARG( SHAPEID, shape ) ARG( BOOL, flag ) )
B3_REC_OP( 0x58, ShapeEnableHitEvents, RET_NONE, ARG( SHAPEID, shape ) ARG( BOOL, flag ) )
B3_REC_OP( 0x59, ShapeSetSphere, RET_NONE, ARG( SHAPEID, shape ) ARG( SPHERE, sphere ) )
B3_REC_OP( 0x5A, ShapeSetCapsule, RET_NONE, ARG( SHAPEID, shape ) ARG( CAPSULE, capsule ) )
B3_REC_OP( 0x5B, ShapeApplyWind, RET_NONE,
		   ARG( SHAPEID, shape ) ARG( VEC3, wind ) ARG( F32, drag ) ARG( F32, lift ) ARG( F32, maxSpeed ) ARG( BOOL, wake ) )
B3_REC_OP( 0x5C, ShapeSetName, RET_NONE, ARG( SHAPEID, shape ) ARG( STR, name ) )

// Joint create and destroy
B3_REC_OP( 0x90, CreateParallelJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( PARALLELJOINTDEF, def ) )
B3_REC_OP( 0x91, CreateDistanceJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( DISTANCEJOINTDEF, def ) )
B3_REC_OP( 0x92, CreateFilterJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( FILTERJOINTDEF, def ) )
B3_REC_OP( 0x93, CreateMotorJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( MOTORJOINTDEF, def ) )
B3_REC_OP( 0x94, CreatePrismaticJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( PRISMATICJOINTDEF, def ) )
B3_REC_OP( 0x95, CreateRevoluteJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( REVOLUTEJOINTDEF, def ) )
B3_REC_OP( 0x96, CreateSphericalJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( SPHERICALJOINTDEF, def ) )
B3_REC_OP( 0x97, CreateWeldJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( WELDJOINTDEF, def ) )
B3_REC_OP( 0x98, CreateWheelJoint, RET_JOINTID, ARG( WORLDID, world ) ARG( WHEELJOINTDEF, def ) )
B3_REC_OP( 0x99, DestroyJoint, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, wakeAttached ) )

// Generic joint mutators
B3_REC_OP( 0x9A, JointSetLocalFrameA, RET_NONE, ARG( JOINTID, joint ) ARG( TRANSFORM, localFrame ) )
B3_REC_OP( 0x9B, JointSetLocalFrameB, RET_NONE, ARG( JOINTID, joint ) ARG( TRANSFORM, localFrame ) )
B3_REC_OP( 0x9C, JointSetCollideConnected, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, shouldCollide ) )
B3_REC_OP( 0x9D, JointWakeBodies, RET_NONE, ARG( JOINTID, joint ) )
B3_REC_OP( 0x9E, JointSetConstraintTuning, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0x9F, JointSetForceThreshold, RET_NONE, ARG( JOINTID, joint ) ARG( F32, threshold ) )
B3_REC_OP( 0xA0, JointSetTorqueThreshold, RET_NONE, ARG( JOINTID, joint ) ARG( F32, threshold ) )

// Parallel joint
B3_REC_OP( 0xA1, ParallelJointSetSpringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xA2, ParallelJointSetSpringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xA3, ParallelJointSetMaxTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, maxTorque ) )

// Distance joint
B3_REC_OP( 0xA4, DistanceJointSetLength, RET_NONE, ARG( JOINTID, joint ) ARG( F32, length ) )
B3_REC_OP( 0xA5, DistanceJointEnableSpring, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableSpring ) )
B3_REC_OP( 0xA6, DistanceJointSetSpringForceRange, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lowerForce ) ARG( F32, upperForce ) )
B3_REC_OP( 0xA7, DistanceJointSetSpringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xA8, DistanceJointSetSpringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xA9, DistanceJointEnableLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableLimit ) )
B3_REC_OP( 0xAA, DistanceJointSetLengthRange, RET_NONE, ARG( JOINTID, joint ) ARG( F32, minLength ) ARG( F32, maxLength ) )
B3_REC_OP( 0xAB, DistanceJointEnableMotor, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableMotor ) )
B3_REC_OP( 0xAC, DistanceJointSetMotorSpeed, RET_NONE, ARG( JOINTID, joint ) ARG( F32, motorSpeed ) )
B3_REC_OP( 0xAD, DistanceJointSetMaxMotorForce, RET_NONE, ARG( JOINTID, joint ) ARG( F32, force ) )

// Motor joint
B3_REC_OP( 0xAE, MotorJointSetLinearVelocity, RET_NONE, ARG( JOINTID, joint ) ARG( VEC3, velocity ) )
B3_REC_OP( 0xAF, MotorJointSetAngularVelocity, RET_NONE, ARG( JOINTID, joint ) ARG( VEC3, velocity ) )
B3_REC_OP( 0xB0, MotorJointSetMaxVelocityForce, RET_NONE, ARG( JOINTID, joint ) ARG( F32, maxForce ) )
B3_REC_OP( 0xB1, MotorJointSetMaxVelocityTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, maxTorque ) )
B3_REC_OP( 0xB2, MotorJointSetLinearHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xB3, MotorJointSetLinearDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, damping ) )
B3_REC_OP( 0xB4, MotorJointSetAngularHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xB5, MotorJointSetAngularDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, damping ) )
B3_REC_OP( 0xB6, MotorJointSetMaxSpringForce, RET_NONE, ARG( JOINTID, joint ) ARG( F32, maxForce ) )
B3_REC_OP( 0xB7, MotorJointSetMaxSpringTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, maxTorque ) )

// Prismatic joint
B3_REC_OP( 0xB8, PrismaticJointEnableSpring, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableSpring ) )
B3_REC_OP( 0xB9, PrismaticJointSetSpringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xBA, PrismaticJointSetSpringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xBB, PrismaticJointSetTargetTranslation, RET_NONE, ARG( JOINTID, joint ) ARG( F32, translation ) )
B3_REC_OP( 0xBC, PrismaticJointEnableLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableLimit ) )
B3_REC_OP( 0xBD, PrismaticJointSetLimits, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lower ) ARG( F32, upper ) )
B3_REC_OP( 0xBE, PrismaticJointEnableMotor, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableMotor ) )
B3_REC_OP( 0xBF, PrismaticJointSetMotorSpeed, RET_NONE, ARG( JOINTID, joint ) ARG( F32, motorSpeed ) )
B3_REC_OP( 0xC0, PrismaticJointSetMaxMotorForce, RET_NONE, ARG( JOINTID, joint ) ARG( F32, force ) )

// Revolute joint
B3_REC_OP( 0xC1, RevoluteJointEnableSpring, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableSpring ) )
B3_REC_OP( 0xC2, RevoluteJointSetSpringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xC3, RevoluteJointSetSpringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xC4, RevoluteJointSetTargetAngle, RET_NONE, ARG( JOINTID, joint ) ARG( F32, angle ) )
B3_REC_OP( 0xC5, RevoluteJointEnableLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableLimit ) )
B3_REC_OP( 0xC6, RevoluteJointSetLimits, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lower ) ARG( F32, upper ) )
B3_REC_OP( 0xC7, RevoluteJointEnableMotor, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableMotor ) )
B3_REC_OP( 0xC8, RevoluteJointSetMotorSpeed, RET_NONE, ARG( JOINTID, joint ) ARG( F32, motorSpeed ) )
B3_REC_OP( 0xC9, RevoluteJointSetMaxMotorTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, torque ) )

// Spherical joint
B3_REC_OP( 0xCA, SphericalJointEnableConeLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableLimit ) )
B3_REC_OP( 0xCB, SphericalJointSetConeLimit, RET_NONE, ARG( JOINTID, joint ) ARG( F32, angleRadians ) )
B3_REC_OP( 0xCC, SphericalJointEnableTwistLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableLimit ) )
B3_REC_OP( 0xCD, SphericalJointSetTwistLimits, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lower ) ARG( F32, upper ) )
B3_REC_OP( 0xCE, SphericalJointEnableSpring, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableSpring ) )
B3_REC_OP( 0xCF, SphericalJointSetSpringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xD0, SphericalJointSetSpringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xD1, SphericalJointSetTargetRotation, RET_NONE, ARG( JOINTID, joint ) ARG( QUAT, targetRotation ) )
B3_REC_OP( 0xD2, SphericalJointEnableMotor, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, enableMotor ) )
B3_REC_OP( 0xD3, SphericalJointSetMotorVelocity, RET_NONE, ARG( JOINTID, joint ) ARG( VEC3, motorVelocity ) )
B3_REC_OP( 0xD4, SphericalJointSetMaxMotorTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, torque ) )

// Weld joint
B3_REC_OP( 0xD5, WeldJointSetLinearHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xD6, WeldJointSetLinearDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xD7, WeldJointSetAngularHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xD8, WeldJointSetAngularDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )

// Wheel joint
B3_REC_OP( 0xD9, WheelJointEnableSuspension, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, flag ) )
B3_REC_OP( 0xDA, WheelJointSetSuspensionHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xDB, WheelJointSetSuspensionDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xDC, WheelJointEnableSuspensionLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, flag ) )
B3_REC_OP( 0xDD, WheelJointSetSuspensionLimits, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lower ) ARG( F32, upper ) )
B3_REC_OP( 0xDE, WheelJointEnableSpinMotor, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, flag ) )
B3_REC_OP( 0xDF, WheelJointSetSpinMotorSpeed, RET_NONE, ARG( JOINTID, joint ) ARG( F32, speed ) )

// Wheel joint continued, overflow past the 0xDF range.
B3_REC_OP( 0xE0, WheelJointSetMaxSpinTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, torque ) )
B3_REC_OP( 0xE1, WheelJointEnableSteering, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, flag ) )
B3_REC_OP( 0xE2, WheelJointSetSteeringHertz, RET_NONE, ARG( JOINTID, joint ) ARG( F32, hertz ) )
B3_REC_OP( 0xE3, WheelJointSetSteeringDampingRatio, RET_NONE, ARG( JOINTID, joint ) ARG( F32, dampingRatio ) )
B3_REC_OP( 0xE4, WheelJointSetMaxSteeringTorque, RET_NONE, ARG( JOINTID, joint ) ARG( F32, torque ) )
B3_REC_OP( 0xE5, WheelJointEnableSteeringLimit, RET_NONE, ARG( JOINTID, joint ) ARG( BOOL, flag ) )
B3_REC_OP( 0xE6, WheelJointSetSteeringLimits, RET_NONE, ARG( JOINTID, joint ) ARG( F32, lower ) ARG( F32, upper ) )
B3_REC_OP( 0xE7, WheelJointSetTargetSteeringAngle, RET_NONE, ARG( JOINTID, joint ) ARG( F32, radians ) )

// Spatial queries. Inputs flow through the manifest (reader side). The hit tail and result are
// hand-written in recording.c / recording_replay.c since they are variable length.
B3_REC_OP( 0xE8, QueryOverlapAABB, RET_NONE, ARG( WORLDID, world ) ARG( AABB, aabb ) ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xE9, QueryOverlapShape, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( SHAPEPROXY, proxy ) ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xEA, QueryCastRay, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( VEC3, translation ) ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xEB, QueryCastShape, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( SHAPEPROXY, proxy ) ARG( VEC3, translation )
			   ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xEC, QueryCastRayClosest, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( VEC3, translation ) ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xED, QueryCastMover, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( CAPSULE, mover ) ARG( VEC3, translation ) ARG( QUERYFILTER, filter ) )
B3_REC_OP( 0xEE, QueryCollideMover, RET_NONE,
		   ARG( WORLDID, world ) ARG( POSITION, origin ) ARG( CAPSULE, mover ) ARG( QUERYFILTER, filter ) )

// Identity key (hash of the caller id + label) for the query that immediately follows. Emitted only
// for a tagged query. The id and label are interned in the trailing tag table, so only the 8 byte key
// rides the stream.
B3_REC_OP( 0xEF, QueryTag, RET_NONE, ARG( U64, key ) )

B3_REC_OP( 0xF1, StateHash, RET_NONE, ARG( WORLDID, world ) ARG( U64, hash ) )

// Accumulated world bounds over the whole recording, written once at stop.
B3_REC_OP( 0xF2, RecordingBounds, RET_NONE, ARG( AABB, bounds ) )
