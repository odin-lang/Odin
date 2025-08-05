package vendor_box2d

import "base:intrinsics"
import "core:c"

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	@(private) VECTOR_EXT :: "_simd" when #config(VENDOR_BOX2D_ENABLE_SIMD128, intrinsics.has_target_feature("simd128")) else ""
} else {
	@(private) VECTOR_EXT :: "avx2" when #config(VENDOR_BOX2D_ENABLE_AVX2, intrinsics.has_target_feature("avx2")) else "sse2"
}

when ODIN_OS == .Windows {
	@(private) LIB_PATH :: "lib/box2d_windows_amd64_" + VECTOR_EXT + ".lib"
} else when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 {
	@(private) LIB_PATH :: "lib/box2d_darwin_arm64.a"
} else when ODIN_OS == .Darwin {
	@(private) LIB_PATH :: "lib/box2d_darwin_amd64_" + VECTOR_EXT + ".a"
} else when ODIN_ARCH == .amd64 {
	@(private) LIB_PATH :: "lib/box2d_other_amd64_" + VECTOR_EXT + ".a"
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	@(private) LIB_PATH :: "lib/box2d_wasm" + VECTOR_EXT + ".o"
} else {
	@(private) LIB_PATH :: "lib/box2d_other.a"
}

when !#exists(LIB_PATH) {
	#panic("Could not find the compiled box2d libraries at \"" + LIB_PATH + "\", they can be compiled by running the `build_box2d.sh` script at `" + ODIN_ROOT + "vendor/box2d/build_box2d.sh\"`")
}

foreign import lib {
	LIB_PATH,
}


// Prototype for user allocation function
//	@param size the allocation size in bytes
//	@param alignment the required alignment, guaranteed to be a power of 2
AllocFcn :: #type proc "c" (size: u32, alignment: i32) -> rawptr

// Prototype for user free function
//	@param mem the memory previously allocated through `b2AllocFcn`
FreeFcn :: #type proc "c" (mem: rawptr)

// Prototype for the user assert callback. Return 0 to skip the debugger break.
AssertFcn :: #type proc "c" (condition, file_name: cstring, line_number: i32) -> i32

// Version numbering scheme.
//
// See https://semver.org/
Version :: struct {
	major:    i32, // Significant changes
	minor:    i32, // Incremental changes
	revision: i32, // Bug fixes
}

HASH_INIT :: 5381

@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// This allows the user to override the allocation functions. These should be
	//	set during application startup.
	SetAllocator :: proc(allocFcn: AllocFcn, freefcn: FreeFcn) ---
	// @return the total bytes allocated by Box2D
	GetByteCount :: proc() -> c.int ---
	// Override the default assert callback
	//	@param assertFcn a non-null assert callback
	SetAssertFcn :: proc(assertfcn: AssertFcn) ---

	// Get the absolute number of system ticks. The value is platform specific.
	GetTicks                :: proc() -> u64 ---
	// Get the milliseconds passed from an initial tick value.
	GetMilliseconds         :: proc(ticks: u64) -> f32 ---
	// Get the milliseconds passed from an initial tick value. Resets the passed in
	// value to the current tick value.
	GetMillisecondsAndReset :: proc(ticks: ^u64) -> f32 ---
	// Yield to be used in a busy loop.
	Yield                   :: proc() ---

	// Simple djb2 hash function for determinism testing.
	Hash :: proc(hash: u32, data: [^]byte, count: c.int) -> u32 ---

	// Box2D bases all length units on meters, but you may need different units for your game.
	// You can set this value to use different units. This should be done at application startup
	// and only modified once. Default value is 1.
	// For example, if your game uses pixels for units you can use pixels for all length values
	// sent to Box2D. There should be no extra cost. However, Box2D has some internal tolerances
	// and thresholds that have been tuned for meters. By calling this function, Box2D is able
	// to adjust those tolerances and thresholds to improve accuracy.
	// A good rule of thumb is to pass the height of your player character to this function. So
	// if your player character is 32 pixels high, then pass 32 to this function. Then you may
	// confidently use pixels for all the length values sent to Box2D. All length values returned
	// from Box2D will also be pixels because Box2D does not do any scaling internally.
	// However, you are now on the hook for coming up with good values for gravity, density, and
	// forces.
	// @warning This must be modified before any calls to Box2D
	SetLengthUnitsPerMeter :: proc(lengthUnits: f32) ---

	// Get the current length units per meter.
	GetLengthUnitsPerMeter :: proc() -> f32 ---
}

@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Use this to initialize your world definition
	// @ingroup world
	DefaultWorldDef          :: proc() -> WorldDef ---

	// Use this to initialize your body definition
	// @ingroup body
	DefaultBodyDef           :: proc() -> BodyDef ---

	// Use this to initialize your filter
	// @ingroup shape
	DefaultFilter            :: proc() -> Filter ---

	// Use this to initialize your query filter
	// @ingroup shape
	DefaultQueryFilter       :: proc() -> QueryFilter ---

	// Use this to initialize your surface material
	// @ingroup shape
	DefaultSurfaceMaterial   :: proc() -> SurfaceMaterial ---

	// Use this to initialize your shape definition
	// @ingroup shape
	DefaultShapeDef          :: proc() -> ShapeDef ---

	// Use this to initialize your chain definition
	// @ingroup shape
	DefaultChainDef          :: proc() -> ChainDef ---

	// Use this to initialize your joint definition
	// @ingroup distance_joint
	DefaultDistanceJointDef  :: proc() -> DistanceJointDef ---

	// Use this to initialize your joint definition
	// @ingroup motor_joint
	DefaultMotorJointDef     :: proc() -> MotorJointDef ---

	// Use this to initialize your joint definition
	// @ingroup mouse_joint
	DefaultMouseJointDef     :: proc() -> MouseJointDef ---

	// Use this to initialize your joint definition
	// @ingroup filter_joint
	DefaultFilterJointDef    :: proc() -> FilterJointDef ---

	// Use this to initialize your joint definition
	// @ingroupd prismatic_joint
	DefaultPrismaticJointDef :: proc() -> PrismaticJointDef ---

	// Use this to initialize your joint definition.
	// @ingroup revolute_joint
	DefaultRevoluteJointDef  :: proc() -> RevoluteJointDef ---

	// Use this to initialize your joint definition
	// @ingroup weld_joint
	DefaultWeldJointDef      :: proc() -> WeldJointDef ---

	// Use this to initialize your joint definition
	// @ingroup wheel_joint
	DefaultWheelJointDef     :: proc() -> WheelJointDef ---

	// Use this to initialize your explosion definition
	// @ingroup world
	DefaultExplosionDef      :: proc() -> ExplosionDef ---

	// Use this to initialize your drawing interface. This allows you to implement a sub-set
	// of the drawing functions.
	DefaultDebugDraw         :: proc() -> DebugDraw ---
}



@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Validate ray cast input data (NaN, etc)
	IsValidRay               :: proc(#by_ptr input: RayCastInput) -> bool ---

	// Make a convex polygon from a convex hull. This will assert if the hull is not valid.
	// @warning Do not manually fill in the hull data, it must come directly from b2ComputeHull
	MakePolygon              :: proc(#by_ptr hull: Hull, radius: f32) -> Polygon ---

	// Make an offset convex polygon from a convex hull. This will assert if the hull is not valid.
	// @warning Do not manually fill in the hull data, it must come directly from b2ComputeHull
	MakeOffsetPolygon        :: proc(#by_ptr hull: Hull, position: Vec2, rotation: Rot) -> Polygon ---

	// Make an offset convex polygon from a convex hull. This will assert if the hull is not valid.
	// @warning Do not manually fill in the hull data, it must come directly from b2ComputeHull
	MakeOffsetRoundedPolygon :: proc(#by_ptr hull: Hull, position: Vec2, rotation: Rot, radius: f32) -> Polygon ---

	// Make a square polygon, bypassing the need for a convex hull.
	MakeSquare               :: proc(halfWidth: f32) -> Polygon ---

	// Make a box (rectangle) polygon, bypassing the need for a convex hull.
	MakeBox                  :: proc(halfWidth, halfHeight: f32) -> Polygon ---

	// Make a rounded box, bypassing the need for a convex hull.
	MakeRoundedBox           :: proc(halfWidth, halfHeight: f32, radius: f32) -> Polygon ---

	// Make an offset box, bypassing the need for a convex hull.
	MakeOffsetBox            :: proc(halfWidth, halfHeight: f32, center: Vec2, rotation: Rot) -> Polygon ---

	// Make an offset rounded box, bypassing the need for a convex hull.
	MakeOffsetRoundedBox     :: proc(halfWidth, halfHeight: f32, center: Vec2, rotation: Rot, radius: f32) -> Polygon ---

	// Transform a polygon. This is useful for transferring a shape from one body to another.
	TransformPolygon         :: proc(transform: Transform, #by_ptr polygon: Polygon) -> Polygon ---

	// Compute mass properties of a circle
	ComputeCircleMass        :: proc(#by_ptr shape: Circle, density: f32) -> MassData ---

	// Compute mass properties of a capsule
	ComputeCapsuleMass       :: proc(#by_ptr shape: Capsule, density: f32) -> MassData ---

	// Compute mass properties of a polygon
	ComputePolygonMass       :: proc(#by_ptr shape: Polygon, density: f32) -> MassData ---

	// Compute the bounding box of a transformed circle
	ComputeCircleAABB        :: proc(#by_ptr shape: Circle, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed capsule
	ComputeCapsuleAABB       :: proc(#by_ptr shape: Capsule, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed polygon
	ComputePolygonAABB       :: proc(#by_ptr shape: Polygon, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed line segment
	ComputeSegmentAABB       :: proc(#by_ptr shape: Segment, transform: Transform) -> AABB ---

	// Test a point for overlap with a circle in local space
	PointInCircle            :: proc(point: Vec2, #by_ptr shape: Circle) -> bool ---

	// Test a point for overlap with a capsule in local space
	PointInCapsule           :: proc(point: Vec2, #by_ptr shape: Capsule) -> bool ---

	// Test a point for overlap with a convex polygon in local space
	PointInPolygon           :: proc(point: Vec2, #by_ptr shape: Polygon) -> bool ---

	// Ray cast versus circle in shape local space. Initial overlap is treated as a miss.
	RayCastCircle            :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Circle) -> CastOutput ---

	// Ray cast versus capsule in shape local space. Initial overlap is treated as a miss.
	RayCastCapsule           :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Capsule) -> CastOutput ---

	// Ray cast versus segment in shape local space. Optionally treat the segment as one-sided with hits from
	// the left side being treated as a miss.
	RayCastSegment           :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Segment, oneSided: bool) -> CastOutput ---

	// Ray cast versus polygon in shape local space. Initial overlap is treated as a miss.
	RayCastPolygon           :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Polygon) -> CastOutput ---

	// Shape cast versus a circle. Initial overlap is treated as a miss.
	ShapeCastCircle          :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Circle) -> CastOutput ---

	// Shape cast versus a capsule. Initial overlap is treated as a miss.
	ShapeCastCapsule         :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Capsule) -> CastOutput ---

	// Shape cast versus a line segment. Initial overlap is treated as a miss.
	ShapeCastSegment         :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Segment) -> CastOutput ---

	// Shape cast versus a convex polygon. Initial overlap is treated as a miss.
	ShapeCastPolygon         :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Polygon) -> CastOutput ---
}


// Compute the convex hull of a set of points. Returns an empty hull if it fails.
// Some failure cases:
// - all points very close together
// - all points on a line
// - less than 3 points
// - more than MAX_POLYGON_VERTICES points
// This welds close points and removes collinear points.
//	@warning Do not modify a hull once it has been computed
@(require_results)
ComputeHull :: proc "c" (points: []Vec2) -> Hull {
	foreign lib {
		b2ComputeHull :: proc "c" (points: [^]Vec2, count: i32) -> Hull ---
	}
	return b2ComputeHull(raw_data(points), i32(len(points)))
}


@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// This determines if a hull is valid. Checks for:
	// - convexity
	// - collinear points
	// This is expensive and should not be called at runtime.
	ValidateHull :: proc(#by_ptr hull: Hull) -> bool ---
}

@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Compute the distance between two line segments, clamping at the end points if needed.
	SegmentDistance :: proc(p1, q1: Vec2, p2, q2: Vec2) -> SegmentDistanceResult ---
}

// Compute the closest points between two shapes represented as point clouds.
// SimplexCache cache is input/output. On the first call set SimplexCache.count to zero.
//	The underlying GJK algorithm may be debugged by passing in debug simplexes and capacity. You may pass in NULL and 0 for these.
@(require_results)
ShapeDistance :: proc "c" (#by_ptr input: DistanceInput, cache: ^SimplexCache, simplexes: []Simplex) -> DistanceOutput {
	foreign lib {
		b2ShapeDistance :: proc "c" (#by_ptr input: DistanceInput, cache: ^SimplexCache, simplexes: [^]Simplex, simplexCapacity: c.int) -> DistanceOutput ---
	}
	return b2ShapeDistance(input, cache, raw_data(simplexes), i32(len(simplexes)))
}


// Make a proxy for use in overlap, shape cast, and related functions. This is a deep copy of the points.
@(require_results)
MakeProxy :: proc "c" (points: []Vec2, radius: f32) -> ShapeProxy {
	foreign lib {
		b2MakeProxy :: proc "c" (points: [^]Vec2, count: i32, radius: f32) -> ShapeProxy ---
	}
	return b2MakeProxy(raw_data(points), i32(len(points)), radius)
}

// Make a proxy with a transform. This is a deep copy of the points.
@(require_results)
MakeOffsetProxy :: proc "c" (points: []Vec2, radius: f32, position: Vec2, rotation: Rot) -> ShapeProxy {
	foreign lib {
		b2MakeOffsetProxy :: proc "c" (points: [^]Vec2, count: i32, radius: f32, position: Vec2, rotation: Rot) -> ShapeProxy ---
	}
	return b2MakeOffsetProxy(raw_data(points), i32(len(points)), radius, position, rotation)
}


@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Perform a linear shape cast of shape B moving and shape A fixed. Determines the hit point, normal, and translation fraction.
	// You may optionally supply an array to hold debug data.
	ShapeCast :: proc(#by_ptr input: ShapeCastPairInput) -> CastOutput ---

	// Evaluate the transform sweep at a specific time.
	GetSweepTransform :: proc(#by_ptr sweep: Sweep, time: f32) -> Transform ---

	// Compute the upper bound on time before two shapes penetrate. Time is represented as
	// a fraction between [0,tMax]. This uses a swept separating axis and may miss some intermediate,
	// non-tunneling collisions. If you change the time interval, you should call this function
	// again.
	TimeOfImpact :: proc(#by_ptr input: TOIInput) -> TOIOutput ---
}

@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Compute the contact manifold between two circles
	CollideCircles                 :: proc(#by_ptr circleA: Circle, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a capsule and circle
	CollideCapsuleAndCircle        :: proc(#by_ptr capsuleA: Capsule, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a circle
	CollideSegmentAndCircle        :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a polygon and a circle
	CollidePolygonAndCircle        :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a capsule and circle
	CollideCapsules                :: proc(#by_ptr capsuleA: Capsule, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a capsule
	CollideSegmentAndCapsule       :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a polygon and capsule
	CollidePolygonAndCapsule       :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between two polygons
	CollidePolygons                :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a polygon
	CollideSegmentAndPolygon       :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a chain segment and a circle
	CollideChainSegmentAndCircle  :: proc(#by_ptr segmentA: ChainSegment, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a capsule
	CollideChainSegmentAndCapsule :: proc(#by_ptr segmentA: ChainSegment, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform, cache: ^SimplexCache) -> Manifold ---

	// Compute the contact manifold between a chain segment and a rounded polygon
	CollideChainSegmentAndPolygon :: proc(#by_ptr segmentA: ChainSegment, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform, cache: ^SimplexCache) -> Manifold ---
}



@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Constructing the tree initializes the node pool.
	DynamicTree_Create          :: proc() -> DynamicTree ---

	// Destroy the tree, freeing the node pool.
	DynamicTree_Destroy         :: proc(tree: ^DynamicTree) ---

	// Create a proxy. Provide an AABB and a userData value.
	DynamicTree_CreateProxy     :: proc(tree: ^DynamicTree, aabb: AABB, categoryBits: u64, userData: u64) -> i32 ---

	// Destroy a proxy. This asserts if the id is invalid.
	DynamicTree_DestroyProxy    :: proc(tree: ^DynamicTree, proxyId: i32) ---

	// Move a proxy to a new AABB by removing and reinserting into the tree.
	DynamicTree_MoveProxy       :: proc(tree: ^DynamicTree, proxyId: i32, aabb: AABB) ---

	// Enlarge a proxy and enlarge ancestors as necessary.
	DynamicTree_EnlargeProxy    :: proc(tree: ^DynamicTree, proxyId: i32, aabb: AABB) ---

	// Modify the category bits on a proxy. This is an expensive operation.
	DynamicTree_SetCategoryBits :: proc(tree: ^DynamicTree, proxyId: i32, categoryBits: u64) ---

	// Get the category bits on a proxy.
	DynamicTree_GetCategoryBits :: proc(tree: ^DynamicTree, proxyId: i32) ---

	// Query an AABB for overlapping proxies. The callback class is called for each proxy that overlaps the supplied AABB.
	//	@return performance data
	DynamicTree_Query           :: proc(#by_ptr tree: DynamicTree, aabb: AABB, maskBits: u64, callback: TreeQueryCallbackFcn, ctx: rawptr) -> TreeStats ---

	// Ray cast against the proxies in the tree. This relies on the callback
	// to perform a exact ray cast in the case were the proxy contains a shape.
	// The callback also performs the any collision filtering. This has performance
	// roughly equal to k * log(n), where k is the number of collisions and n is the
	// number of proxies in the tree.
	// Bit-wise filtering using mask bits can greatly improve performance in some scenarios.
	//	However, this filtering may be approximate, so the user should still apply filtering to results.
	// @param tree the dynamic tree to ray cast
	// @param input the ray cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1)
	// @param maskBits mask bit hint: `bool accept = (maskBits & node->categoryBits) != 0;`
	// @param callback a callback class that is called for each proxy that is hit by the ray
	// @param context user context that is passed to the callback
	//	@return performance data
	DynamicTree_RayCast         :: proc(#by_ptr tree: DynamicTree, #by_ptr input: RayCastInput, maskBits: u64, callback: TreeRayCastCallbackFcn, ctx: rawptr) -> TreeStats ---

	// Ray cast against the proxies in the tree. This relies on the callback
	// to perform a exact ray cast in the case were the proxy contains a shape.
	// The callback also performs the any collision filtering. This has performance
	// roughly equal to k * log(n), where k is the number of collisions and n is the
	// number of proxies in the tree.
	//	@param tree the dynamic tree to ray cast
	// @param input the ray cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1).
	//	@param maskBits filter bits: `bool accept = (maskBits & node->categoryBits) != 0 ---`
	// @param callback a callback class that is called for each proxy that is hit by the shape
	//	@param context user context that is passed to the callback
	//	@return performance data
	DynamicTree_ShapeCast       :: proc(#by_ptr tree: DynamicTree, #by_ptr input: ShapeCastInput, maskBits: u32, callback: TreeShapeCastCallbackFcn, ctx: rawptr) -> TreeStats ---

	// Get the height of the binary tree.
	DynamicTree_GetHeight       :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Get the ratio of the sum of the node areas to the root area.
	DynamicTree_GetAreaRatio    :: proc(#by_ptr tree: DynamicTree) -> f32 ---

	// Get the bounding box that contains the entire tree
	DynamicTree_GetRootBounds   :: proc(#by_ptr tree: DynamicTree) -> AABB ---

	// Get the number of proxies created
	DynamicTree_GetProxyCount   :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
	DynamicTree_Rebuild         :: proc(tree: ^DynamicTree, fullBuild: bool) -> c.int ---

	// Get the number of bytes used by this tree
	DynamicTree_GetByteCount    :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Get proxy user data
	DynamicTree_GetUserData     :: proc(#by_ptr tree: DynamicTree, proxyId: c.int) -> u64 ---

	// Get the AABB of a proxy
	DynamicTree_GetAABB         :: proc(#by_ptr tree: DynamicTree, proxyId: c.int) -> AABB ---

	// Validate this tree. For testing.
	DynamicTree_Validate           :: proc(#by_ptr tree: DynamicTree) ---

	// Validate this tree has no enlarged AABBs. For testing.
	DynamicTree_ValidateNoEnlarged :: proc(#by_ptr tree: DynamicTree) ---
}

/**
 * @defgroup character Character mover
 * Character movement solver
 * @{
 */

@(require_results)
SolvePlanes :: proc(position: Vec2, planes: []CollisionPlane) -> PlaneSolverResult {
	foreign lib {
		b2SolvePlanes :: proc "c" (position: Vec2, planes: [^]CollisionPlane, count: i32) -> PlaneSolverResult ---
	}

	return b2SolvePlanes(position, raw_data(planes), i32(len(planes)))
}

@(require_results)
ClipVector :: proc(vector: Vec2, planes: []CollisionPlane) -> Vec2 {
	foreign lib {
		b2ClipVector :: proc "c" (vector: Vec2, planes: [^]CollisionPlane, count: i32) -> Vec2 ---
	}

	return b2ClipVector(vector, raw_data(planes), i32(len(planes)))
}

/**@}*/


@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	/**
	 * @defgroup world World
	 * These functions allow you to create a simulation world.
	 *
	 * You can add rigid bodies and joint constraints to the world and run the simulation. You can get contact
	 * information to get contact points and normals as well as events. You can query to world, checking for overlaps and casting rays
	 * or shapes. There is also debugging information such as debug draw, timing information, and counters. You can find documentation
	 * here: https://box2d.org/
	 */

	// Create a world for rigid body simulation. A world contains bodies, shapes, and constraints. You make create
	//	up to 128 worlds. Each world is completely independent and may be simulated in parallel.
	//	@return the world id.
	CreateWorld                   :: proc(#by_ptr def: WorldDef) -> WorldId ---

	// Destroy a world
	DestroyWorld                  :: proc(worldId: WorldId) ---

	// World id validation. Provides validation for up to 64K allocations.
	World_IsValid                 :: proc(id: WorldId) -> bool ---

	// Simulate a world for one time step. This performs collision detection, integration, and constraint solution.
	// @param worldId The world to simulate
	// @param timeStep The amount of time to simulate, this should be a fixed number. Usually 1/60.
	// @param subStepCount The number of sub-steps, increasing the sub-step count can increase accuracy. Usually 4.
	World_Step                    :: proc(worldId: WorldId, timeStep: f32 , subStepCount: c.int) ---

	// Call this to draw shapes and other debug draw data
	World_Draw                    :: proc(worldId: WorldId, draw: ^DebugDraw) ---

	// Get the body events for the current time step. The event data is transient. Do not store a reference to this data.
	World_GetBodyEvents           :: proc(worldId: WorldId) -> BodyEvents ---

	// Get sensor events for the current time step. The event data is transient. Do not store a reference to this data.
	World_GetSensorEvents         :: proc(worldId: WorldId) -> SensorEvents ---

	// Get contact events for this current time step. The event data is transient. Do not store a reference to this data.
	World_GetContactEvents        :: proc(worldId: WorldId) -> ContactEvents ---

	// Overlap test for all shapes that *potentially* overlap the provided AABB
	World_OverlapAABB             :: proc(worldId: WorldId, aabb: AABB, filter: QueryFilter, fcn: OverlapResultFcn, ctx: rawptr) -> TreeStats ---

	// Overlap test for all shapes that overlap the provided shape proxy.
	World_OverlapShape            :: proc(worldId: WorldId, #by_ptr proxy: ShapeProxy, filter: QueryFilter, fcn: OverlapResultFcn, ctx: rawptr) -> TreeStats ---

	// Cast a ray into the world to collect shapes in the path of the ray.
	// Your callback function controls whether you get the closest point, any point, or n-points.
	// The ray-cast ignores shapes that contain the starting point.
	//	@note The callback function may receive shapes in any order
	//	@param worldId The world to cast the ray against
	//	@param origin The start point of the ray
	//	@param translation The translation of the ray from the start point to the end point
	//	@param filter Contains bit flags to filter unwanted shapes from the results
	//	@param fcn A user implemented callback function
	//	@param context A user context that is passed along to the callback function
	//	@return traversal performance counters
	World_CastRay                 :: proc(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter, fcn: CastResultFcn, ctx: rawptr) -> TreeStats ---

	// Cast a ray into the world to collect the closest hit. This is a convenience function.
	// This is less general than b2World_CastRay() and does not allow for custom filtering.
	World_CastRayClosest          :: proc(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter) -> RayResult ---

	// Cast a shape through the world. Similar to a cast ray except that a shape is cast instead of a point.
	// @see World_CastRay
	World_CastShape               :: proc(worldId: WorldId, #by_ptr shape: ShapeProxy, translation: Vec2, filter: QueryFilter, fcn: CastResultFcn, ctx: rawptr) -> TreeStats ---

	// Cast a capsule mover through the world. This is a special shape cast that handles sliding along other shapes while reducing
	// clipping.
	World_CastMover               :: proc(worldId: WorldId, #by_ptr mover: Capsule, translation: Vec2, filter: QueryFilter) -> f32 ---

	// Collide a capsule mover with the world, gathering collision planes that can be fed to b2SolvePlanes. Useful for
	// kinematic character movement.
	World_CollideMover            :: proc(worldId: WorldId, #by_ptr mover: Capsule, filter: QueryFilter, fcn: PlaneResultFcn, ctx: rawptr) ---

	// Enable/disable sleep. If your application does not need sleeping, you can gain some performance
	//	by disabling sleep completely at the world level.
	//	@see WorldDef
	World_EnableSleeping          :: proc(worldId: WorldId, flag: bool) ---

	// Is body sleeping enabled?
	World_IsSleepingEnabled       :: proc(worldId: WorldId) -> bool ---

	// Enable/disable continuous collision between dynamic and static bodies. Generally you should keep continuous
	// collision enabled to prevent fast moving objects from going through static objects. The performance gain from
	//	disabling continuous collision is minor.
	//	@see WorldDef
	World_EnableContinuous        :: proc(worldId: WorldId, flag: bool) ---

	// Is continuous collision enabled?
	World_IsContinuousEnabled     :: proc(worldId: WorldId) -> bool ---

	// Adjust the restitution threshold. It is recommended not to make this value very small
	//	because it will prevent bodies from sleeping. Usually in meters per second.
	//	@see WorldDef
	World_SetRestitutionThreshold :: proc(worldId: WorldId, value: f32) ---

	// Get the restitution speed threshold. Usually in meters per second.
	World_GetRestitutionThreshold :: proc(worldId: WorldId) -> f32 ---

	// Adjust the hit event threshold. This controls the collision velocity needed to generate a b2ContactHitEvent.
	// Usually in meters per second.
	//	@see WorldDef::hitEventThreshold
	World_SetHitEventThreshold    :: proc(worldId: WorldId, value: f32) ---

	// Get the hit event speed threshold. Usually in meters per second.
	World_GetHitEventThreshold    :: proc(worldId: WorldId) -> f32 ---

	// Register the custom filter callback. This is optional.
	World_SetCustomFilterCallback :: proc(worldId: WorldId, fcn: CustomFilterFcn, ctx: rawptr) ---

	// Register the pre-solve callback. This is optional.
	World_SetPreSolveCallback     :: proc(worldId: WorldId, fcn: PreSolveFcn, ctx: rawptr) ---

	// Set the gravity vector for the entire world. Box2D has no concept of an up direction and this
	// is left as a decision for the application. Usually in m/s^2.
	//	@see WorldDef
	World_SetGravity              :: proc(worldId: WorldId, gravity: Vec2) ---

	// Get the gravity vector
	World_GetGravity              :: proc(worldId: WorldId) -> Vec2 ---

	// Apply a radial explosion
	//	@param worldId The world id
	//	@param explosionDef The explosion definition
	World_Explode                 :: proc(worldId: WorldId, #by_ptr explosionDef: ExplosionDef) ---

	// Adjust contact tuning parameters
	//	@param worldId The world id
	// @param hertz The contact stiffness (cycles per second)
	// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
	// @param pushSpeed The maximum contact constraint push out speed (meters per second)
	//	@note Advanced feature
	World_SetContactTuning        :: proc(worldId: WorldId, hertz: f32, dampingRatio: f32, pushSpeed: f32) ---

	// Adjust joint tuning parameters
	// @param worldId The world id
	// @param hertz The contact stiffness (cycles per second)
	// @param dampingRatio The contact bounciness with 1 being critical damping (non-dimensional)
	// @note Advanced feature
	World_SetJointTuning          :: proc(worldId: WorldId, hertz: f32, dampingRatio: f32) ---

	// Set the maximum linear speed. Usually in m/s.
	World_SetMaximumLinearSpeed   :: proc(worldId: WorldId, maximumLinearSpeed: f32) ---

	// Get the maximum linear speed. Usually in m/s.
	World_GetMaximumLinearSpeed   :: proc(worldId: WorldId) -> f32 ---

	// Enable/disable constraint warm starting. Advanced feature for testing. Disabling
	//	warm starting greatly reduces stability and provides no performance gain.
	World_EnableWarmStarting      :: proc(worldId: WorldId, flag: bool) ---

	// Is constraint warm starting enabled?
	World_IsWarmStartingEnabled   :: proc(worldId: WorldId) -> bool ---

	// Get the number of awake bodies.
	World_GetAwakeBodyCount       :: proc(worldId: WorldId) -> c.int ---

	// Get the current world performance profile
	World_GetProfile              :: proc(worldId: WorldId) -> Profile ---

	// Get world counters and sizes
	World_GetCounters             :: proc(worldId: WorldId) -> Counters ---

	// Set the user data pointer.
	World_SetUserData             :: proc(worldId: WorldId, userData: rawptr) ---

	// Get the user data pointer.
	World_GetUserData             :: proc(worldId: WorldId) -> rawptr ---

	// Set the friction callback. Passing nil resets to default.
	World_SetFrictionCallback     :: proc(worldId: WorldId, callback: FrictionCallback) ---

	// Set the restitution callback. Passing nil resets to default.
	World_SetRestitutionCallback  :: proc(worldId: WorldId, callback: RestitutionCallback) ---

	// Dump memory stats to box2d_memory.txt
	World_DumpMemoryStats         :: proc(worldId: WorldId) ---

	// This is for internal testing
	World_RebuildStaticTree       :: proc(worldId: WorldId) ---

	// This is for internal testing
	World_EnableSpeculative       :: proc(worldId: WorldId, flag: bool) ---
}


@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	/**
	 * @defgroup body Body
	 * This is the body API.
	 */

	// Create a rigid body given a definition. No reference to the definition is retained. So you can create the definition
	//	on the stack and pass it as a pointer.
	//	@code{.odin}
	//	body_def := b2.DefaultBodyDef()
	//	my_body_id =: b2.CreateBody(my_world_id, body_def)
	//	@endcode
	// @warning This function is locked during callbacks.
	CreateBody                      :: proc(worldId: WorldId, #by_ptr def: BodyDef) -> BodyId ---

	// Destroy a rigid body given an id. This destroys all shapes and joints attached to the body.
	//	Do not keep references to the associated shapes and joints.
	DestroyBody                     :: proc(bodyId: BodyId) ---

	// Body identifier validation. Can be used to detect orphaned ids. Provides validation for up to 64K allocations.
	Body_IsValid                    :: proc(id: BodyId) -> bool ---

	// Get the body type: static, kinematic, or dynamic
	Body_GetType                    :: proc(bodyId: BodyId) -> BodyType ---

	// Change the body type. This is an expensive operation. This automatically updates the mass
	//	properties regardless of the automatic mass setting.
	Body_SetType                    :: proc(bodyId: BodyId, type: BodyType) ---

	// Set the body name. Up to 32 characters excluding 0 termination.
	Body_SetName                    :: proc(bodyId: BodyId, name: cstring) ---

	// Get the body name. May be nil.
	Body_GetName                    :: proc(bodyId: BodyId) -> cstring ---

	// Set the user data for a body
	Body_SetUserData                :: proc(bodyId: BodyId, userData: rawptr) ---

	// Get the user data stored in a body
	Body_GetUserData                :: proc(bodyId: BodyId) -> rawptr ---

	// Get the world position of a body. This is the location of the body origin.
	Body_GetPosition                :: proc(bodyId: BodyId) -> Vec2 ---

	// Get the world rotation of a body as a cosine/sine pair (complex number)
	Body_GetRotation                :: proc(bodyId: BodyId) -> Rot ---

	// Get the world transform of a body.
	Body_GetTransform               :: proc(bodyId: BodyId) -> Transform ---

	// Set the world transform of a body. This acts as a teleport and is fairly expensive.
	// @note Generally you should create a body with then intended transform.
	//	@see BodyDef::position and BodyDef::angle
	Body_SetTransform               :: proc(bodyId: BodyId, position: Vec2, rotation: Rot) ---

	// Get a local point on a body given a world point
	Body_GetLocalPoint              :: proc(bodyId: BodyId, worldPoint: Vec2) -> Vec2 ---

	// Get a world point on a body given a local point
	Body_GetWorldPoint              :: proc(bodyId: BodyId, localPoint: Vec2) -> Vec2 ---

	// Get a local vector on a body given a world vector
	Body_GetLocalVector             :: proc(bodyId: BodyId, worldVector: Vec2) -> Vec2 ---

	// Get a world vector on a body given a local vector
	Body_GetWorldVector             :: proc(bodyId: BodyId, localVector: Vec2) -> Vec2 ---

	// Get the linear velocity of a body's center of mass. Usually in meters per second.
	Body_GetLinearVelocity          :: proc(bodyId: BodyId) -> Vec2 ---

	// Get the angular velocity of a body in radians per second
	Body_GetAngularVelocity         :: proc(bodyId: BodyId) -> f32 ---

	// Set the linear velocity of a body. Usually in meters per second.
	Body_SetLinearVelocity          :: proc(bodyId: BodyId, linearVelocity: Vec2) ---

	// Set the angular velocity of a body in radians per second
	Body_SetAngularVelocity         :: proc(bodyId: BodyId, angularVelocity: f32) ---

	// Set the velocity to reach the given transform after a given time step.
	// The result will be close but maybe not exact. This is meant for kinematic bodies.
	// This will automatically wake the body if asleep.
	Body_SetTargetTransform         :: proc(bodyId: BodyId, target: Transform, timeStep: f32) ---

	// Get the linear velocity of a local point attached to a body. Usually in meters per second.
	Body_GetLocalPointVelocity      :: proc(bodyId: BodyId, localPoint: Vec2) -> Vec2 ---

	// Get the linear velocity of a world point attached to a body. Usually in meters per second.
	GetWorldPointVelocity           :: proc(bodyId: BodyId, worldPoint: Vec2) -> Vec2 ---

	// Apply a force at a world point. If the force is not applied at the center of mass,
	// it will generate a torque and affect the angular velocity. This optionally wakes up the body.
	//	The force is ignored if the body is not awake.
	//	@param bodyId The body id
	// @param force The world force vector, usually in newtons (N)
	// @param point The world position of the point of application
	// @param wake Option to wake up the body
	Body_ApplyForce                 :: proc(bodyId: BodyId, force: Vec2, point: Vec2, wake: bool) ---

	// Apply a force to the center of mass. This optionally wakes up the body.
	//	The force is ignored if the body is not awake.
	//	@param bodyId The body id
	// @param force the world force vector, usually in newtons (N).
	// @param wake also wake up the body
	Body_ApplyForceToCenter         :: proc(bodyId: BodyId, force: Vec2, wake: bool) ---

	// Apply a torque. This affects the angular velocity without affecting the linear velocity.
	//	This optionally wakes the body. The torque is ignored if the body is not awake.
	//	@param bodyId The body id
	// @param torque about the z-axis (out of the screen), usually in N*m.
	// @param wake also wake up the body
	Body_ApplyTorque                :: proc(bodyId: BodyId, torque: f32, wake: bool) ---

	// Apply an impulse at a point. This immediately modifies the velocity.
	// It also modifies the angular velocity if the point of application
	// is not at the center of mass. This optionally wakes the body.
	// The impulse is ignored if the body is not awake.
	//	@param bodyId The body id
	// @param impulse the world impulse vector, usually in N*s or kg*m/s.
	// @param point the world position of the point of application.
	// @param wake also wake up the body
	//	@warning This should be used for one-shot impulses. If you need a steady force,
	// use a force instead, which will work better with the sub-stepping solver.
	Body_ApplyLinearImpulse         :: proc(bodyId: BodyId, impulse: Vec2, point: Vec2, wake: bool) ---

	// Apply an impulse to the center of mass. This immediately modifies the velocity.
	// The impulse is ignored if the body is not awake. This optionally wakes the body.
	//	@param bodyId The body id
	// @param impulse the world impulse vector, usually in N*s or kg*m/s.
	// @param wake also wake up the body
	//	@warning This should be used for one-shot impulses. If you need a steady force,
	// use a force instead, which will work better with the sub-stepping solver.
	Body_ApplyLinearImpulseToCenter :: proc(bodyId: BodyId, impulse: Vec2, wake: bool) ---

	// Apply an angular impulse. The impulse is ignored if the body is not awake.
	// This optionally wakes the body.
	//	@param bodyId The body id
	// @param impulse the angular impulse, usually in units of kg*m*m/s
	// @param wake also wake up the body
	//	@warning This should be used for one-shot impulses. If you need a steady force,
	// use a force instead, which will work better with the sub-stepping solver.
	Body_ApplyAngularImpulse        :: proc(bodyId: BodyId, impulse: f32, wake: bool) ---

	// Get the mass of the body, usually in kilograms
	Body_GetMass                    :: proc(bodyId: BodyId) -> f32 ---

	// Get the rotational inertia of the body, usually in kg*m^2
	Body_GetRotationalInertia       :: proc(bodyId: BodyId) -> f32 ---

	// Get the center of mass position of the body in local space
	Body_GetLocalCenterOfMass       :: proc(bodyId: BodyId) -> Vec2 ---

	// Get the center of mass position of the body in world space
	Body_GetWorldCenterOfMass       :: proc(bodyId: BodyId) -> Vec2 ---

	// Override the body's mass properties. Normally this is computed automatically using the
	//	shape geometry and density. This information is lost if a shape is added or removed or if the
	//	body type changes.
	Body_SetMassData                :: proc(bodyId: BodyId, massData: MassData) ---

	// Get the mass data for a body
	Body_GetMassData                :: proc(bodyId: BodyId) -> MassData ---

	// This update the mass properties to the sum of the mass properties of the shapes.
	// This normally does not need to be called unless you called SetMassData to override
	// the mass and you later want to reset the mass.
	//	You may also use this when automatic mass computation has been disabled.
	//	You should call this regardless of body type.
	Body_ApplyMassFromShapes        :: proc(bodyId: BodyId) ---

	// Adjust the linear damping. Normally this is set in BodyDef before creation.
	Body_SetLinearDamping           :: proc(bodyId: BodyId, linearDamping: f32) ---

	// Get the current linear damping.
	Body_GetLinearDamping           :: proc(bodyId: BodyId) -> f32 ---

	// Adjust the angular damping. Normally this is set in BodyDef before creation.
	Body_SetAngularDamping          :: proc(bodyId: BodyId, angularDamping: f32) ---

	// Get the current angular damping.
	Body_GetAngularDamping          :: proc(bodyId: BodyId) -> f32 ---

	// Adjust the gravity scale. Normally this is set in BodyDef before creation.
	//	@see BodyDef::gravityScale
	Body_SetGravityScale            :: proc(bodyId: BodyId, gravityScale: f32) ---

	// Get the current gravity scale
	Body_GetGravityScale            :: proc(bodyId: BodyId) -> f32 ---

	// @return true if this body is awake
	Body_IsAwake                    :: proc(bodyId: BodyId) -> bool ---

	// Wake a body from sleep. This wakes the entire island the body is touching.
	//	@warning Putting a body to sleep will put the entire island of bodies touching this body to sleep,
	//	which can be expensive and possibly unintuitive.
	Body_SetAwake                   :: proc(bodyId: BodyId, awake: bool) ---

	// Enable or disable sleeping for this body. If sleeping is disabled the body will wake.
	Body_EnableSleep                :: proc(bodyId: BodyId, enableSleep: bool) ---

	// Returns true if sleeping is enabled for this body
	Body_IsSleepEnabled             :: proc(bodyId: BodyId) -> bool ---

	// Set the sleep threshold, usually in meters per second
	Body_SetSleepThreshold          :: proc(bodyId: BodyId, sleepThreshold: f32) ---

	// Get the sleep threshold, usually in meters per second.
	Body_GetSleepThreshold          :: proc(bodyId: BodyId) -> f32 ---

	// Returns true if this body is enabled
	Body_IsEnabled                  :: proc(bodyId: BodyId) -> bool ---

	// Disable a body by removing it completely from the simulation. This is expensive.
	Body_Disable                    :: proc(bodyId: BodyId) ---

	// Enable a body by adding it to the simulation. This is expensive.
	Body_Enable                     :: proc(bodyId: BodyId) ---

	// Set this body to have fixed rotation. This causes the mass to be reset in all cases.
	Body_SetFixedRotation           :: proc(bodyId: BodyId, flag: bool) ---

	// Does this body have fixed rotation?
	Body_IsFixedRotation            :: proc(bodyId: BodyId) -> bool ---

	// Set this body to be a bullet. A bullet does continuous collision detection
	// against dynamic bodies (but not other bullets).
	Body_SetBullet                  :: proc(bodyId: BodyId, flag: bool) ---

	// Is this body a bullet?
	Body_IsBullet                   :: proc(bodyId: BodyId) -> bool ---

	// Enable/disable contact events on all shapes.
	// @see b2ShapeDef::enableContactEvents
	// @warning changing this at runtime may cause mismatched begin/end touch events
	Body_EnableContactEvents        :: proc(bodyId: BodyId, flag: bool) ---

	// Enable/disable hit events on all shapes
	//	@see b2ShapeDef::enableHitEvents
	Body_EnableHitEvents            :: proc(bodyId: BodyId, flag: bool) ---

	// Get the world that owns this body
	Body_GetWorld                   :: proc(bodyId: BodyId) -> WorldId ---

	// Get the number of shapes on this body
	Body_GetShapeCount              :: proc(bodyId: BodyId) -> c.int ---

	// Get the number of joints on this body
	Body_GetJointCount              :: proc(bodyId: BodyId) -> c.int ---

	// Get the maximum capacity required for retrieving all the touching contacts on a body
	Body_GetContactCapacity         :: proc(bodyId: BodyId) -> c.int ---

	// Get the current world AABB that contains all the attached shapes. Note that this may not encompass the body origin.
	//	If there are no shapes attached then the returned AABB is empty and centered on the body origin.
	Body_ComputeAABB                :: proc(bodyId: BodyId) -> AABB ---
}

// Get the shape ids for all shapes on this body, up to the provided capacity.
//	@returns the shape ids stored in the user array
@(require_results)
Body_GetShapes :: proc "c" (bodyId: BodyId, shapeArray: []ShapeId) -> []ShapeId {
	foreign lib {
		b2Body_GetShapes :: proc "c" (bodyId: BodyId, shapeArray: [^]ShapeId, capacity: c.int) -> c.int ---
	}
	n := b2Body_GetShapes(bodyId, raw_data(shapeArray), c.int(len(shapeArray)))
	return shapeArray[:n]

}

// Get the joint ids for all joints on this body, up to the provided capacity
//	@returns the joint ids stored in the user array
@(require_results)
Body_GetJoints :: proc "c" (bodyId: BodyId, jointArray: []JointId) -> []JointId {
	foreign lib {
		b2Body_GetJoints :: proc "c" (bodyId: BodyId, jointArray: [^]JointId, capacity: c.int) -> c.int ---
	}
	n := b2Body_GetJoints(bodyId, raw_data(jointArray), c.int(len(jointArray)))
	return jointArray[:n]

}

// Get the touching contact data for a body
@(require_results)
Body_GetContactData :: proc "c" (bodyId: BodyId, contactData: []ContactData) -> []ContactData {
	foreign lib {
		b2Body_GetContactData :: proc "c" (bodyId: BodyId, contactData: [^]ContactData, capacity: c.int) -> c.int ---
	}
	n := b2Body_GetContactData(bodyId, raw_data(contactData), c.int(len(contactData)))
	return contactData[:n]

}

@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	/**
	 * @defgroup shape Shape
	 * Functions to create, destroy, and access.
	 * Shapes bind raw geometry to bodies and hold material properties including friction and restitution.
	 */

	// Create a circle shape and attach it to a body. The shape definition and geometry are fully cloned.
	// Contacts are not created until the next time step.
	//	@return the shape id for accessing the shape
	CreateCircleShape              :: proc(bodyId: BodyId, #by_ptr def: ShapeDef, #by_ptr circle: Circle) -> ShapeId ---

	// Create a line segment shape and attach it to a body. The shape definition and geometry are fully cloned.
	// Contacts are not created until the next time step.
	//	@return the shape id for accessing the shape
	CreateSegmentShape             :: proc(bodyId: BodyId, #by_ptr def: ShapeDef, #by_ptr segment: Segment) -> ShapeId ---

	// Create a capsule shape and attach it to a body. The shape definition and geometry are fully cloned.
	// Contacts are not created until the next time step.
	//	@return the shape id for accessing the shape
	CreateCapsuleShape             :: proc(bodyId: BodyId, #by_ptr def: ShapeDef, #by_ptr capsule: Capsule) -> ShapeId ---

	// Create a polygon shape and attach it to a body. The shape definition and geometry are fully cloned.
	// Contacts are not created until the next time step.
	//	@return the shape id for accessing the shape
	CreatePolygonShape             :: proc(bodyId: BodyId, #by_ptr def: ShapeDef, #by_ptr polygon: Polygon) -> ShapeId ---

	// Destroy a shape. You may defer the body mass update which can improve performance if several shapes on a
	//	body are destroyed at once.
	//	@see b2Body_ApplyMassFromShapes
	DestroyShape                   :: proc(shapeId: ShapeId, updateBodyMass: bool) ---

	// Shape identifier validation. Provides validation for up to 64K allocations.
	Shape_IsValid                  :: proc(id: ShapeId) -> bool ---

	// Get the type of a shape
	Shape_GetType                  :: proc(shapeId: ShapeId) -> ShapeType ---

	// Get the id of the body that a shape is attached to
	Shape_GetBody                  :: proc(shapeId: ShapeId) -> BodyId ---

	// Get the world that owns this shape.
	Shape_GetWorld                 :: proc(shapeId: ShapeId) -> WorldId ---

	// Returns true if the shape is a sensor. It is not possible to change a shape
	// from sensor to solid dynamically because this breaks the contract for
	// sensor events.
	Shape_IsSensor                 :: proc(shapeId: ShapeId) -> bool ---

	// Set the user data for a shape
	Shape_SetUserData              :: proc(shapeId: ShapeId, userData: rawptr) ---

	// Get the user data for a shape. This is useful when you get a shape id
	//	from an event or query.
	Shape_GetUserData              :: proc(shapeId: ShapeId) -> rawptr ---

	// Set the mass density of a shape, usually in kg/m^2.
	//	This will optionally update the mass properties on the parent body.
	//	@see b2ShapeDef::density, b2Body_ApplyMassFromShapes
	Shape_SetDensity               :: proc(shapeId: ShapeId, density: f32, updateBodyMass: bool) ---

	// Get the density of a shape, usually in kg/m^2
	Shape_GetDensity               :: proc(shapeId: ShapeId) -> f32 ---

	// Set the friction on a shape
	//	@see b2ShapeDef::friction
	Shape_SetFriction              :: proc(shapeId: ShapeId, friction: f32) ---

	// Get the friction of a shape
	Shape_GetFriction              :: proc(shapeId: ShapeId) -> f32 ---

	// Set the shape restitution (bounciness)
	//	@see b2ShapeDef::restitution
	Shape_SetRestitution           :: proc(shapeId: ShapeId, restitution: f32) ---

	// Get the shape restitution
	Shape_GetRestitution           :: proc(shapeId: ShapeId) -> f32 ---

	// Set the shape material identifier
	// @see b2ShapeDef::material
	Shape_SetMaterial              :: proc(shapeId: ShapeId, material: c.int) ---

	// Get the shape material identifier
	Shape_GetMaterial              :: proc(shapeId: ShapeId) -> c.int ---

	// Get the shape filter
	Shape_GetFilter                :: proc(shapeId: ShapeId) -> Filter ---

	// Set the current filter. This is almost as expensive as recreating the shape. This may cause
	// contacts to be immediately destroyed. However contacts are not created until the next world step.
	// Sensor overlap state is also not updated until the next world step.
	// @see b2ShapeDef::filter
	Shape_SetFilter                :: proc(shapeId: ShapeId, filter: Filter) ---

	// Enable sensor events for this shape.
	//	@see b2ShapeDef::enableSensorEvents
	Shape_EnableSensorEvents       :: proc(shapeId: ShapeId, flag: bool) ---

	// Returns true if sensor events are enabled
	Shape_AreSensorEventsEnabled   :: proc(shapeId: ShapeId) -> bool ---

	// Enable contact events for this shape. Only applies to kinematic and dynamic bodies. Ignored for sensors.
	//	@see b2ShapeDef::enableContactEvents
	// @warning changing this at run-time may lead to lost begin/end events
	Shape_EnableContactEvents      :: proc(shapeId: ShapeId, flag: bool) ---

	// Returns true if contact events are enabled
	Shape_AreContactEventsEnabled  :: proc(shapeId: ShapeId) -> bool ---

	// Enable pre-solve contact events for this shape. Only applies to dynamic bodies. These are expensive
	//	and must be carefully handled due to multithreading. Ignored for sensors.
	//	@see b2PreSolveFcn
	Shape_EnablePreSolveEvents     :: proc(shapeId: ShapeId, flag: bool) ---

	// Returns true if pre-solve events are enabled
	Shape_ArePreSolveEventsEnabled :: proc(shapeId: ShapeId) -> bool ---

	// Enable contact hit events for this shape. Ignored for sensors.
	//	@see WorldDef.hitEventThreshold
	Shape_EnableHitEvents          :: proc(shapeId: ShapeId, flag: bool) ---

	// Returns true if hit events are enabled
	Shape_AreHitEventsEnabled      :: proc(shapeId: ShapeId) -> bool ---

	// Test a point for overlap with a shape
	Shape_TestPoint                :: proc(shapeId: ShapeId, point: Vec2) -> bool ---

	// Ray cast a shape directly
	Shape_RayCast                  :: proc(shapeId: ShapeId, #by_ptr input: RayCastInput) -> CastOutput ---

	// Get a copy of the shape's circle. Asserts the type is correct.
	Shape_GetCircle                :: proc(shapeId: ShapeId) -> Circle ---

	// Get a copy of the shape's line segment. Asserts the type is correct.
	Shape_GetSegment               :: proc(shapeId: ShapeId) -> Segment ---

	// Get a copy of the shape's chain segment. These come from chain shapes.
	// Asserts the type is correct.
	Shape_GetChainSegment          :: proc(shapeId: ShapeId) -> ChainSegment ---

	// Get a copy of the shape's capsule. Asserts the type is correct.
	Shape_GetCapsule               :: proc(shapeId: ShapeId) -> Capsule ---

	// Get a copy of the shape's convex polygon. Asserts the type is correct.
	Shape_GetPolygon               :: proc(shapeId: ShapeId) -> Polygon ---

	// Allows you to change a shape to be a circle or update the current circle.
	// This does not modify the mass properties.
	//	@see b2Body_ApplyMassFromShapes
	Shape_SetCircle                :: proc(shapeId: ShapeId, #by_ptr circle: Circle) ---

	// Allows you to change a shape to be a capsule or update the current capsule.
	// This does not modify the mass properties.
	//	@see b2Body_ApplyMassFromShapes
	Shape_SetCapsule               :: proc(shapeId: ShapeId, #by_ptr capsule: Capsule) ---

	// Allows you to change a shape to be a segment or update the current segment.
	Shape_SetSegment               :: proc(shapeId: ShapeId, #by_ptr segment: Segment) ---

	// Allows you to change a shape to be a polygon or update the current polygon.
	// This does not modify the mass properties.
	//	@see b2Body_ApplyMassFromShapes
	Shape_SetPolygon               :: proc(shapeId: ShapeId, #by_ptr polygon: Polygon) ---

	// Get the parent chain id if the shape type is a chain segment, otherwise
	// returns b2_nullChainId.
	Shape_GetParentChain           :: proc(shapeId: ShapeId) -> ChainId ---

	// Get the maximum capacity required for retrieving all the touching contacts on a shape
	Shape_GetContactCapacity       :: proc(shapeId: ShapeId) -> c.int ---

	// Get the maximum capacity required for retrieving all the overlapped shapes on a sensor shape.
	// This returns 0 if the provided shape is not a sensor.
	// @param shapeId the id of a sensor shape
	// @returns the required capacity to get all the overlaps in b2Shape_GetSensorOverlaps
	Shape_GetSensorCapacity        :: proc(shapeId: ShapeId) -> c.int ---

	// Get the overlapped shapes for a sensor shape.
	// @param shapeId the id of a sensor shape
	// @param overlaps a user allocated array that is filled with the overlapping shapes
	// @param capacity the capacity of overlappedShapes
	// @returns the number of elements filled in the provided array
	// @warning do not ignore the return value, it specifies the valid number of elements
	// @warning overlaps may contain destroyed shapes so use b2Shape_IsValid to confirm each overlap
	Shape_GetSensorOverlaps        :: proc(shapeId: ShapeId, overlaps: [^]ShapeId, capacity: c.int) -> c.int ---

	// Get the current world AABB
	Shape_GetAABB                  :: proc(shapeId: ShapeId) -> AABB ---

	// Get the mass data of a shape
	Shape_GetMassData              :: proc(shapeId: ShapeId) -> MassData ---

	// Get the closest point on a shape to a target point. Target and result are in world space.
	Shape_GetClosestPoint          :: proc(shapeId: ShapeId, target: Vec2) -> Vec2 ---
}

// Get the touching contact data for a shape. The provided shapeId will be either shapeIdA or shapeIdB on the contact data.
@(require_results)
Shape_GetContactData :: proc "c" (shapeId: ShapeId, contactData: []ContactData) -> []ContactData {
	foreign lib {
		b2Shape_GetContactData :: proc "c" (shapeId: ShapeId, contactData: [^]ContactData, capacity: c.int) -> c.int ---
	}
	n := b2Shape_GetContactData(shapeId, raw_data(contactData), c.int(len(contactData)))
	return contactData[:n]
}


@(link_prefix="b2", default_calling_convention="c", require_results)
foreign lib {
	// Chain Shape

	// Create a chain shape
	//	@see b2ChainDef for details
	CreateChain           :: proc(bodyId: BodyId, #by_ptr def: ChainDef) -> ChainId ---

	// Destroy a chain shape
	DestroyChain          :: proc(chainId: ChainId) ---

	// Get the world that owns this chain shape
	Chain_GetWorld        :: proc(chainId: ChainId) -> WorldId ---

	// Get the number of segments on this chain
	Chain_GetSegmentCount :: proc(chainId: ChainId) -> c.int ---

	// Fill a user array with chain segment shape ids up to the specified capacity. Returns
	// the actual number of segments returned.
	Chain_GetSegments     :: proc(chainId: ChainId, segmentArray: [^]ShapeId, capacity: c.int) -> c.int ---

	// Set the chain friction
	// @see b2ChainDef::friction
	Chain_SetFriction     :: proc(chainId: ChainId, friction: f32) ---

	// Get the chain friction
	Chain_GetFriction     :: proc(chainId: ChainId) -> f32 ---

	// Set the chain restitution (bounciness)
	// @see b2ChainDef::restitution
	Chain_SetRestitution  :: proc(chainId: ChainId, restitution: f32) ---

	// Get the chain restitution
	Chain_GetRestitution  :: proc(chainId: ChainId) -> f32 ---

	// Set the chain material
	// @see b2ChainDef::material
	Chain_SetMaterial     :: proc(chainId: ChainId, material: c.int) ---

	// Get the chain material
	Chain_GetMaterial     :: proc(chainId: ChainId) -> c.int ---

	// Chain identifier validation. Provides validation for up to 64K allocations.
	Chain_IsValid         :: proc(id: ChainId) -> bool ---

	/**
	 * @defgroup joint Joint
	 * @brief Joints allow you to connect rigid bodies together while allowing various forms of relative motions.
	 */

	// Destroy a joint
	DestroyJoint              :: proc(jointId: JointId) ---

	// Joint identifier validation. Provides validation for up to 64K allocations.
	Joint_IsValid             :: proc(id: JointId) -> bool ---

	// Get the joint type
	Joint_GetType             :: proc(jointId: JointId) -> JointType ---

	// Get body A id on a joint
	Joint_GetBodyA            :: proc(jointId: JointId) -> BodyId ---

	// Get body B id on a joint
	Joint_GetBodyB            :: proc(jointId: JointId) -> BodyId ---

	// Get the world that owns this joint
	Joint_GetWorld            :: proc(jointId: JointId) -> WorldId ---

	// Get the local anchor on bodyA
	Joint_GetLocalAnchorA     :: proc(jointId: JointId) -> Vec2 ---

	// Get the local anchor on bodyB
	Joint_GetLocalAnchorB     :: proc(jointId: JointId) -> Vec2 ---

	// Toggle collision between connected bodies
	Joint_SetCollideConnected :: proc(jointId: JointId, shouldCollide: bool) ---

	// Is collision allowed between connected bodies?
	Joint_GetCollideConnected :: proc(jointId: JointId) -> bool ---

	// Set the user data on a joint
	Joint_SetUserData         :: proc(jointId: JointId, userData: rawptr) ---

	// Get the user data on a joint
	Joint_GetUserData         :: proc(jointId: JointId) -> rawptr ---

	// Wake the bodies connect to this joint
	Joint_WakeBodies          :: proc(jointId: JointId) ---

	// Get the current constraint force for this joint. Usually in Newtons.
	Joint_GetConstraintForce  :: proc(jointId: JointId) -> Vec2 ---

	// Get the current constraint torque for this joint. Usually in Newton * meters.
	Joint_GetConstraintTorque :: proc(jointId: JointId) -> f32 ---

	/**
	 * @defgroup distance_joint Distance Joint
	 * @brief Functions for the distance joint.
	 */

	// Create a distance joint
	//	@see b2DistanceJointDef for details
	CreateDistanceJoint                 :: proc(worldId: WorldId, #by_ptr def: DistanceJointDef) -> JointId ---

	// Set the rest length of a distance joint
	// @param jointId The id for a distance joint
	// @param length The new distance joint length
	DistanceJoint_SetLength             :: proc(jointId: JointId, length: f32) ---

	// Get the rest length of a distance joint
	DistanceJoint_GetLength             :: proc(jointId: JointId) -> f32 ---

	// Enable/disable the distance joint spring. When disabled the distance joint is rigid.
	DistanceJoint_EnableSpring          :: proc(jointId: JointId, enableSpring: bool) ---

	// Is the distance joint spring enabled?
	DistanceJoint_IsSpringEnabled       :: proc(jointId: JointId) -> bool ---

	// Set the spring stiffness in Hertz
	DistanceJoint_SetSpringHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Set the spring damping ratio, non-dimensional
	DistanceJoint_SetSpringDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the spring Hertz
	DistanceJoint_GetSpringHertz        :: proc(jointId: JointId) -> f32 ---

	// Get the spring damping ratio
	DistanceJoint_GetSpringDampingRatio :: proc(jointId: JointId) -> f32 ---

	// Enable joint limit. The limit only works if the joint spring is enabled. Otherwise the joint is rigid
	//	and the limit has no effect.
	DistanceJoint_EnableLimit           :: proc(jointId: JointId, enableLimit: bool) ---

	// Is the distance joint limit enabled?
	DistanceJoint_IsLimitEnabled        :: proc(jointId: JointId) -> bool ---

	// Set the minimum and maximum length parameters of a distance joint
	DistanceJoint_SetLengthRange        :: proc(jointId: JointId, minLength, maxLength: f32) ---

	// Get the distance joint minimum length
	DistanceJoint_GetMinLength          :: proc(jointId: JointId) -> f32 ---

	// Get the distance joint maximum length
	DistanceJoint_GetMaxLength          :: proc(jointId: JointId) -> f32 ---

	// Get the current length of a distance joint
	DistanceJoint_GetCurrentLength      :: proc(jointId: JointId) -> f32 ---

	// Enable/disable the distance joint motor
	DistanceJoint_EnableMotor           :: proc(jointId: JointId, enableMotor: bool) ---

	// Is the distance joint motor enabled?
	DistanceJoint_IsMotorEnabled        :: proc(jointId: JointId) -> bool ---

	// Set the distance joint motor speed, usually in meters per second
	DistanceJoint_SetMotorSpeed         :: proc(jointId: JointId, motorSpeed: f32) ---

	// Get the distance joint motor speed, usually in meters per second
	DistanceJoint_GetMotorSpeed         :: proc(jointId: JointId) -> f32 ---

	// Set the distance joint maximum motor force, usually in newtons
	DistanceJoint_SetMaxMotorForce      :: proc(jointId: JointId, force: f32) ---

	// Get the distance joint maximum motor force, usually in newtons
	DistanceJoint_GetMaxMotorForce      :: proc(jointId: JointId) -> f32 ---

	// Get the distance joint current motor force, usually in newtons
	DistanceJoint_GetMotorForce         :: proc(jointId: JointId) -> f32 ---

	/**
	 * @defgroup motor_joint Motor Joint
	 * @brief Functions for the motor joint.
	 *
	 * The motor joint is used to drive the relative transform between two bodies. It takes
	 * a relative position and rotation and applies the forces and torques needed to achieve
	 * that relative transform over time.
	 */

	// Create a motor joint
	//	@see b2MotorJointDef for details
	CreateMotorJoint               :: proc(worldId: WorldId, def: MotorJointDef) -> JointId ---

	// Set the motor joint linear offset target
	MotorJoint_SetLinearOffset     :: proc(jointId: JointId, linearOffset: Vec2) ---

	// Get the motor joint linear offset target
	MotorJoint_GetLinearOffset     :: proc(jointId: JointId) -> Vec2 ---

	// Set the motor joint angular offset target in radians
	MotorJoint_SetAngularOffset    :: proc(jointId: JointId, angularOffset: f32) ---

	// Get the motor joint angular offset target in radians
	MotorJoint_GetAngularOffset    :: proc(jointId: JointId) -> f32 ---

	// Set the motor joint maximum force, usually in newtons
	MotorJoint_SetMaxForce         :: proc(jointId: JointId, maxForce: f32) ---

	// Get the motor joint maximum force, usually in newtons
	MotorJoint_GetMaxForce         :: proc(jointId: JointId) -> f32 ---

	// Set the motor joint maximum torque, usually in newton-meters
	MotorJoint_SetMaxTorque        :: proc(jointId: JointId, maxTorque: f32) ---

	// Get the motor joint maximum torque, usually in newton-meters
	MotorJoint_GetMaxTorque        :: proc(jointId: JointId) -> f32 ---

	// Set the motor joint correction factor, usually in [0, 1]
	MotorJoint_SetCorrectionFactor :: proc(jointId: JointId, correctionFactor: f32) ---

	// Get the motor joint correction factor, usually in [0, 1]
	MotorJoint_GetCorrectionFactor :: proc(jointId: JointId) -> f32 ---

	/**@}*/

	/**
	 * @defgroup mouse_joint Mouse Joint
	 * @brief Functions for the mouse joint.
	 *
	 * The mouse joint is designed for use in the samples application, but you may find it useful in applications where
	 * the user moves a rigid body with a cursor.
	 */

	// Create a mouse joint
	//	@see b2MouseJointDef for details
	CreateMouseJoint                 :: proc(worldId: WorldId, #by_ptr def: MouseJointDef) -> JointId ---

	// Set the mouse joint target
	MouseJoint_SetTarget             :: proc(jointId: JointId, target: Vec2) ---

	// Get the mouse joint target
	MouseJoint_GetTarget             :: proc(jointId: JointId) -> Vec2 ---

	// Set the mouse joint spring stiffness in Hertz
	MouseJoint_SetSpringHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Get the mouse joint spring stiffness in Hertz
	MouseJoint_GetSpringHertz        :: proc(jointId: JointId) -> f32 ---

	// Set the mouse joint spring damping ratio, non-dimensional
	MouseJoint_SetSpringDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the mouse joint damping ratio, non-dimensional
	MouseJoint_GetSpringDampingRatio :: proc(jointId: JointId) -> f32 ---

	// Set the mouse joint maximum force, usually in newtons
	MouseJoint_SetMaxForce           :: proc(jointId: JointId, maxForce: f32) ---

	// Get the mouse joint maximum force, usually in newtons
	MouseJoint_GetMaxForce           :: proc(jointId: JointId) -> f32 ---

	/**@}*/

	/**
	 * @defgroup filter_joint Filter Joint
	 * @brief Functions for the filter joint.
	 *
	 * The filter joint is used to disable collision between two bodies. As a side effect of being a joint, it also
	 * keeps the two bodies in the same simulation island.
	 * @{
	 */

	// Create a filter joint.
	// @see b2FilterJointDef for details
	CreateFilterJoint :: proc(worldId: WorldId, #by_ptr def: FilterJointDef) -> JointId ---

	/**@}*/

	/**
	 * @defgroup prismatic_joint Prismatic Joint
	 * @brief A prismatic joint allows for translation along a single axis with no rotation.
	 *
	 * The prismatic joint is useful for things like pistons and moving platforms, where you want a body to translate
	 * along an axis and have no rotation. Also called a *slider* joint.
	 */

	// Create a prismatic (slider) joint.
	//	@see b2PrismaticJointDef for details
	CreatePrismaticJoint                 :: proc(worldId: WorldId, #by_ptr def: PrismaticJointDef) -> JointId ---

	// Enable/disable the joint spring.
	PrismaticJoint_EnableSpring          :: proc(jointId: JointId, enableSpring: bool) ---

	// Is the prismatic joint spring enabled or not?
	PrismaticJoint_IsSpringEnabled       :: proc(jointId: JointId) -> bool ---

	// Set the prismatic joint stiffness in Hertz.
	// This should usually be less than a quarter of the simulation rate. For example, if the simulation
	// runs at 60Hz then the joint stiffness should be 15Hz or less.
	PrismaticJoint_SetSpringHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Get the prismatic joint stiffness in Hertz
	PrismaticJoint_GetSpringHertz        :: proc(jointId: JointId) -> f32 ---

	// Set the prismatic joint damping ratio (non-dimensional)
	PrismaticJoint_SetSpringDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the prismatic spring damping ratio (non-dimensional)
	PrismaticJoint_GetSpringDampingRatio :: proc(jointId: JointId) -> f32 ---

	// Enable/disable a prismatic joint limit
	PrismaticJoint_EnableLimit           :: proc(jointId: JointId, enableLimit: bool) ---

	// Is the prismatic joint limit enabled?
	PrismaticJoint_IsLimitEnabled        :: proc(jointId: JointId) -> bool ---

	// Get the prismatic joint lower limit
	PrismaticJoint_GetLowerLimit         :: proc(jointId: JointId) -> f32 ---

	// Get the prismatic joint upper limit
	PrismaticJoint_GetUpperLimit         :: proc(jointId: JointId) -> f32 ---

	// Set the prismatic joint limits
	PrismaticJoint_SetLimits             :: proc(jointId: JointId, lower, upper: f32) ---

	// Enable/disable a prismatic joint motor
	PrismaticJoint_EnableMotor           :: proc(jointId: JointId, enableMotor: bool) ---

	// Is the prismatic joint motor enabled?
	PrismaticJoint_IsMotorEnabled        :: proc(jointId: JointId) -> bool ---

	// Set the prismatic joint motor speed, usually in meters per second
	PrismaticJoint_SetMotorSpeed         :: proc(jointId: JointId, motorSpeed: f32) ---

	// Get the prismatic joint motor speed, usually in meters per second
	PrismaticJoint_GetMotorSpeed         :: proc(jointId: JointId) -> f32 ---

	// Set the prismatic joint maximum motor force, usually in newtons
	PrismaticJoint_SetMaxMotorForce      :: proc(jointId: JointId, force: f32) ---

	// Get the prismatic joint maximum motor force, usually in newtons
	PrismaticJoint_GetMaxMotorForce      :: proc(jointId: JointId) -> f32 ---

	// Get the prismatic joint current motor force, usually in newtons
	PrismaticJoint_GetMotorForce         :: proc(jointId: JointId) -> f32 ---

	// Get the current joint translation, usually in meters.
	PrismaticJoint_GetTranslation        :: proc(jointId: JointId) -> f32 ---

	// Get the current joint translation speed, usually in meters per second.
	PrismaticJoint_GetSpeed              :: proc(jointId: JointId) -> f32 ---

	/**
	 * @defgroup revolute_joint Revolute Joint
	 * @brief A revolute joint allows for relative rotation in the 2D plane with no relative translation.
	 *
	 * The revolute joint is probably the most common joint. It can be used for ragdolls and chains.
	 * Also called a *hinge* or *pin* joint.
	 */

	// Create a revolute joint
	//	@see b2RevoluteJointDef for details
	CreateRevoluteJoint                 :: proc(worldId: WorldId, #by_ptr def: RevoluteJointDef) -> JointId ---

	// Enable/disable the revolute joint spring
	RevoluteJoint_EnableSpring          :: proc(jointId: JointId, enableSpring: bool) ---

	// Is the revolute spring enabled?
	RevoluteJoint_IsSpringEnabled       :: proc(jointId: JointId) -> bool ---

	// Set the revolute joint spring stiffness in Hertz
	RevoluteJoint_SetSpringHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Get the revolute joint spring stiffness in Hertz
	RevoluteJoint_GetSpringHertz        :: proc(jointId: JointId) -> f32 ---

	// Set the revolute joint spring damping ratio, non-dimensional
	RevoluteJoint_SetSpringDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the revolute joint spring damping ratio, non-dimensional
	RevoluteJoint_GetSpringDampingRatio :: proc(jointId: JointId) -> f32 ---

	// Get the revolute joint current angle in radians relative to the reference angle
	//	@see b2RevoluteJointDef::referenceAngle
	RevoluteJoint_GetAngle              :: proc(jointId: JointId) -> f32 ---

	// Enable/disable the revolute joint limit
	RevoluteJoint_EnableLimit           :: proc(jointId: JointId, enableLimit: bool) ---

	// Is the revolute joint limit enabled?
	RevoluteJoint_IsLimitEnabled        :: proc(jointId: JointId) -> bool ---

	// Get the revolute joint lower limit in radians
	RevoluteJoint_GetLowerLimit         :: proc(jointId: JointId) -> f32 ---

	// Get the revolute joint upper limit in radians
	RevoluteJoint_GetUpperLimit         :: proc(jointId: JointId) -> f32 ---

	// Set the revolute joint limits in radians. It is expected that lower <= upper
	// and that -0.95 * B2_PI <= lower && upper <= -0.95 * B2_PI.
	RevoluteJoint_SetLimits             :: proc(jointId: JointId, lower, upper: f32) ---

	// Enable/disable a revolute joint motor
	RevoluteJoint_EnableMotor           :: proc(jointId: JointId, enableMotor: bool) ---

	// Is the revolute joint motor enabled?
	RevoluteJoint_IsMotorEnabled        :: proc(jointId: JointId) -> bool ---

	// Set the revolute joint motor speed in radians per second
	RevoluteJoint_SetMotorSpeed         :: proc(jointId: JointId, motorSpeed: f32) ---

	// Get the revolute joint motor speed in radians per second
	RevoluteJoint_GetMotorSpeed         :: proc(jointId: JointId) -> f32 ---

	// Get the revolute joint current motor torque, usually in newton-meters
	RevoluteJoint_GetMotorTorque        :: proc(jointId: JointId) -> f32 ---

	// Set the revolute joint maximum motor torque, usually in newton-meters
	RevoluteJoint_SetMaxMotorTorque     :: proc(jointId: JointId, torque: f32) ---

	// Get the revolute joint maximum motor torque, usually in newton-meters
	RevoluteJoint_GetMaxMotorTorque     :: proc(jointId: JointId) -> f32 ---

	/**@}*/

	/**
	 * @defgroup weld_joint Weld Joint
	 * @brief A weld joint fully constrains the relative transform between two bodies while allowing for springiness
	 *
	 * A weld joint constrains the relative rotation and translation between two bodies. Both rotation and translation
	 * can have damped springs.
	 *
	 * @note The accuracy of weld joint is limited by the accuracy of the solver. Long chains of weld joints may flex.
	 */

	// Create a weld joint
	//	@see b2WeldJointDef for details
	CreateWeldJoint                  :: proc(worldId: WorldId, #by_ptr def: WeldJointDef) -> JointId ---

	// Get the weld joint reference angle in radians
	WeldJoint_GetReferenceAngle      :: proc(jointId: JointId) -> f32 ---

	// Set the weld joint reference angle in radians, must be in [-pi,pi].
	WeldJoint_SetReferenceAngle      :: proc(jointId: JointId, angleInRadians: f32) ---

	// Set the weld joint linear stiffness in Hertz. 0 is rigid.
	WeldJoint_SetLinearHertz         :: proc(jointId: JointId, hertz: f32) ---

	// Get the weld joint linear stiffness in Hertz
	WeldJoint_GetLinearHertz         :: proc(jointId: JointId) -> f32 ---

	// Set the weld joint linear damping ratio (non-dimensional)
	WeldJoint_SetLinearDampingRatio  :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the weld joint linear damping ratio (non-dimensional)
	WeldJoint_GetLinearDampingRatio  :: proc(jointId: JointId) -> f32 ---

	// Set the weld joint angular stiffness in Hertz. 0 is rigid.
	WeldJoint_SetAngularHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Get the weld joint angular stiffness in Hertz
	WeldJoint_GetAngularHertz        :: proc(jointId: JointId) -> f32 ---

	// Set weld joint angular damping ratio, non-dimensional
	WeldJoint_SetAngularDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the weld joint angular damping ratio, non-dimensional
	WeldJoint_GetAngularDampingRatio :: proc(jointId: JointId) -> f32 ---

	/**
	 * @defgroup wheel_joint Wheel Joint
	 * The wheel joint can be used to simulate wheels on vehicles.
	 *
	 * The wheel joint restricts body B to move along a local axis in body A. Body B is free to
	 * rotate. Supports a linear spring, linear limits, and a rotational motor.
	 *
	 */

	// Create a wheel joint
	//	@see b2WheelJointDef for details
	CreateWheelJoint                 :: proc(worldId: WorldId, #by_ptr def: WheelJointDef) -> JointId ---

	// Enable/disable the wheel joint spring
	WheelJoint_EnableSpring          :: proc(jointId: JointId, enableSpring: bool) ---

	// Is the wheel joint spring enabled?
	WheelJoint_IsSpringEnabled       :: proc(jointId: JointId) -> bool ---

	// Set the wheel joint stiffness in Hertz
	WheelJoint_SetSpringHertz        :: proc(jointId: JointId, hertz: f32) ---

	// Get the wheel joint stiffness in Hertz
	WheelJoint_GetSpringHertz        :: proc(jointId: JointId) -> f32 ---

	// Set the wheel joint damping ratio, non-dimensional
	WheelJoint_SetSpringDampingRatio :: proc(jointId: JointId, dampingRatio: f32) ---

	// Get the wheel joint damping ratio, non-dimensional
	WheelJoint_GetSpringDampingRatio :: proc(jointId: JointId) -> f32 ---

	// Enable/disable the wheel joint limit
	WheelJoint_EnableLimit           :: proc(jointId: JointId, enableLimit: bool) ---

	// Is the wheel joint limit enabled?
	WheelJoint_IsLimitEnabled        :: proc(jointId: JointId) -> bool ---

	// Get the wheel joint lower limit
	WheelJoint_GetLowerLimit         :: proc(jointId: JointId) -> f32 ---

	// Get the wheel joint upper limit
	WheelJoint_GetUpperLimit         :: proc(jointId: JointId) -> f32 ---

	// Set the wheel joint limits
	WheelJoint_SetLimits             :: proc(jointId: JointId, lower, upper: f32) ---

	// Enable/disable the wheel joint motor
	WheelJoint_EnableMotor           :: proc(jointId: JointId, enableMotor: bool) ---

	// Is the wheel joint motor enabled?
	WheelJoint_IsMotorEnabled        :: proc(jointId: JointId) -> bool ---

	// Set the wheel joint motor speed in radians per second
	WheelJoint_SetMotorSpeed         :: proc(jointId: JointId, motorSpeed: f32) ---

	// Get the wheel joint motor speed in radians per second
	WheelJoint_GetMotorSpeed         :: proc(jointId: JointId) -> f32 ---

	// Set the wheel joint maximum motor torque, usually in newton-meters
	WheelJoint_SetMaxMotorTorque     :: proc(jointId: JointId, torque: f32) ---

	// Get the wheel joint maximum motor torque, usually in newton-meters
	WheelJoint_GetMaxMotorTorque     :: proc(jointId: JointId) -> f32 ---

	// Get the wheel joint current motor torque, usually in newton-meters
	WheelJoint_GetMotorTorque        :: proc(jointId: JointId) -> f32 ---
}



IsValid :: proc{
	IsValidFloat,
	IsValidVec2,
	IsValidRotation,
	IsValidAABB,
	IsValidPlane,
	World_IsValid,
	Body_IsValid,
	Shape_IsValid,
	Chain_IsValid,
	Joint_IsValid,

	IsValidRay,
}
