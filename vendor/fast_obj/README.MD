# fast_obj

Because the world needs another OBJ loader.
Single header library, should compile without warnings in both C89 or C++.
Much faster (5-10x) than other libraries tested.

To use:

     mesh := fast_obj.read("path/to/objfile.obj")

     ...do stuff with mesh...

     fast_obj.destroy(mesh);

Note that valid indices in the `Mesh.indices` array start from `1`.  A dummy position, normal and
texture coordinate are added to the corresponding `Mesh` arrays at element `0` and then an index
of `0` is used to indicate that attribute is not present at the vertex.  This means that users can avoid
the need to test for non-present data if required as the vertices will still reference a valid entry in
the mesh arrays.

A simple test app is provided to compare speed against [tinyobjloader](https://github.com/syoyo/tinyobjloader) and
check output matches.

### Version 1.3

Version 1.3 makes a small change to the API.  Textures are now stored in a separate array on the
`Mesh` structure, and are referenced by index from materials, instead of being referenced
by the material directly.

