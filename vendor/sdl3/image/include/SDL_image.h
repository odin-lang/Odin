/*
  SDL_image:  An example image loading library for use with SDL
  Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/* WIKI CATEGORY: SDLImage */

/**
 * # CategorySDLImage
 *
 * Header file for SDL_image library
 *
 * A simple library to load images of various formats as SDL surfaces
 */

#ifndef SDL_IMAGE_H_
#define SDL_IMAGE_H_

#include <SDL3/SDL.h>
#include <SDL3/SDL_begin_code.h>

/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

/**
 * Printable format: "%d.%d.%d", MAJOR, MINOR, MICRO
 */
#define SDL_IMAGE_MAJOR_VERSION 3
#define SDL_IMAGE_MINOR_VERSION 2
#define SDL_IMAGE_MICRO_VERSION 4

/**
 * This is the version number macro for the current SDL_image version.
 */
#define SDL_IMAGE_VERSION \
    SDL_VERSIONNUM(SDL_IMAGE_MAJOR_VERSION, SDL_IMAGE_MINOR_VERSION, SDL_IMAGE_MICRO_VERSION)

/**
 * This macro will evaluate to true if compiled with SDL_image at least X.Y.Z.
 */
#define SDL_IMAGE_VERSION_ATLEAST(X, Y, Z) \
    ((SDL_IMAGE_MAJOR_VERSION >= X) && \
     (SDL_IMAGE_MAJOR_VERSION > X || SDL_IMAGE_MINOR_VERSION >= Y) && \
     (SDL_IMAGE_MAJOR_VERSION > X || SDL_IMAGE_MINOR_VERSION > Y || SDL_IMAGE_MICRO_VERSION >= Z))

/**
 * This function gets the version of the dynamically linked SDL_image library.
 *
 * \returns SDL_image version.
 *
 * \since This function is available since SDL_image 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL IMG_Version(void);

/**
 * Load an image from an SDL data source into a software surface.
 *
 * An SDL_Surface is a buffer of pixels in memory accessible by the CPU. Use
 * this if you plan to hand the data to something else or manipulate it
 * further in code.
 *
 * There are no guarantees about what format the new SDL_Surface data will be;
 * in many cases, SDL_image will attempt to supply a surface that exactly
 * matches the provided image, but in others it might have to convert (either
 * because the image is in a format that SDL doesn't directly support or
 * because it's compressed data that could reasonably uncompress to various
 * formats and SDL_image had to pick one). You can inspect an SDL_Surface for
 * its specifics, and use SDL_ConvertSurface to then migrate to any supported
 * format.
 *
 * If the image format supports a transparent pixel, SDL will set the colorkey
 * for the surface. You can enable RLE acceleration on the surface afterwards
 * by calling: SDL_SetSurfaceColorKey(image, SDL_RLEACCEL,
 * image->format->colorkey);
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * Even though this function accepts a file type, SDL_image may still try
 * other decoders that are capable of detecting file type from the contents of
 * the image data, but may rely on the caller-provided type string for formats
 * that it cannot autodetect. If `type` is NULL, SDL_image will rely solely on
 * its ability to guess the format.
 *
 * There is a separate function to read files from disk without having to deal
 * with SDL_IOStream: `IMG_Load("filename.jpg")` will call this function and
 * manage those details for you, determining the file type from the filename's
 * extension.
 *
 * There is also IMG_Load_IO(), which is equivalent to this function except
 * that it will rely on SDL_image to determine what type of data it is
 * loading, much like passing a NULL for type.
 *
 * If you are using SDL's 2D rendering API, there is an equivalent call to
 * load images directly into an SDL_Texture for use by the GPU without using a
 * software surface: call IMG_LoadTextureTyped_IO() instead.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to SDL_DestroySurface().
 *
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \param type a filename extension that represent this data ("BMP", "GIF",
 *             "PNG", etc).
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_Load
 * \sa IMG_Load_IO
 * \sa SDL_DestroySurface
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadTyped_IO(SDL_IOStream *src, bool closeio, const char *type);

/**
 * Load an image from a filesystem path into a software surface.
 *
 * An SDL_Surface is a buffer of pixels in memory accessible by the CPU. Use
 * this if you plan to hand the data to something else or manipulate it
 * further in code.
 *
 * There are no guarantees about what format the new SDL_Surface data will be;
 * in many cases, SDL_image will attempt to supply a surface that exactly
 * matches the provided image, but in others it might have to convert (either
 * because the image is in a format that SDL doesn't directly support or
 * because it's compressed data that could reasonably uncompress to various
 * formats and SDL_image had to pick one). You can inspect an SDL_Surface for
 * its specifics, and use SDL_ConvertSurface to then migrate to any supported
 * format.
 *
 * If the image format supports a transparent pixel, SDL will set the colorkey
 * for the surface. You can enable RLE acceleration on the surface afterwards
 * by calling: SDL_SetSurfaceColorKey(image, SDL_RLEACCEL,
 * image->format->colorkey);
 *
 * There is a separate function to read files from an SDL_IOStream, if you
 * need an i/o abstraction to provide data from anywhere instead of a simple
 * filesystem read; that function is IMG_Load_IO().
 *
 * If you are using SDL's 2D rendering API, there is an equivalent call to
 * load images directly into an SDL_Texture for use by the GPU without using a
 * software surface: call IMG_LoadTexture() instead.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to
 * [SDL_DestroySurface](https://wiki.libsdl.org/SDL3/SDL_DestroySurface)
 * ().
 *
 * \param file a path on the filesystem to load an image from.
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadTyped_IO
 * \sa IMG_Load_IO
 * \sa SDL_DestroySurface
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_Load(const char *file);

/**
 * Load an image from an SDL data source into a software surface.
 *
 * An SDL_Surface is a buffer of pixels in memory accessible by the CPU. Use
 * this if you plan to hand the data to something else or manipulate it
 * further in code.
 *
 * There are no guarantees about what format the new SDL_Surface data will be;
 * in many cases, SDL_image will attempt to supply a surface that exactly
 * matches the provided image, but in others it might have to convert (either
 * because the image is in a format that SDL doesn't directly support or
 * because it's compressed data that could reasonably uncompress to various
 * formats and SDL_image had to pick one). You can inspect an SDL_Surface for
 * its specifics, and use SDL_ConvertSurface to then migrate to any supported
 * format.
 *
 * If the image format supports a transparent pixel, SDL will set the colorkey
 * for the surface. You can enable RLE acceleration on the surface afterwards
 * by calling: SDL_SetSurfaceColorKey(image, SDL_RLEACCEL,
 * image->format->colorkey);
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * There is a separate function to read files from disk without having to deal
 * with SDL_IOStream: `IMG_Load("filename.jpg")` will call this function and
 * manage those details for you, determining the file type from the filename's
 * extension.
 *
 * There is also IMG_LoadTyped_IO(), which is equivalent to this function
 * except a file extension (like "BMP", "JPG", etc) can be specified, in case
 * SDL_image cannot autodetect the file format.
 *
 * If you are using SDL's 2D rendering API, there is an equivalent call to
 * load images directly into an SDL_Texture for use by the GPU without using a
 * software surface: call IMG_LoadTexture_IO() instead.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to SDL_DestroySurface().
 *
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_Load
 * \sa IMG_LoadTyped_IO
 * \sa SDL_DestroySurface
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_Load_IO(SDL_IOStream *src, bool closeio);

/**
 * Load an image from a filesystem path into a GPU texture.
 *
 * An SDL_Texture represents an image in GPU memory, usable by SDL's 2D Render
 * API. This can be significantly more efficient than using a CPU-bound
 * SDL_Surface if you don't need to manipulate the image directly after
 * loading it.
 *
 * If the loaded image has transparency or a colorkey, a texture with an alpha
 * channel will be created. Otherwise, SDL_image will attempt to create an
 * SDL_Texture in the most format that most reasonably represents the image
 * data (but in many cases, this will just end up being 32-bit RGB or 32-bit
 * RGBA).
 *
 * There is a separate function to read files from an SDL_IOStream, if you
 * need an i/o abstraction to provide data from anywhere instead of a simple
 * filesystem read; that function is IMG_LoadTexture_IO().
 *
 * If you would rather decode an image to an SDL_Surface (a buffer of pixels
 * in CPU memory), call IMG_Load() instead.
 *
 * When done with the returned texture, the app should dispose of it with a
 * call to SDL_DestroyTexture().
 *
 * \param renderer the SDL_Renderer to use to create the GPU texture.
 * \param file a path on the filesystem to load an image from.
 * \returns a new texture, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadTextureTyped_IO
 * \sa IMG_LoadTexture_IO
 */
extern SDL_DECLSPEC SDL_Texture * SDLCALL IMG_LoadTexture(SDL_Renderer *renderer, const char *file);

/**
 * Load an image from an SDL data source into a GPU texture.
 *
 * An SDL_Texture represents an image in GPU memory, usable by SDL's 2D Render
 * API. This can be significantly more efficient than using a CPU-bound
 * SDL_Surface if you don't need to manipulate the image directly after
 * loading it.
 *
 * If the loaded image has transparency or a colorkey, a texture with an alpha
 * channel will be created. Otherwise, SDL_image will attempt to create an
 * SDL_Texture in the most format that most reasonably represents the image
 * data (but in many cases, this will just end up being 32-bit RGB or 32-bit
 * RGBA).
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * There is a separate function to read files from disk without having to deal
 * with SDL_IOStream: `IMG_LoadTexture(renderer, "filename.jpg")` will call
 * this function and manage those details for you, determining the file type
 * from the filename's extension.
 *
 * There is also IMG_LoadTextureTyped_IO(), which is equivalent to this
 * function except a file extension (like "BMP", "JPG", etc) can be specified,
 * in case SDL_image cannot autodetect the file format.
 *
 * If you would rather decode an image to an SDL_Surface (a buffer of pixels
 * in CPU memory), call IMG_Load() instead.
 *
 * When done with the returned texture, the app should dispose of it with a
 * call to SDL_DestroyTexture().
 *
 * \param renderer the SDL_Renderer to use to create the GPU texture.
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \returns a new texture, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadTexture
 * \sa IMG_LoadTextureTyped_IO
 * \sa SDL_DestroyTexture
 */
extern SDL_DECLSPEC SDL_Texture * SDLCALL IMG_LoadTexture_IO(SDL_Renderer *renderer, SDL_IOStream *src, bool closeio);

/**
 * Load an image from an SDL data source into a GPU texture.
 *
 * An SDL_Texture represents an image in GPU memory, usable by SDL's 2D Render
 * API. This can be significantly more efficient than using a CPU-bound
 * SDL_Surface if you don't need to manipulate the image directly after
 * loading it.
 *
 * If the loaded image has transparency or a colorkey, a texture with an alpha
 * channel will be created. Otherwise, SDL_image will attempt to create an
 * SDL_Texture in the most format that most reasonably represents the image
 * data (but in many cases, this will just end up being 32-bit RGB or 32-bit
 * RGBA).
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * Even though this function accepts a file type, SDL_image may still try
 * other decoders that are capable of detecting file type from the contents of
 * the image data, but may rely on the caller-provided type string for formats
 * that it cannot autodetect. If `type` is NULL, SDL_image will rely solely on
 * its ability to guess the format.
 *
 * There is a separate function to read files from disk without having to deal
 * with SDL_IOStream: `IMG_LoadTexture("filename.jpg")` will call this
 * function and manage those details for you, determining the file type from
 * the filename's extension.
 *
 * There is also IMG_LoadTexture_IO(), which is equivalent to this function
 * except that it will rely on SDL_image to determine what type of data it is
 * loading, much like passing a NULL for type.
 *
 * If you would rather decode an image to an SDL_Surface (a buffer of pixels
 * in CPU memory), call IMG_LoadTyped_IO() instead.
 *
 * When done with the returned texture, the app should dispose of it with a
 * call to SDL_DestroyTexture().
 *
 * \param renderer the SDL_Renderer to use to create the GPU texture.
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \param type a filename extension that represent this data ("BMP", "GIF",
 *             "PNG", etc).
 * \returns a new texture, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadTexture
 * \sa IMG_LoadTexture_IO
 * \sa SDL_DestroyTexture
 */
extern SDL_DECLSPEC SDL_Texture * SDLCALL IMG_LoadTextureTyped_IO(SDL_Renderer *renderer, SDL_IOStream *src, bool closeio, const char *type);

/**
 * Detect AVIF image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is AVIF data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isAVIF(SDL_IOStream *src);

/**
 * Detect ICO image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is ICO data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isICO(SDL_IOStream *src);

/**
 * Detect CUR image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is CUR data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isCUR(SDL_IOStream *src);

/**
 * Detect BMP image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is BMP data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isBMP(SDL_IOStream *src);

/**
 * Detect GIF image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is GIF data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isGIF(SDL_IOStream *src);

/**
 * Detect JPG image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is JPG data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isJPG(SDL_IOStream *src);

/**
 * Detect JXL image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is JXL data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isJXL(SDL_IOStream *src);

/**
 * Detect LBM image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is LBM data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isLBM(SDL_IOStream *src);

/**
 * Detect PCX image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is PCX data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isPCX(SDL_IOStream *src);

/**
 * Detect PNG image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is PNG data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isPNG(SDL_IOStream *src);

/**
 * Detect PNM image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is PNM data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isPNM(SDL_IOStream *src);

/**
 * Detect SVG image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is SVG data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isSVG(SDL_IOStream *src);

/**
 * Detect QOI image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is QOI data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isQOI(SDL_IOStream *src);

/**
 * Detect TIFF image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is TIFF data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isTIF(SDL_IOStream *src);

/**
 * Detect XCF image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is XCF data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isXCF(SDL_IOStream *src);

/**
 * Detect XPM image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is XPM data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXV
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isXPM(SDL_IOStream *src);

/**
 * Detect XV image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is XV data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isWEBP
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isXV(SDL_IOStream *src);

/**
 * Detect WEBP image data on a readable/seekable SDL_IOStream.
 *
 * This function attempts to determine if a file is a given filetype, reading
 * the least amount possible from the SDL_IOStream (usually a few bytes).
 *
 * There is no distinction made between "not the filetype in question" and
 * basic i/o errors.
 *
 * This function will always attempt to seek `src` back to where it started
 * when this function was called, but it will not report any errors in doing
 * so, but assuming seeking works, this means you can immediately use this
 * with a different IMG_isTYPE function, or load the image without further
 * seeking.
 *
 * You do not need to call this function to load data; SDL_image can work to
 * determine file type in many cases in its standard load functions.
 *
 * \param src a seekable/readable SDL_IOStream to provide image data.
 * \returns non-zero if this is WEBP data, zero otherwise.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_isAVIF
 * \sa IMG_isICO
 * \sa IMG_isCUR
 * \sa IMG_isBMP
 * \sa IMG_isGIF
 * \sa IMG_isJPG
 * \sa IMG_isJXL
 * \sa IMG_isLBM
 * \sa IMG_isPCX
 * \sa IMG_isPNG
 * \sa IMG_isPNM
 * \sa IMG_isSVG
 * \sa IMG_isQOI
 * \sa IMG_isTIF
 * \sa IMG_isXCF
 * \sa IMG_isXPM
 * \sa IMG_isXV
 */
extern SDL_DECLSPEC bool SDLCALL IMG_isWEBP(SDL_IOStream *src);

/**
 * Load a AVIF image directly.
 *
 * If you know you definitely have a AVIF image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadAVIF_IO(SDL_IOStream *src);

/**
 * Load a ICO image directly.
 *
 * If you know you definitely have a ICO image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadICO_IO(SDL_IOStream *src);

/**
 * Load a CUR image directly.
 *
 * If you know you definitely have a CUR image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadCUR_IO(SDL_IOStream *src);

/**
 * Load a BMP image directly.
 *
 * If you know you definitely have a BMP image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadBMP_IO(SDL_IOStream *src);

/**
 * Load a GIF image directly.
 *
 * If you know you definitely have a GIF image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadGIF_IO(SDL_IOStream *src);

/**
 * Load a JPG image directly.
 *
 * If you know you definitely have a JPG image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadJPG_IO(SDL_IOStream *src);

/**
 * Load a JXL image directly.
 *
 * If you know you definitely have a JXL image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadJXL_IO(SDL_IOStream *src);

/**
 * Load a LBM image directly.
 *
 * If you know you definitely have a LBM image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadLBM_IO(SDL_IOStream *src);

/**
 * Load a PCX image directly.
 *
 * If you know you definitely have a PCX image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadPCX_IO(SDL_IOStream *src);

/**
 * Load a PNG image directly.
 *
 * If you know you definitely have a PNG image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadPNG_IO(SDL_IOStream *src);

/**
 * Load a PNM image directly.
 *
 * If you know you definitely have a PNM image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadPNM_IO(SDL_IOStream *src);

/**
 * Load a SVG image directly.
 *
 * If you know you definitely have a SVG image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadSVG_IO(SDL_IOStream *src);

/**
 * Load a QOI image directly.
 *
 * If you know you definitely have a QOI image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadQOI_IO(SDL_IOStream *src);

/**
 * Load a TGA image directly.
 *
 * If you know you definitely have a TGA image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadTGA_IO(SDL_IOStream *src);

/**
 * Load a TIFF image directly.
 *
 * If you know you definitely have a TIFF image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadTIF_IO(SDL_IOStream *src);

/**
 * Load a XCF image directly.
 *
 * If you know you definitely have a XCF image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadXCF_IO(SDL_IOStream *src);

/**
 * Load a XPM image directly.
 *
 * If you know you definitely have a XPM image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXV_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadXPM_IO(SDL_IOStream *src);

/**
 * Load a XV image directly.
 *
 * If you know you definitely have a XV image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadWEBP_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadXV_IO(SDL_IOStream *src);

/**
 * Load a WEBP image directly.
 *
 * If you know you definitely have a WEBP image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream to load image data from.
 * \returns SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAVIF_IO
 * \sa IMG_LoadICO_IO
 * \sa IMG_LoadCUR_IO
 * \sa IMG_LoadBMP_IO
 * \sa IMG_LoadGIF_IO
 * \sa IMG_LoadJPG_IO
 * \sa IMG_LoadJXL_IO
 * \sa IMG_LoadLBM_IO
 * \sa IMG_LoadPCX_IO
 * \sa IMG_LoadPNG_IO
 * \sa IMG_LoadPNM_IO
 * \sa IMG_LoadSVG_IO
 * \sa IMG_LoadQOI_IO
 * \sa IMG_LoadTGA_IO
 * \sa IMG_LoadTIF_IO
 * \sa IMG_LoadXCF_IO
 * \sa IMG_LoadXPM_IO
 * \sa IMG_LoadXV_IO
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadWEBP_IO(SDL_IOStream *src);

/**
 * Load an SVG image, scaled to a specific size.
 *
 * Since SVG files are resolution-independent, you specify the size you would
 * like the output image to be and it will be generated at those dimensions.
 *
 * Either width or height may be 0 and the image will be auto-sized to
 * preserve aspect ratio.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to SDL_DestroySurface().
 *
 * \param src an SDL_IOStream to load SVG data from.
 * \param width desired width of the generated surface, in pixels.
 * \param height desired height of the generated surface, in pixels.
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_LoadSizedSVG_IO(SDL_IOStream *src, int width, int height);

/**
 * Load an XPM image from a memory array.
 *
 * The returned surface will be an 8bpp indexed surface, if possible,
 * otherwise it will be 32bpp. If you always want 32-bit data, use
 * IMG_ReadXPMFromArrayToRGB888() instead.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to SDL_DestroySurface().
 *
 * \param xpm a null-terminated array of strings that comprise XPM data.
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_ReadXPMFromArrayToRGB888
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_ReadXPMFromArray(char **xpm);

/**
 * Load an XPM image from a memory array.
 *
 * The returned surface will always be a 32-bit RGB surface. If you want 8-bit
 * indexed colors (and the XPM data allows it), use IMG_ReadXPMFromArray()
 * instead.
 *
 * When done with the returned surface, the app should dispose of it with a
 * call to SDL_DestroySurface().
 *
 * \param xpm a null-terminated array of strings that comprise XPM data.
 * \returns a new SDL surface, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_ReadXPMFromArray
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL IMG_ReadXPMFromArrayToRGB888(char **xpm);

/**
 * Save an SDL_Surface into a AVIF image file.
 *
 * If the file already exists, it will be overwritten.
 *
 * \param surface the SDL surface to save.
 * \param file path on the filesystem to write new file to.
 * \param quality the desired quality, ranging between 0 (lowest) and 100
 *                (highest).
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SaveAVIF_IO
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SaveAVIF(SDL_Surface *surface, const char *file, int quality);

/**
 * Save an SDL_Surface into AVIF image data, via an SDL_IOStream.
 *
 * If you just want to save to a filename, you can use IMG_SaveAVIF() instead.
 *
 * If `closeio` is true, `dst` will be closed before returning, whether this
 * function succeeds or not.
 *
 * \param surface the SDL surface to save.
 * \param dst the SDL_IOStream to save the image data to.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \param quality the desired quality, ranging between 0 (lowest) and 100
 *                (highest).
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SaveAVIF
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SaveAVIF_IO(SDL_Surface *surface, SDL_IOStream *dst, bool closeio, int quality);

/**
 * Save an SDL_Surface into a PNG image file.
 *
 * If the file already exists, it will be overwritten.
 *
 * \param surface the SDL surface to save.
 * \param file path on the filesystem to write new file to.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SavePNG_IO
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SavePNG(SDL_Surface *surface, const char *file);

/**
 * Save an SDL_Surface into PNG image data, via an SDL_IOStream.
 *
 * If you just want to save to a filename, you can use IMG_SavePNG() instead.
 *
 * If `closeio` is true, `dst` will be closed before returning, whether this
 * function succeeds or not.
 *
 * \param surface the SDL surface to save.
 * \param dst the SDL_IOStream to save the image data to.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SavePNG
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SavePNG_IO(SDL_Surface *surface, SDL_IOStream *dst, bool closeio);

/**
 * Save an SDL_Surface into a JPEG image file.
 *
 * If the file already exists, it will be overwritten.
 *
 * \param surface the SDL surface to save.
 * \param file path on the filesystem to write new file to.
 * \param quality [0; 33] is Lowest quality, [34; 66] is Middle quality, [67;
 *                100] is Highest quality.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SaveJPG_IO
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SaveJPG(SDL_Surface *surface, const char *file, int quality);

/**
 * Save an SDL_Surface into JPEG image data, via an SDL_IOStream.
 *
 * If you just want to save to a filename, you can use IMG_SaveJPG() instead.
 *
 * If `closeio` is true, `dst` will be closed before returning, whether this
 * function succeeds or not.
 *
 * \param surface the SDL surface to save.
 * \param dst the SDL_IOStream to save the image data to.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \param quality [0; 33] is Lowest quality, [34; 66] is Middle quality, [67;
 *                100] is Highest quality.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_SaveJPG
 */
extern SDL_DECLSPEC bool SDLCALL IMG_SaveJPG_IO(SDL_Surface *surface, SDL_IOStream *dst, bool closeio, int quality);

/**
 * Animated image support
 *
 * Currently only animated GIFs and WEBP images are supported.
 */
typedef struct IMG_Animation
{
	int w, h;
	int count;
	SDL_Surface **frames;
	int *delays;
} IMG_Animation;

/**
 * Load an animation from a file.
 *
 * When done with the returned animation, the app should dispose of it with a
 * call to IMG_FreeAnimation().
 *
 * \param file path on the filesystem containing an animated image.
 * \returns a new IMG_Animation, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_FreeAnimation
 */
extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimation(const char *file);

/**
 * Load an animation from an SDL_IOStream.
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * When done with the returned animation, the app should dispose of it with a
 * call to IMG_FreeAnimation().
 *
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \returns a new IMG_Animation, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_FreeAnimation
 */
extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimation_IO(SDL_IOStream *src, bool closeio);

/**
 * Load an animation from an SDL datasource
 *
 * Even though this function accepts a file type, SDL_image may still try
 * other decoders that are capable of detecting file type from the contents of
 * the image data, but may rely on the caller-provided type string for formats
 * that it cannot autodetect. If `type` is NULL, SDL_image will rely solely on
 * its ability to guess the format.
 *
 * If `closeio` is true, `src` will be closed before returning, whether this
 * function succeeds or not. SDL_image reads everything it needs from `src`
 * during this call in any case.
 *
 * When done with the returned animation, the app should dispose of it with a
 * call to IMG_FreeAnimation().
 *
 * \param src an SDL_IOStream that data will be read from.
 * \param closeio true to close/free the SDL_IOStream before returning, false
 *                to leave it open.
 * \param type a filename extension that represent this data ("GIF", etc).
 * \returns a new IMG_Animation, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAnimation
 * \sa IMG_LoadAnimation_IO
 * \sa IMG_FreeAnimation
 */
extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadAnimationTyped_IO(SDL_IOStream *src, bool closeio, const char *type);

/**
 * Dispose of an IMG_Animation and free its resources.
 *
 * The provided `anim` pointer is not valid once this call returns.
 *
 * \param anim IMG_Animation to dispose of.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAnimation
 * \sa IMG_LoadAnimation_IO
 * \sa IMG_LoadAnimationTyped_IO
 */
extern SDL_DECLSPEC void SDLCALL IMG_FreeAnimation(IMG_Animation *anim);

/**
 * Load a GIF animation directly.
 *
 * If you know you definitely have a GIF image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream that data will be read from.
 * \returns a new IMG_Animation, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAnimation
 * \sa IMG_LoadAnimation_IO
 * \sa IMG_LoadAnimationTyped_IO
 * \sa IMG_FreeAnimation
 */
extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadGIFAnimation_IO(SDL_IOStream *src);

/**
 * Load a WEBP animation directly.
 *
 * If you know you definitely have a WEBP image, you can call this function,
 * which will skip SDL_image's file format detection routines. Generally it's
 * better to use the abstract interfaces; also, there is only an SDL_IOStream
 * interface available here.
 *
 * \param src an SDL_IOStream that data will be read from.
 * \returns a new IMG_Animation, or NULL on error.
 *
 * \since This function is available since SDL_image 3.0.0.
 *
 * \sa IMG_LoadAnimation
 * \sa IMG_LoadAnimation_IO
 * \sa IMG_LoadAnimationTyped_IO
 * \sa IMG_FreeAnimation
 */
extern SDL_DECLSPEC IMG_Animation * SDLCALL IMG_LoadWEBPAnimation_IO(SDL_IOStream *src);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif
#include <SDL3/SDL_close_code.h>

#endif /* SDL_IMAGE_H_ */
