/*
Implementation of the HxA 3D asset format
HxA is a interchangeable graphics asset format.
Designed by Eskil Steenberg. @quelsolaar / eskil 'at' obsession 'dot' se / www.quelsolaar.com

Author of this Odin package: Ginger Bill

Following comment is copied from the original C-implementation  
---------  
- Does the world need another Graphics file format?  
Unfortunately, Yes. All existing formats are either too large and complicated to be implemented from
scratch, or don't have some basic features needed in modern computer graphics.

- Who is this format for?  
For people who want a capable open Graphics format that can be implemented from scratch in
a few hours. It is ideal for graphics researchers, game developers or other people who
wants to build custom graphics pipelines. Given how easy it is to parse and write, it
should be easy to write utilities that process assets to preform tasks like: generating
normals, light-maps, tangent spaces, Error detection, GPU optimization, LOD generation,
and UV mapping.

- Why store images in the format when there are so many good image formats already?  
Yes there are, but only for 2D RGB/RGBA images. A lot of computer graphics rendering rely
on 1D, 3D, cube, multilayer, multi channel, floating point bitmap buffers. There almost no
formats for this kind of data. Also 3D files that reference separate image files rely on
file paths, and this often creates issues when the assets are moved. By including the
texture data in the files directly the assets become self contained.

- Why doesn't the format support <insert whatever>?  
Because the entire point is to make a format that can be implemented. Features like NURBSs,
Construction history, or BSP trees would make the format too large to serve its purpose.
The facilities of the formats to store meta data should make the format flexible enough
for most uses. Adding HxA support should be something anyone can do in a days work.

Structure:  
----------  
HxA is designed to be extremely simple to parse, and is therefore based around conventions. It has
a few basic structures, and depending on how they are used they mean different things. This means
that you can implement a tool that loads the entire file, modifies the parts it cares about and
leaves the rest intact. It is also possible to write a tool that makes all data in the file
editable without the need to understand its use. It is also possible for anyone to use the format
to store data axillary data. Anyone who wants to store data not covered by a convention can submit
a convention to extend the format. There should never be a convention for storing the same data in
two differed ways.

The data is story in a number of nodes that are stored in an array. Each node stores an array of
meta data. Meta data can describe anything you want, and a lot of conventions will use meta data
to store additional information, for things like transforms, lights, shaders and animation.
Data for Vertices, Corners, Faces, and Pixels are stored in named layer stacks. Each stack consists
of a number of named layers. All layers in the stack have the same number of elements. Each layer
describes one property of the primitive. Each layer can have multiple channels and each layer can
store data of a different type.

HaX stores 3 kinds of nodes
- Pixel data.
- Polygon geometry data.
- Meta data only.

Pixel Nodes stores pixels in a layer stack. A layer may store things like Albedo, Roughness,
Reflectance, Light maps, Masks, Normal maps, and Displacement. Layers use the channels of the
layers to store things like color.
The length of the layer stack is determined by the type and dimensions stored in the Geometry data
is stored in 3 separate layer stacks for: vertex data, corner data and face data. The
vertex data stores things like verities, blend shapes, weight maps, and vertex colors. The first
layer in a vertex stack has to be a 3 channel layer named "position" describing the base position
of the vertices. The corner stack describes data per corner or edge of the polygons. It can be used
for things like UV, normals, and adjacency. The first layer in a corner stack has to be a 1 channel
integer layer named "index" describing the vertices used to form polygons. The last value in each
polygon has a negative - 1 index to indicate the end of the polygon.

For Example:
	A quad and a tri with the vertex index:
		[0, 1, 2, 3] [1, 4, 2]
	is stored:
		[0, 1, 2, -4, 1, 4, -3]

The face stack stores values per face. the length of the face stack has to match the number of
negative values in the index layer in the corner stack. The face stack can be used to store things
like material index.

Storage:  
-------  
All data is stored in little endian byte order with no padding. The layout mirrors the structs
defined below with a few exceptions. All names are stored as a 8-bit unsigned integer indicating
the length of the name followed by that many characters. Termination is not stored in the file.
Text strings stored in meta data are stored the same way as names, but instead of a 8-bit unsigned
integer a 32-bit unsigned integer is used.
*/
package encoding_hxa
