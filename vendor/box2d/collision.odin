package vendor_box2d

foreign import lib {
	"box2d.lib", // dummy
}

import "core:c"


// The maximum number of vertices on a convex polygon. Changing this affects performance even if you
//	don't use more vertices.
maxPolygonVertices :: 8

// Low level ray-cast input data
RayCastInput :: struct {
	// Start point of the ray cast
	origin: Vec2,

	// Translation of the ray cast
	translation: Vec2,

	// The maximum fraction of the translation to consider, typically 1
	maxFraction: f32,
}

// Low level shape cast input in generic form. This allows casting an arbitrary point
//	cloud wrap with a radius. For example, a circle is a single point with a non-zero radius.
//	A capsule is two points with a non-zero radius. A box is four points with a zero radius.
ShapeCastInput :: struct {
	// A point cloud to cast
	points: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count: i32,

	// The radius around the point cloud
	radius: f32,

	// The translation of the shape cast
	translation: Vec2,

	// The maximum fraction of the translation to consider, typically 1
	maxFraction: f32,
}

// Low level ray-cast or shape-cast output data
CastOutput :: struct {
	// The surface normal at the hit point
	normal: Vec2,

	// The surface hit point
	point: Vec2,

	// The fraction of the input translation at collision
	fraction: f32,

	// The number of iterations used
	iterations: i32,

	// Did the cast hit?
	hit: bool,
}

// This holds the mass data computed for a shape.
MassData :: struct {
	// The mass of the shape, usually in kilograms.
	mass: f32,

	// The position of the shape's centroid relative to the shape's origin.
	center: Vec2,

	// The rotational inertia of the shape about the local origin.
	rotationalInertia: f32,
}

// A solid circle
Circle :: struct {
	// The local center
	center: Vec2,

	// The radius
	radius: f32,
}

// A solid capsule can be viewed as two semicircles connected
//	by a rectangle.
Capsule :: struct {
	// Local center of the first semicircle
	center1: Vec2,

	// Local center of the second semicircle
	center2: Vec2,

	// The radius of the semicircles
	radius: f32,
}

// A solid convex polygon. It is assumed that the interior of the polygon is to
// the left of each edge.
// Polygons have a maximum number of vertices equal to maxPolygonVertices.
// In most cases you should not need many vertices for a convex polygon.
//	@warning DO NOT fill this out manually, instead use a helper function like
//	b2MakePolygon or b2MakeBox.
Polygon :: struct {
	// The polygon vertices
	vertices: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The outward normal vectors of the polygon sides
	normals: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The centroid of the polygon
	centroid: Vec2,

	// The external radius for rounded polygons
	radius: f32,

	// The number of polygon vertices
	count: i32,
}

// A line segment with two-sided collision.
Segment :: struct {
	// The first point
	point1: Vec2,

	// The second point
	point2: Vec2,
}

// A smooth line segment with one-sided collision. Only collides on the right side.
// Several of these are generated for a chain shape.
// ghost1 -> point1 -> point2 -> ghost2
SmoothSegment :: struct {
	// The tail ghost vertex
	ghost1: Vec2,

	// The line segment
	segment: Segment,

	// The head ghost vertex
	ghost2: Vec2,

	// The owning chain shape index (internal usage only)
	chainId: i32,
}


@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// Validate ray cast input data (NaN, etc)
	IsValidRay :: proc(#by_ptr input: RayCastInput) -> bool ---

	// Make a convex polygon from a convex hull. This will assert if the hull is not valid.
	// @warning Do not manually fill in the hull data, it must come directly from b2ComputeHull
	MakePolygon :: proc(#by_ptr hull: Hull, radius: f32) -> Polygon ---

	// Make an offset convex polygon from a convex hull. This will assert if the hull is not valid.
	// @warning Do not manually fill in the hull data, it must come directly from b2ComputeHull
	MakeOffsetPolygon :: proc(#by_ptr hull: Hull, radius: f32, transform: Transform) -> Polygon ---

	// Make a square polygon, bypassing the need for a convex hull.
	MakeSquare :: proc(h: f32) -> Polygon ---

	// Make a box (rectangle) polygon, bypassing the need for a convex hull.
	MakeBox :: proc(hx, hy: f32) -> Polygon ---

	// Make a rounded box, bypassing the need for a convex hull.
	MakeRoundedBox :: proc(hx, hy: f32, radius: f32) -> Polygon ---

	// Make an offset box, bypassing the need for a convex hull.
	MakeOffsetBox :: proc(hx, hy: f32, center: Vec2, angle: f32) -> Polygon ---

	// Transform a polygon. This is useful for transferring a shape from one body to another.
	TransformPolygon :: proc(transform: Transform, #by_ptr polygon: Polygon) -> Polygon ---

	// Compute mass properties of a circle
	ComputeCircleMass :: proc(#by_ptr shape: Circle, density: f32) -> MassData ---

	// Compute mass properties of a capsule
	ComputeCapsuleMass :: proc(#by_ptr shape: Capsule, density: f32) -> MassData ---

	// Compute mass properties of a polygon
	ComputePolygonMass :: proc(#by_ptr shape: Polygon, density: f32) -> MassData ---

	// Compute the bounding box of a transformed circle
	ComputeCircleAABB :: proc(#by_ptr shape: Circle, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed capsule
	ComputeCapsuleAABB :: proc(#by_ptr shape: Capsule, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed polygon
	ComputePolygonAABB :: proc(#by_ptr shape: Polygon, transform: Transform) -> AABB ---

	// Compute the bounding box of a transformed line segment
	ComputeSegmentAABB :: proc(#by_ptr shape: Segment, transform: Transform) -> AABB ---

	// Test a point for overlap with a circle in local space
	PointInCircle :: proc(point: Vec2, #by_ptr shape: Circle) -> bool ---

	// Test a point for overlap with a capsule in local space
	PointInCapsule :: proc(point: Vec2, #by_ptr shape: Capsule) -> bool ---

	// Test a point for overlap with a convex polygon in local space
	PointInPolygon :: proc(point: Vec2, #by_ptr shape: Polygon) -> bool ---

	// Ray cast versus circle in shape local space. Initial overlap is treated as a miss.
	RayCastCircle :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Circle) -> CastOutput ---

	// Ray cast versus capsule in shape local space. Initial overlap is treated as a miss.
	RayCastCapsule :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Capsule) -> CastOutput ---

	// Ray cast versus segment in shape local space. Optionally treat the segment as one-sided with hits from
	// the left side being treated as a miss.
	RayCastSegment :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Segment, oneSided: bool) -> CastOutput ---

	// Ray cast versus polygon in shape local space. Initial overlap is treated as a miss.
	RayCastPolygon :: proc(#by_ptr input: RayCastInput, #by_ptr shape: Polygon) -> CastOutput ---

	// Shape cast versus a circle. Initial overlap is treated as a miss.
	ShapeCastCircle :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Circle) -> CastOutput ---

	// Shape cast versus a capsule. Initial overlap is treated as a miss.
	ShapeCastCapsule :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Capsule) -> CastOutput ---

	// Shape cast versus a line segment. Initial overlap is treated as a miss.
	ShapeCastSegment :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Segment) -> CastOutput ---

	// Shape cast versus a convex polygon. Initial overlap is treated as a miss.
	ShapeCastPolygon :: proc(#by_ptr input: ShapeCastInput, #by_ptr shape: Polygon) -> CastOutput ---
}

// A convex hull. Used to create convex polygons.
//	@warning Do not modify these values directly, instead use b2ComputeHull()
Hull :: struct {
	// The final points of the hull
	points: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count: i32,
}

// Compute the convex hull of a set of points. Returns an empty hull if it fails.
// Some failure cases:
// - all points very close together
// - all points on a line
// - less than 3 points
// - more than maxPolygonVertices points
// This welds close points and removes collinear points.
//	@warning Do not modify a hull once it has been computed
ComputeHull :: proc "c" (points: []Vec2) -> Hull {
	foreign lib {
		b2ComputeHull :: proc "c" (points: [^]Vec2, count: i32) -> Hull ---
	}
	return b2ComputeHull(raw_data(points), i32(len(points)))
}


@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// This determines if a hull is valid. Checks for:
	// - convexity
	// - collinear points
	// This is expensive and should not be called at runtime.
	ValidateHull :: proc(#by_ptr hull: Hull) -> bool ---
}

/**
 * @defgroup distance Distance
 * Functions for computing the distance between shapes.
 *
 * These are advanced functions you can use to perform distance calculations. There
 * are functions for computing the closest points between shapes, doing linear shape casts,
 * and doing rotational shape casts. The latter is called time of impact (TOI).
 */

// Result of computing the distance between two line segments
SegmentDistanceResult :: struct {
	// The closest point on the first segment
	closest1: Vec2,

	// The closest point on the second segment
	closest2: Vec2,

	// The barycentric coordinate on the first segment
	fraction1: f32,

	// The barycentric coordinate on the second segment
	fraction2: f32,

	// The squared distance between the closest points
	distanceSquared: f32,
}

@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// Compute the distance between two line segments, clamping at the end points if needed.
	SegmentDistance :: proc(p1, q1: Vec2, p2, q2: Vec2) -> SegmentDistanceResult ---
}

// A distance proxy is used by the GJK algorithm. It encapsulates any shape.
DistanceProxy :: struct {
	// The point cloud
	points: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count: i32,

	// The external radius of the point cloud
	radius: f32,
}

// Used to warm start b2Distance. Set count to zero on first call or
//	use zero initialization.
DistanceCache :: struct {
	// The number of stored simplex points
	count: u16,

	// The cached simplex indices on shape A
	indexA: [3]u8 `fmt:"v,count"`,

	// The cached simplex indices on shape B
	indexB: [3]u8 `fmt:"v,count"`,
}

emptyDistanceCache :: DistanceCache{}

// Input for b2ShapeDistance
DistanceInput :: struct {
	// The proxy for shape A
	proxyA: DistanceProxy,

	// The proxy for shape B
	proxyB: DistanceProxy,

	// The world transform for shape A
	transformA: Transform,

	// The world transform for shape B
	transformB: Transform,

	// Should the proxy radius be considered?
	useRadii: bool,
}

// Output for b2ShapeDistance
DistanceOutput :: struct {
	pointA:       Vec2, // Closest point on shapeA
	pointB:       Vec2, // Closest point on shapeB
	distance:     f32,  // The final distance, zero if overlapped
	iterations:   i32,  // Number of GJK iterations used
	simplexCount: i32,  // The number of simplexes stored in the simplex array
}

// Simplex vertex for debugging the GJK algorithm
SimplexVertex :: struct {
	wA:     Vec2, // support point in proxyA
	wB:     Vec2, // support point in proxyB
	w:      Vec2, // wB - wA
	a:      f32,  // barycentric coordinate for closest point
	indexA: i32,  // wA index
	indexB: i32,  // wB index
}

// Simplex from the GJK algorithm
Simplex :: struct {
	v1, v2, v3: SimplexVertex `fmt:"v,count"`, // vertices
	count: i32, // number of valid vertices
}

// Input parameters for b2ShapeCast
ShapeCastPairInput :: struct {
	proxyA:       DistanceProxy, // The proxy for shape A
	proxyB:       DistanceProxy, // The proxy for shape B
	transformA:   Transform, // The world transform for shape A
	transformB:   Transform, // The world transform for shape B
	translationB: Vec2, // The translation of shape B
	maxFraction:  f32, // The fraction of the translation to consider, typically 1
}


// This describes the motion of a body/shape for TOI computation. Shapes are defined with respect to the body origin,
// which may not coincide with the center of mass. However, to support dynamics we must interpolate the center of mass
// position.
Sweep :: struct {
	localCenter: Vec2, // Local center of mass position
	c1:          Vec2, // Starting center of mass world position
	c2:          Vec2, // Ending center of mass world position
	q1:          Rot,  // Starting world rotation
	q2:          Rot,  // Ending world rotation
}

// Input parameters for b2TimeOfImpact
TOIInput :: struct {
	proxyA: DistanceProxy, // The proxy for shape A
	proxyB: DistanceProxy, // The proxy for shape B
	sweepA: Sweep,         // The movement of shape A
	sweepB: Sweep,         // The movement of shape B
	tMax:   f32,           // Defines the sweep interval [0, tMax]
}

// Describes the TOI output
TOIState :: enum c.int {
	Unknown,
	Failed,
	Overlapped,
	Hit,
	Separated,
}

// Output parameters for b2TimeOfImpact.
TOIOutput :: struct {
	state: TOIState, // The type of result
	t: f32,          // The time of the collision
}

// Compute the closest points between two shapes represented as point clouds.
// DistanceCache cache is input/output. On the first call set DistanceCache.count to zero.
//	The underlying GJK algorithm may be debugged by passing in debug simplexes and capacity. You may pass in NULL and 0 for these.
ShapeDistance :: proc "c" (cache: ^DistanceCache, #by_ptr input: DistanceInput, simplexes: []Simplex) -> DistanceOutput {
	foreign lib {
		b2ShapeDistance :: proc "c" (cache: ^DistanceCache, #by_ptr input: DistanceInput, simplexes: [^]Simplex, simplexCapacity: c.int) -> DistanceOutput ---
	}
	return b2ShapeDistance(cache, input, raw_data(simplexes), i32(len(simplexes)))
}


// Make a proxy for use in GJK and related functions.
MakeProxy :: proc "c" (vertices: []Vec2, radius: f32) -> DistanceProxy {
	foreign lib {
		b2MakeProxy :: proc "c" (vertices: [^]Vec2, count: i32, radius: f32) -> DistanceProxy ---
	}
	return b2MakeProxy(raw_data(vertices), i32(len(vertices)), radius)
}


@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// Perform a linear shape cast of shape B moving and shape A fixed. Determines the hit point, normal, and translation fraction.
	ShapeCast :: proc(#by_ptr input: ShapeCastPairInput) -> CastOutput ---

	// Evaluate the transform sweep at a specific time.
	GetSweepTransform :: proc(#by_ptr sweep: Sweep, time: f32) -> Transform ---

	// Compute the upper bound on time before two shapes penetrate. Time is represented as
	// a fraction between [0,tMax]. This uses a swept separating axis and may miss some intermediate,
	// non-tunneling collisions. If you change the time interval, you should call this function
	// again.
	TimeOfImpact :: proc(#by_ptr input: TOIInput) -> TOIOutput ---
}


/**
 * @defgroup collision Collision
 * @brief Functions for colliding pairs of shapes
 */

// A manifold point is a contact point belonging to a contact
// manifold. It holds details related to the geometry and dynamics
// of the contact points.
ManifoldPoint :: struct {
	// Location of the contact point in world space. Subject to precision loss at large coordinates.
	//	@note Should only be used for debugging.
	point: Vec2,

	// Location of the contact point relative to bodyA's origin in world space
	//	@note When used internally to the Box2D solver, these are relative to the center of mass.
	anchorA: Vec2,

	// Location of the contact point relative to bodyB's origin in world space
	anchorB: Vec2,

	// The separation of the contact point, negative if penetrating
	separation: f32,

	// The impulse along the manifold normal vector.
	normalImpulse: f32,

	// The friction impulse
	tangentImpulse: f32,

	// The maximum normal impulse applied during sub-stepping
	//	todo not sure this is needed
	maxNormalImpulse: f32,

	// Relative normal velocity pre-solve. Used for hit events. If the normal impulse is
	// zero then there was no hit. Negative means shapes are approaching.
	normalVelocity: f32,

	// Uniquely identifies a contact point between two shapes
	id: u16,

	// Did this contact point exist the previous step?
	persisted: bool,
}

// A contact manifold describes the contact points between colliding shapes
Manifold :: struct {
	// The manifold points, up to two are possible in 2D
	points: [2]ManifoldPoint,

	// The unit normal vector in world space, points from shape A to bodyB
	normal: Vec2,

	// The number of contacts points, will be 0, 1, or 2
	pointCount: i32,
}

@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// Compute the contact manifold between two circles
	CollideCircles :: proc(#by_ptr circleA: Circle, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a capsule and circle
	CollideCapsuleAndCircle :: proc(#by_ptr capsuleA: Capsule, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a circle
	CollideSegmentAndCircle :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a polygon and a circle
	CollidePolygonAndCircle :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a capsule and circle
	CollideCapsules :: proc(#by_ptr capsuleA: Capsule, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a capsule
	CollideSegmentAndCapsule :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a polygon and capsule
	CollidePolygonAndCapsule :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between two polygons
	CollidePolygons :: proc(#by_ptr polygonA: Polygon, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a polygon
	CollideSegmentAndPolygon :: proc(#by_ptr segmentA: Segment, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between a smooth segment and a circle
	CollideSmoothSegmentAndCircle :: proc(#by_ptr smoothSegmentA: SmoothSegment, xfA: Transform, #by_ptr circleB: Circle, xfB: Transform) -> Manifold ---

	// Compute the contact manifold between an segment and a capsule
	CollideSmoothSegmentAndCapsule :: proc(#by_ptr smoothSegmentA: SmoothSegment, xfA: Transform, #by_ptr capsuleB: Capsule, xfB: Transform, cache: ^DistanceCache) -> Manifold ---

	// Compute the contact manifold between a smooth segment and a rounded polygon
	CollideSmoothSegmentAndPolygon :: proc(#by_ptr smoothSegmentA: SmoothSegment, xfA: Transform, #by_ptr polygonB: Polygon, xfB: Transform, cache: ^DistanceCache) -> Manifold ---
}


/**
 * @defgroup tree Dynamic Tree
 * The dynamic tree is a binary AABB tree to organize and query large numbers of geometric objects
 *
 * Box2D uses the dynamic tree internally to sort collision shapes into a binary bounding volume hierarchy.
 * This data structure may have uses in games for organizing other geometry data and may be used independently
 * of Box2D rigid body simulation.
 *
 * A dynamic AABB tree broad-phase, inspired by Nathanael Presson's btDbvt.
 * A dynamic tree arranges data in a binary tree to accelerate
 * queries such as AABB queries and ray casts. Leaf nodes are proxies
 * with an AABB. These are used to hold a user collision object, such as a reference to a b2Shape.
 * Nodes are pooled and relocatable, so I use node indices rather than pointers.
 * The dynamic tree is made available for advanced users that would like to use it to organize
 * spatial game data besides rigid bodies.
 *
 * @note This is an advanced feature and normally not used by applications directly.
 */

// The default category bit for a tree proxy. Used for collision filtering.
defaultCategoryBits :: 0x00000001

// Convenience mask bits to use when you don't need collision filtering and just want
//	all results.
defaultMaskBits :: 0xFFFFFFFF

// A node in the dynamic tree. This is private data placed here for performance reasons.
// 16 + 16 + 8 + pad(8)
TreeNode :: struct {
	// The node bounding box
	aabb: AABB, // 16

	// Category bits for collision filtering
	categoryBits: u32, // 4

	using _: struct #raw_union {
		// The node parent index
		parent: i32,

		// The node freelist next index
		next: i32,
	}, // 4

	// Child 1 index
	child1: i32, // 4

	// Child 2 index
	child2: i32, // 4

	// User data
	// todo could be union with child index
	userData: i32, // 4

	// Leaf = 0, free node = -1
	height: i16, // 2

	// Has the AABB been enlarged?
	enlarged: bool, // 1

	// Padding for clarity
	pad: [9]byte,
}

// The dynamic tree structure. This should be considered private data.
// It is placed here for performance reasons.
DynamicTree :: struct {
	// The tree nodes
	nodes: [^]TreeNode `fmt"v,nodeCount"`,

	// The root index
	root: i32,

	// The number of nodes
	nodeCount: i32,

	// The allocated node space
	nodeCapacity: i32,

	// Node free list
	freeList: i32,

	// Number of proxies created
	proxyCount: i32,

	// Leaf indices for rebuild
	leafIndices: [^]i32,

	// Leaf bounding boxes for rebuild
	leafBoxes: [^]AABB,

	// Leaf bounding box centers for rebuild
	leafCenters: [^]Vec2,

	// Bins for sorting during rebuild
	binIndices: [^]i32,

	// Allocated space for rebuilding
	rebuildCapacity: i32,
}

// This function receives proxies found in the AABB query.
// @return true if the query should continue
TreeQueryCallbackFcn :: #type proc "c" (proxyId: i32, userData: i32, ctx: rawptr) -> bool

// This function receives clipped ray-cast input for a proxy. The function
// returns the new ray fraction.
// - return a value of 0 to terminate the ray-cast
// - return a value less than input->maxFraction to clip the ray
// - return a value of input->maxFraction to continue the ray cast without clipping
TreeShapeCastCallbackFcn :: #type proc "c" (#by_ptr input: ShapeCastInput, proxyId: i32, userData: i32, ctx: rawptr) -> f32


// This function receives clipped raycast input for a proxy. The function
// returns the new ray fraction.
// - return a value of 0 to terminate the ray cast
// - return a value less than input->maxFraction to clip the ray
// - return a value of input->maxFraction to continue the ray cast without clipping
TreeRayCastCallbackFcn :: #type proc "c" (#by_ptr input: RayCastInput, proxyId: i32, userData: i32, ctx: rawptr) -> f32

@(link_prefix="b2", default_calling_convention="c")
foreign lib {
	// Constructing the tree initializes the node pool.
	DynamicTree_Create :: proc() -> DynamicTree ---

	// Destroy the tree, freeing the node pool.
	DynamicTree_Destroy :: proc(tree: ^DynamicTree) ---

	// Create a proxy. Provide an AABB and a userData value.
	DynamicTree_CreateProxy :: proc(tree: ^DynamicTree, aabb: AABB, categoryBits: u32, userData: i32) -> i32 ---

	// Destroy a proxy. This asserts if the id is invalid.
	DynamicTree_DestroyProxy :: proc(tree: ^DynamicTree, proxyId: i32) ---

	// Move a proxy to a new AABB by removing and reinserting into the tree.
	DynamicTree_MoveProxy :: proc(tree: ^DynamicTree, proxyId: i32, aabb: AABB) ---

	// Enlarge a proxy and enlarge ancestors as necessary.
	DynamicTree_EnlargeProxy :: proc(tree: ^DynamicTree, proxyId: i32, aabb: AABB) ---

	// Query an AABB for overlapping proxies. The callback class
	// is called for each proxy that overlaps the supplied AABB.
	DynamicTree_Query :: proc(#by_ptr tree: DynamicTree, aabb: AABB, maskBits: u32, callback: TreeQueryCallbackFcn, ctx: rawptr) ---

	// Ray-cast against the proxies in the tree. This relies on the callback
	// to perform a exact ray-cast in the case were the proxy contains a shape.
	// The callback also performs the any collision filtering. This has performance
	// roughly equal to k * log(n), where k is the number of collisions and n is the
	// number of proxies in the tree.
	//	Bit-wise filtering using mask bits can greatly improve performance in some scenarios.
	//	@param tree the dynamic tree to ray cast
	// @param input the ray-cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1)
	//	@param maskBits filter bits: `bool accept = (maskBits & node->categoryBits) != 0 ---`
	// @param callback a callback class that is called for each proxy that is hit by the ray
	//	@param context user context that is passed to the callback
	DynamicTree_RayCast :: proc(#by_ptr tree: DynamicTree, #by_ptr input: RayCastInput, maskBits: u32, callback: TreeRayCastCallbackFcn, ctx: rawptr) ---

	// Ray-cast against the proxies in the tree. This relies on the callback
	// to perform a exact ray-cast in the case were the proxy contains a shape.
	// The callback also performs the any collision filtering. This has performance
	// roughly equal to k * log(n), where k is the number of collisions and n is the
	// number of proxies in the tree.
	//	@param tree the dynamic tree to ray cast
	// @param input the ray-cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1).
	//	@param maskBits filter bits: `bool accept = (maskBits & node->categoryBits) != 0 ---`
	// @param callback a callback class that is called for each proxy that is hit by the shape
	//	@param context user context that is passed to the callback
	DynamicTree_ShapeCast :: proc(#by_ptr tree: DynamicTree, #by_ptr input: ShapeCastInput, maskBits: u32, callback: TreeShapeCastCallbackFcn, ctx: rawptr) ---

	// Validate this tree. For testing.
	DynamicTree_Validate :: proc(#by_ptr tree: DynamicTree) ---

	// Compute the height of the binary tree in O(N) time. Should not be
	// called often.
	DynamicTree_GetHeight :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Get the maximum balance of the tree. The balance is the difference in height of the two children of a node.
	DynamicTree_GetMaxBalance :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Get the ratio of the sum of the node areas to the root area.
	DynamicTree_GetAreaRatio :: proc(#by_ptr tree: DynamicTree) -> f32 ---

	// Build an optimal tree. Very expensive. For testing.
	DynamicTree_RebuildBottomUp :: proc(tree: ^DynamicTree) ---

	// Get the number of proxies created
	DynamicTree_GetProxyCount :: proc(#by_ptr tree: DynamicTree) -> c.int ---

	// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
	DynamicTree_Rebuild :: proc(tree: ^DynamicTree, fullBuild: bool) -> c.int ---

	// Shift the world origin. Useful for large worlds.
	// The shift formula is: position -= newOrigin
	// @param tree the tree to shift
	// @param newOrigin the new origin with respect to the old origin
	DynamicTree_ShiftOrigin :: proc(tree: ^DynamicTree, newOrigin: Vec2) ---

	// Get the number of bytes used by this tree
	DynamicTree_GetByteCount :: proc(#by_ptr tree: DynamicTree) -> c.int ---
}

// Get proxy user data
// @return the proxy user data or 0 if the id is invalid
DynamicTree_GetUserData :: proc "contextless" (tree: DynamicTree, proxyId: i32) -> i32 {
	return tree.nodes[proxyId].userData
}

// Get the AABB of a proxy
DynamicTree_GetAABB :: proc "contextless" (tree: DynamicTree, proxyId: i32) -> AABB {
	return tree.nodes[proxyId].aabb
}
