
SDL_image 2.0

The latest version of this library is available from GitHub:
https://github.com/libsdl-org/SDL_image/releases

This is a simple library to load images of various formats as SDL surfaces.
It can load BMP, GIF, JPEG, LBM, PCX, PNG, PNM (PPM/PGM/PBM), QOI, TGA, XCF, XPM, and simple SVG format images. It can also load AVIF, JPEG-XL, TIFF, and WebP images, depending on build options (see the note below for details.)

API:
#include "SDL_image.h"

	SDL_Surface *IMG_Load(const char *file);
or
	SDL_Surface *IMG_Load_RW(SDL_RWops *src, int freesrc);
or
	SDL_Surface *IMG_LoadTyped_RW(SDL_RWops *src, int freesrc, char *type);

where type is a string specifying the format (i.e. "PNG" or "pcx").
Note that IMG_Load_RW cannot load TGA images.

To create a surface from an XPM image included in C source, use:

	SDL_Surface *IMG_ReadXPMFromArray(char **xpm);

An example program 'showimage' is included, with source in 'examples/showimage.c'

Documentation is also available online at https://wiki.libsdl.org/SDL2_image

This library is under the zlib License, see the file "LICENSE.txt" for details.

Note:
Support for AVIF, JPEG-XL, TIFF, and WebP are not included by default because of the size of the decode libraries, but you can get them by running external/download.sh
- When building with CMake, you can enable the appropriate SDL2IMAGE_* options defined in CMakeLists.txt. SDL2IMAGE_VENDORED allows switching between system and vendored libraries.
- When building with configure/make, you can build and install them normally and the configure script will detect and use them.
- When building with Visual Studio, you will need to build the libraries and then add the appropriate LOAD_* preprocessor define to the Visual Studio project.
- When building with Xcode, you can edit the config at the top of the project to enable them, and you will need to include the appropriate framework in your application.
- For Android, you can edit the config at the top of Android.mk to enable them.
