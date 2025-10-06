package vendor_box2d

import "core:c"


// The maximum number of vertices on a convex polygon. Changing this affects performance even if you
//	don't use more vertices.
MAX_POLYGON_VERTICES :: 8

// Low level ray cast input data
RayCastInput :: struct {
	// Start point of the ray cast
	origin:      Vec2,

	// Translation of the ray cast
	translation: Vec2,

	// The maximum fraction of the translation to consider, typically 1
	maxFraction: f32,
}

// A distance proxy is used by the GJK algorithm. It encapsulates any shape.
// You can provide between 1 and MAX_POLYGON_VERTICES and a radius.
ShapeProxy :: struct {
	// The point cloud
	points: [MAX_POLYGON_VERTICES]Vec2 `fmt:"v,count"`,

	// The number of points. Must be greater than 0.
	count:  c.int,

	// The external radius of the point cloud. May be zero.
	radius: f32,
}

// Low level shape cast input in generic form. This allows casting an arbitrary point
// cloud wrap with a radius. For example, a circle is a single point with a non-zero radius.
// A capsule is two points with a non-zero radius. A box is four points with a zero radius.
ShapeCastInput :: struct {
	// A generic shape
	proxy:       ShapeProxy,

	// The translation of the shape cast
	translation: Vec2,

	// The maximum fraction of the translation to consider, typically 1
	maxFraction: f32,

	// Allow shape cast to encroach when initially touching. This only works if the radius is greater than zero.
	canEncroach: bool,
}

// Low level ray cast or shape-cast output data
CastOutput :: struct {
	// The surface normal at the hit point
	normal:     Vec2,

	// The surface hit point
	point:      Vec2,

	// The fraction of the input translation at collision
	fraction:   f32,

	// The number of iterations used
	iterations: c.int,

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
// Polygons have a maximum number of vertices equal to MAX_POLYGON_VERTICES.
// In most cases you should not need many vertices for a convex polygon.
// @warning DO NOT fill this out manually, instead use a helper function like
// b2MakePolygon or b2MakeBox.
Polygon :: struct {
	// The polygon vertices
	vertices: [MAX_POLYGON_VERTICES]Vec2 `fmt:"v,count"`,

	// The outward normal vectors of the polygon sides
	normals:  [MAX_POLYGON_VERTICES]Vec2 `fmt:"v,count"`,

	// The centroid of the polygon
	centroid: Vec2,

	// The external radius for rounded polygons
	radius:   f32,

	// The number of polygon vertices
	count:    c.int,
}

// A line segment with two-sided collision.
Segment :: struct {
	// The first point
	point1: Vec2,

	// The second point
	point2: Vec2,
}

// A line segment with one-sided collision. Only collides on the right side.
// Several of these are generated for a chain shape.
// ghost1 -> point1 -> point2 -> ghost2
ChainSegment :: struct {
	// The tail ghost vertex
	ghost1:  Vec2,

	// The line segment
	segment: Segment,

	// The head ghost vertex
	ghost2:  Vec2,

	// The owning chain shape index (internal usage only)
	chainId: c.int,
}


// A convex hull. Used to create convex polygons.
//	@warning Do not modify these values directly, instead use b2ComputeHull()
Hull :: struct {
	// The final points of the hull
	points: [MAX_POLYGON_VERTICES]Vec2 `fmt:"v,count"`,

	// The number of points
	count:  c.int,
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

// Used to warm start the GJK simplex. If you call this function multiple times with nearby
// transforms this might improve performance. Otherwise you can zero initialize this.
// The distance cache must be initialized to zero on the first call.
// Users should generally just zero initialize this structure for each call.
SimplexCache :: struct {
	// The number of stored simplex points
	count: u16,

	// The cached simplex indices on shape A
	indexA: [3]u8 `fmt:"v,count"`,

	// The cached simplex indices on shape B
	indexB: [3]u8 `fmt:"v,count"`,
}

emptySimplexCache :: SimplexCache{}

// Input for b2ShapeDistance
DistanceInput :: struct {
	// The proxy for shape A
	proxyA: ShapeProxy,

	// The proxy for shape B
	proxyB: ShapeProxy,

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
	normal:       Vec2, // Normal vector that points from A to B
	distance:     f32,  // The final distance, zero if overlapped
	iterations:   i32,  // Number of GJK iterations used
	simplexCount: i32,  // The number of simplexes stored in the simplex array
}

// Simplex vertex for debugging the GJK algorithm
SimplexVertex :: struct {
	wA:     Vec2,  // support point in proxyA
	wB:     Vec2,  // support point in proxyB
	w:      Vec2,  // wB - wA
	a:      f32,   // barycentric coordinate for closest point
	indexA: c.int, // wA index
	indexB: c.int, // wB index
}

// Simplex from the GJK algorithm
Simplex :: struct {
	v1, v2, v3: SimplexVertex `fmt:"v,count"`, // vertices
	count: c.int, // number of valid vertices
}

// Input parameters for b2ShapeCast
ShapeCastPairInput :: struct {
	proxyA:       ShapeProxy, // The proxy for shape A
	proxyB:       ShapeProxy, // The proxy for shape B
	transformA:   Transform, // The world transform for shape A
	transformB:   Transform, // The world transform for shape B
	translationB: Vec2, // The translation of shape B
	maxFraction:  f32, // The fraction of the translation to consider, typically 1
	canEncroach:  bool, // Allows shapes with a radius to move slightly closer if already touching
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
	proxyA:      ShapeProxy, // The proxy for shape A
	proxyB:      ShapeProxy, // The proxy for shape B
	sweepA:      Sweep,      // The movement of shape A
	sweepB:      Sweep,      // The movement of shape B
	maxFraction: f32,        // Defines the sweep interval [0, maxFraction]
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
	state:    TOIState, // The type of result
	fraction: f32,      // The sweep time of the collision
}



/**
 * @defgroup collision Collision
 * @brief Functions for colliding pairs of shapes
 */

// A manifold point is a contact point belonging to a contact manifold.
// It holds details related to the geometry and dynamics of the contact points.
// Box2D uses speculative collision so some contact points may be separated.
// You may use the totalNormalImpulse to determine if there was an interaction during
// the time step.
ManifoldPoint :: struct {
	// Location of the contact point in world space. Subject to precision loss at large coordinates.
	//	@note Should only be used for debugging.
	point:            Vec2,

	// Location of the contact point relative to shapeA's origin in world space
	//	@note When used internally to the Box2D solver, this is relative to the body center of mass.
	anchorA:          Vec2,

	// Location of the contact point relative to shapeB's origin in world space
	// @note When used internally to the Box2D solver, this is relative to the body center of mass.
	anchorB:          Vec2,

	// The separation of the contact point, negative if penetrating
	separation:       f32,

	// The total normal impulse applied across sub-stepping and restitution. This is important
	// to identify speculative contact points that had an interaction in the time step.
	totalNormalImpulse: f32,

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

// A contact manifold describes the contact points between colliding shapes.
// @note Box2D uses speculative collision so some contact points may be separated.
Manifold :: struct {
	// The unit normal vector in world space, points from shape A to bodyB
	normal:         Vec2,

	// Angular impulse applied for rolling resistance. N * m * s = kg * m^2 / s
	rollingImpulse: f32,

	// The manifold points, up to two are possible in 2D
	points:         [2]ManifoldPoint,


	// The number of contacts points, will be 0, 1, or 2
	pointCount:     c.int,
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
 * with an AABB. These are used to hold a user collision object.
 * Nodes are pooled and relocatable, so I use node indices rather than pointers.
 * The dynamic tree is made available for advanced users that would like to use it to organize
 * spatial game data besides rigid bodies.
 */

// The dynamic tree structure. This should be considered private data.
// It is placed here for performance reasons.
DynamicTree :: struct {
	// The tree nodes
	nodes:           rawptr,

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

// These are performance results returned by dynamic tree queries.
TreeStats :: struct {
	// Number of internal nodes visited during the query
	nodeVisits: c.int,

	// Number of leaf nodes visited during the query
	leafVisits: c.int,
}

// This function receives proxies found in the AABB query.
// @return true if the query should continue
TreeQueryCallbackFcn     :: #type proc "c" (proxyId: i32, userData: u64, ctx: rawptr) -> bool

// This function receives clipped ray cast input for a proxy. The function
// returns the new ray fraction.
// - return a value of 0 to terminate the ray cast
// - return a value less than input->maxFraction to clip the ray
// - return a value of input->maxFraction to continue the ray cast without clipping
TreeShapeCastCallbackFcn :: #type proc "c" (#by_ptr input: ShapeCastInput, proxyId: i32, userData: u64, ctx: rawptr) -> f32


// This function receives clipped raycast input for a proxy. The function
// returns the new ray fraction.
// - return a value of 0 to terminate the ray cast
// - return a value less than input->maxFraction to clip the ray
// - return a value of input->maxFraction to continue the ray cast without clipping
TreeRayCastCallbackFcn   :: #type proc "c" (#by_ptr input: RayCastInput, proxyId: i32, userData: u64, ctx: rawptr) -> f32

/**@}*/

/**
 * @defgroup character Character mover
 * Character movement solver
 * @{
 */

/// These are the collision planes returned from b2World_CollideMover
PlaneResult :: struct {
	// The collision plane between the mover and convex shape
	plane: Plane,

	// Did the collision register a hit? If not this plane should be ignored.
	hit:   bool,
}

// These are collision planes that can be fed to b2SolvePlanes. Normally
// this is assembled by the user from plane results in b2PlaneResult
CollisionPlane :: struct {
	// The collision plane between the mover and some shape
	plane:        Plane,

	// Setting this to FLT_MAX makes the plane as rigid as possible. Lower values can
	// make the plane collision soft. Usually in meters.
	pushLimit:    f32,

	// The push on the mover determined by b2SolvePlanes. Usually in meters.
	push:         f32,

	// Indicates if b2ClipVector should clip against this plane. Should be false for soft collision.
	clipVelocity: bool,
}

// Result returned by b2SolvePlanes
PlaneSolverResult :: struct {
	// The final position of the mover
	position:       Vec2,

	// The number of iterations used by the plane solver. For diagnostics.
	iterationCount: i32,
}
