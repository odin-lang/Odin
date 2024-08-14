package vendor_box2d

import "core:c"


// The maximum number of vertices on a convex polygon. Changing this affects performance even if you
//	don't use more vertices.
maxPolygonVertices :: 8

// Low level ray-cast input data
RayCastInput :: struct {
	// Start point of the ray cast
	origin:      Vec2,

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
	points:      [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count:       i32,

	// The radius around the point cloud
	radius:      f32,

	// The translation of the shape cast
	translation: Vec2,

	// The maximum fraction of the translation to consider, typically 1
	maxFraction: f32,
}

// Low level ray-cast or shape-cast output data
CastOutput :: struct {
	// The surface normal at the hit point
	normal:     Vec2,

	// The surface hit point
	point:      Vec2,

	// The fraction of the input translation at collision
	fraction:   f32,

	// The number of iterations used
	iterations: i32,

	// Did the cast hit?
	hit:        bool,
}

// This holds the mass data computed for a shape.
MassData :: struct {
	// The mass of the shape, usually in kilograms.
	mass:              f32,

	// The position of the shape's centroid relative to the shape's origin.
	center:            Vec2,

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
	radius:  f32,
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
	normals:  [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The centroid of the polygon
	centroid: Vec2,

	// The external radius for rounded polygons
	radius:   f32,

	// The number of polygon vertices
	count:    i32,
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
	ghost1:  Vec2,

	// The line segment
	segment: Segment,

	// The head ghost vertex
	ghost2:  Vec2,

	// The owning chain shape index (internal usage only)
	chainId: i32,
}


// A convex hull. Used to create convex polygons.
//	@warning Do not modify these values directly, instead use b2ComputeHull()
Hull :: struct {
	// The final points of the hull
	points: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count:  i32,
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
	closest1:        Vec2,

	// The closest point on the second segment
	closest2:        Vec2,

	// The barycentric coordinate on the first segment
	fraction1:       f32,

	// The barycentric coordinate on the second segment
	fraction2:       f32,

	// The squared distance between the closest points
	distanceSquared: f32,
}

// A distance proxy is used by the GJK algorithm. It encapsulates any shape.
DistanceProxy :: struct {
	// The point cloud
	points: [maxPolygonVertices]Vec2 `fmt:"v,count"`,

	// The number of points
	count:  i32,

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
	t:     f32,      // The time of the collision
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
	point:            Vec2,

	// Location of the contact point relative to bodyA's origin in world space
	//	@note When used internally to the Box2D solver, these are relative to the center of mass.
	anchorA:          Vec2,

	// Location of the contact point relative to bodyB's origin in world space
	anchorB:          Vec2,

	// The separation of the contact point, negative if penetrating
	separation:       f32,

	// The impulse along the manifold normal vector.
	normalImpulse:    f32,

	// The friction impulse
	tangentImpulse:   f32,

	// The maximum normal impulse applied during sub-stepping
	//	todo not sure this is needed
	maxNormalImpulse: f32,

	// Relative normal velocity pre-solve. Used for hit events. If the normal impulse is
	// zero then there was no hit. Negative means shapes are approaching.
	normalVelocity:   f32,

	// Uniquely identifies a contact point between two shapes
	id:               u16,

	// Did this contact point exist the previous step?
	persisted:        bool,
}

// A contact manifold describes the contact points between colliding shapes
Manifold :: struct {
	// The manifold points, up to two are possible in 2D
	points:     [2]ManifoldPoint,

	// The unit normal vector in world space, points from shape A to bodyB
	normal:     Vec2,

	// The number of contacts points, will be 0, 1, or 2
	pointCount: i32,
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
		next:   i32,
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
	_: [9]byte,
}

// The dynamic tree structure. This should be considered private data.
// It is placed here for performance reasons.
DynamicTree :: struct {
	// The tree nodes
	nodes:           [^]TreeNode `fmt"v,nodeCount"`,

	// The root index
	root:            i32,

	// The number of nodes
	nodeCount:       i32,

	// The allocated node space
	nodeCapacity:    i32,

	// Node free list
	freeList:        i32,

	// Number of proxies created
	proxyCount:      i32,

	// Leaf indices for rebuild
	leafIndices:     [^]i32,

	// Leaf bounding boxes for rebuild
	leafBoxes:       [^]AABB,

	// Leaf bounding box centers for rebuild
	leafCenters:     [^]Vec2,

	// Bins for sorting during rebuild
	binIndices:      [^]i32,

	// Allocated space for rebuilding
	rebuildCapacity: i32,
}

// This function receives proxies found in the AABB query.
// @return true if the query should continue
TreeQueryCallbackFcn     :: #type proc "c" (proxyId: i32, userData: i32, ctx: rawptr) -> bool

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
TreeRayCastCallbackFcn   :: #type proc "c" (#by_ptr input: RayCastInput, proxyId: i32, userData: i32, ctx: rawptr) -> f32
