/*
  SDL_ttf:  A companion library to SDL for working with TrueType (tm) fonts
  Copyright (C) 2001-2025 Sam Lantinga <slouken@libsdl.org>

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

/* WIKI CATEGORY: SDLTTF */

/**
 * # CategorySDLTTF
 *
 * Header file for SDL_ttf library
 *
 * This library is a wrapper around the excellent FreeType 2.0 library,
 * available at: https://www.freetype.org/
 */

#ifndef SDL_TTF_H_
#define SDL_TTF_H_

#include <SDL3/SDL.h>
#include <SDL3/SDL_begin_code.h>

/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

/**
 * Printable format: "%d.%d.%d", MAJOR, MINOR, MICRO
 */
#define SDL_TTF_MAJOR_VERSION   3
#define SDL_TTF_MINOR_VERSION   2
#define SDL_TTF_MICRO_VERSION   2

/**
 * This is the version number macro for the current SDL_ttf version.
 */
#define SDL_TTF_VERSION \
    SDL_VERSIONNUM(SDL_TTF_MAJOR_VERSION, SDL_TTF_MINOR_VERSION, SDL_TTF_MICRO_VERSION)

/**
 * This macro will evaluate to true if compiled with SDL_ttf at least X.Y.Z.
 */
#define SDL_TTF_VERSION_ATLEAST(X, Y, Z) \
    ((SDL_TTF_MAJOR_VERSION >= X) && \
     (SDL_TTF_MAJOR_VERSION > X || SDL_TTF_MINOR_VERSION >= Y) && \
     (SDL_TTF_MAJOR_VERSION > X || SDL_TTF_MINOR_VERSION > Y || SDL_TTF_MICRO_VERSION >= Z))

/**
 * This function gets the version of the dynamically linked SDL_ttf library.
 *
 * \returns SDL_ttf version.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_Version(void);

/**
 * Query the version of the FreeType library in use.
 *
 * TTF_Init() should be called before calling this function.
 *
 * \param major to be filled in with the major version number. Can be NULL.
 * \param minor to be filled in with the minor version number. Can be NULL.
 * \param patch to be filled in with the param version number. Can be NULL.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_Init
 */
extern SDL_DECLSPEC void SDLCALL TTF_GetFreeTypeVersion(int *major, int *minor, int *patch);

/**
 * Query the version of the HarfBuzz library in use.
 *
 * If HarfBuzz is not available, the version reported is 0.0.0.
 *
 * \param major to be filled in with the major version number. Can be NULL.
 * \param minor to be filled in with the minor version number. Can be NULL.
 * \param patch to be filled in with the param version number. Can be NULL.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL TTF_GetHarfBuzzVersion(int *major, int *minor, int *patch);

/**
 * The internal structure containing font information.
 *
 * Opaque data!
 */
typedef struct TTF_Font TTF_Font;

/**
 * Initialize SDL_ttf.
 *
 * You must successfully call this function before it is safe to call any
 * other function in this library.
 *
 * It is safe to call this more than once, and each successful TTF_Init() call
 * should be paired with a matching TTF_Quit() call.
 *
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_Quit
 */
extern SDL_DECLSPEC bool SDLCALL TTF_Init(void);

/**
 * Create a font from a file, using a specified point size.
 *
 * Some .fon fonts will have several sizes embedded in the file, so the point
 * size becomes the index of choosing which size. If the value is too high,
 * the last indexed size will be the default.
 *
 * When done with the returned TTF_Font, use TTF_CloseFont() to dispose of it.
 *
 * \param file path to font file.
 * \param ptsize point size to use for the newly-opened font.
 * \returns a valid TTF_Font, or NULL on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CloseFont
 */
extern SDL_DECLSPEC TTF_Font * SDLCALL TTF_OpenFont(const char *file, float ptsize);

/**
 * Create a font from an SDL_IOStream, using a specified point size.
 *
 * Some .fon fonts will have several sizes embedded in the file, so the point
 * size becomes the index of choosing which size. If the value is too high,
 * the last indexed size will be the default.
 *
 * If `closeio` is true, `src` will be automatically closed once the font is
 * closed. Otherwise you should close `src` yourself after closing the font.
 *
 * When done with the returned TTF_Font, use TTF_CloseFont() to dispose of it.
 *
 * \param src an SDL_IOStream to provide a font file's data.
 * \param closeio true to close `src` when the font is closed, false to leave
 *                it open.
 * \param ptsize point size to use for the newly-opened font.
 * \returns a valid TTF_Font, or NULL on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CloseFont
 */
extern SDL_DECLSPEC TTF_Font * SDLCALL TTF_OpenFontIO(SDL_IOStream *src, bool closeio, float ptsize);

/**
 * Create a font with the specified properties.
 *
 * These are the supported properties:
 *
 * - `TTF_PROP_FONT_CREATE_FILENAME_STRING`: the font file to open, if an
 *   SDL_IOStream isn't being used. This is required if
 *   `TTF_PROP_FONT_CREATE_IOSTREAM_POINTER` and
 *   `TTF_PROP_FONT_CREATE_EXISTING_FONT` aren't set.
 * - `TTF_PROP_FONT_CREATE_IOSTREAM_POINTER`: an SDL_IOStream containing the
 *   font to be opened. This should not be closed until the font is closed.
 *   This is required if `TTF_PROP_FONT_CREATE_FILENAME_STRING` and
 *   `TTF_PROP_FONT_CREATE_EXISTING_FONT` aren't set.
 * - `TTF_PROP_FONT_CREATE_IOSTREAM_OFFSET_NUMBER`: the offset in the iostream
 *   for the beginning of the font, defaults to 0.
 * - `TTF_PROP_FONT_CREATE_IOSTREAM_AUTOCLOSE_BOOLEAN`: true if closing the
 *   font should also close the associated SDL_IOStream.
 * - `TTF_PROP_FONT_CREATE_SIZE_FLOAT`: the point size of the font. Some .fon
 *   fonts will have several sizes embedded in the file, so the point size
 *   becomes the index of choosing which size. If the value is too high, the
 *   last indexed size will be the default.
 * - `TTF_PROP_FONT_CREATE_FACE_NUMBER`: the face index of the font, if the
 *   font contains multiple font faces.
 * - `TTF_PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER`: the horizontal DPI to use
 *   for font rendering, defaults to
 *   `TTF_PROP_FONT_CREATE_VERTICAL_DPI_NUMBER` if set, or 72 otherwise.
 * - `TTF_PROP_FONT_CREATE_VERTICAL_DPI_NUMBER`: the vertical DPI to use for
 *   font rendering, defaults to `TTF_PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER`
 *   if set, or 72 otherwise.
 * - `TTF_PROP_FONT_CREATE_EXISTING_FONT`: an optional TTF_Font that, if set,
 *   will be used as the font data source and the initial size and style of
 *   the new font.
 *
 * \param props the properties to use.
 * \returns a valid TTF_Font, or NULL on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CloseFont
 */
extern SDL_DECLSPEC TTF_Font * SDLCALL TTF_OpenFontWithProperties(SDL_PropertiesID props);

#define TTF_PROP_FONT_CREATE_FILENAME_STRING            "SDL_ttf.font.create.filename"
#define TTF_PROP_FONT_CREATE_IOSTREAM_POINTER           "SDL_ttf.font.create.iostream"
#define TTF_PROP_FONT_CREATE_IOSTREAM_OFFSET_NUMBER     "SDL_ttf.font.create.iostream.offset"
#define TTF_PROP_FONT_CREATE_IOSTREAM_AUTOCLOSE_BOOLEAN "SDL_ttf.font.create.iostream.autoclose"
#define TTF_PROP_FONT_CREATE_SIZE_FLOAT                 "SDL_ttf.font.create.size"
#define TTF_PROP_FONT_CREATE_FACE_NUMBER                "SDL_ttf.font.create.face"
#define TTF_PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER      "SDL_ttf.font.create.hdpi"
#define TTF_PROP_FONT_CREATE_VERTICAL_DPI_NUMBER        "SDL_ttf.font.create.vdpi"
#define TTF_PROP_FONT_CREATE_EXISTING_FONT              "SDL_ttf.font.create.existing_font"

/**
 * Create a copy of an existing font.
 *
 * The copy will be distinct from the original, but will share the font file
 * and have the same size and style as the original.
 *
 * When done with the returned TTF_Font, use TTF_CloseFont() to dispose of it.
 *
 * \param existing_font the font to copy.
 * \returns a valid TTF_Font, or NULL on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               original font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CloseFont
 */
extern SDL_DECLSPEC TTF_Font * SDLCALL TTF_CopyFont(TTF_Font *existing_font);

/**
 * Get the properties associated with a font.
 *
 * The following read-write properties are provided by SDL:
 *
 * - `TTF_PROP_FONT_OUTLINE_LINE_CAP_NUMBER`: The FT_Stroker_LineCap value
 *   used when setting the font outline, defaults to
 *   `FT_STROKER_LINECAP_ROUND`.
 * - `TTF_PROP_FONT_OUTLINE_LINE_JOIN_NUMBER`: The FT_Stroker_LineJoin value
 *   used when setting the font outline, defaults to
 *   `FT_STROKER_LINEJOIN_ROUND`.
 * - `TTF_PROP_FONT_OUTLINE_MITER_LIMIT_NUMBER`: The FT_Fixed miter limit used
 *   when setting the font outline, defaults to 0.
 *
 * \param font the font to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL TTF_GetFontProperties(TTF_Font *font);

#define TTF_PROP_FONT_OUTLINE_LINE_CAP_NUMBER           "SDL_ttf.font.outline.line_cap"
#define TTF_PROP_FONT_OUTLINE_LINE_JOIN_NUMBER          "SDL_ttf.font.outline.line_join"
#define TTF_PROP_FONT_OUTLINE_MITER_LIMIT_NUMBER        "SDL_ttf.font.outline.miter_limit"

/**
 * Get the font generation.
 *
 * The generation is incremented each time font properties change that require
 * rebuilding glyphs, such as style, size, etc.
 *
 * \param font the font to query.
 * \returns the font generation or 0 on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC Uint32 SDLCALL TTF_GetFontGeneration(TTF_Font *font);

/**
 * Add a fallback font.
 *
 * Add a font that will be used for glyphs that are not in the current font.
 * The fallback font should have the same size and style as the current font.
 *
 * If there are multiple fallback fonts, they are used in the order added.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 * \param fallback the font to add as a fallback.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created
 *               both fonts.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_ClearFallbackFonts
 * \sa TTF_RemoveFallbackFont
 */
extern SDL_DECLSPEC bool SDLCALL TTF_AddFallbackFont(TTF_Font *font, TTF_Font *fallback);

/**
 * Remove a fallback font.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 * \param fallback the font to remove as a fallback.
 *
 * \threadsafety This function should be called on the thread that created
 *               both fonts.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_AddFallbackFont
 * \sa TTF_ClearFallbackFonts
 */
extern SDL_DECLSPEC void SDLCALL TTF_RemoveFallbackFont(TTF_Font *font, TTF_Font *fallback);

/**
 * Remove all fallback fonts.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_AddFallbackFont
 * \sa TTF_RemoveFallbackFont
 */
extern SDL_DECLSPEC void SDLCALL TTF_ClearFallbackFonts(TTF_Font *font);

/**
 * Set a font's size dynamically.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * \param font the font to resize.
 * \param ptsize the new point size.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontSize
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontSize(TTF_Font *font, float ptsize);

/**
 * Set font size dynamically with target resolutions, in dots per inch.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * \param font the font to resize.
 * \param ptsize the new point size.
 * \param hdpi the target horizontal DPI.
 * \param vdpi the target vertical DPI.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontSize
 * \sa TTF_GetFontSizeDPI
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontSizeDPI(TTF_Font *font, float ptsize, int hdpi, int vdpi);

/**
 * Get the size of a font.
 *
 * \param font the font to query.
 * \returns the size of the font, or 0.0f on failure; call SDL_GetError() for
 *          more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontSize
 * \sa TTF_SetFontSizeDPI
 */
extern SDL_DECLSPEC float SDLCALL TTF_GetFontSize(TTF_Font *font);

/**
 * Get font target resolutions, in dots per inch.
 *
 * \param font the font to query.
 * \param hdpi a pointer filled in with the target horizontal DPI.
 * \param vdpi a pointer filled in with the target vertical DPI.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontSizeDPI
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetFontDPI(TTF_Font *font, int *hdpi, int *vdpi);

/**
 * Font style flags for TTF_Font
 *
 * These are the flags which can be used to set the style of a font in
 * SDL_ttf. A combination of these flags can be used with functions that set
 * or query font style, such as TTF_SetFontStyle or TTF_GetFontStyle.
 *
 * \since This datatype is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontStyle
 * \sa TTF_GetFontStyle
 */
typedef Uint32 TTF_FontStyleFlags;

#define TTF_STYLE_NORMAL        0x00 /**< No special style */
#define TTF_STYLE_BOLD          0x01 /**< Bold style */
#define TTF_STYLE_ITALIC        0x02 /**< Italic style */
#define TTF_STYLE_UNDERLINE     0x04 /**< Underlined text */
#define TTF_STYLE_STRIKETHROUGH 0x08 /**< Strikethrough text */

/**
 * Set a font's current style.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * The font styles are a set of bit flags, OR'd together:
 *
 * - `TTF_STYLE_NORMAL` (is zero)
 * - `TTF_STYLE_BOLD`
 * - `TTF_STYLE_ITALIC`
 * - `TTF_STYLE_UNDERLINE`
 * - `TTF_STYLE_STRIKETHROUGH`
 *
 * \param font the font to set a new style on.
 * \param style the new style values to set, OR'd together.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontStyle
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetFontStyle(TTF_Font *font, TTF_FontStyleFlags style);

/**
 * Query a font's current style.
 *
 * The font styles are a set of bit flags, OR'd together:
 *
 * - `TTF_STYLE_NORMAL` (is zero)
 * - `TTF_STYLE_BOLD`
 * - `TTF_STYLE_ITALIC`
 * - `TTF_STYLE_UNDERLINE`
 * - `TTF_STYLE_STRIKETHROUGH`
 *
 * \param font the font to query.
 * \returns the current font style, as a set of bit flags.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontStyle
 */
extern SDL_DECLSPEC TTF_FontStyleFlags SDLCALL TTF_GetFontStyle(const TTF_Font *font);

/**
 * Set a font's current outline.
 *
 * This uses the font properties `TTF_PROP_FONT_OUTLINE_LINE_CAP_NUMBER`,
 * `TTF_PROP_FONT_OUTLINE_LINE_JOIN_NUMBER`, and
 * `TTF_PROP_FONT_OUTLINE_MITER_LIMIT_NUMBER` when setting the font outline.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * \param font the font to set a new outline on.
 * \param outline positive outline value, 0 to default.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontOutline
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontOutline(TTF_Font *font, int outline);

/**
 * Query a font's current outline.
 *
 * \param font the font to query.
 * \returns the font's current outline value.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontOutline
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontOutline(const TTF_Font *font);

/**
 * Hinting flags for TTF (TrueType Fonts)
 *
 * This enum specifies the level of hinting to be applied to the font
 * rendering. The hinting level determines how much the font's outlines are
 * adjusted for better alignment on the pixel grid.
 *
 * \since This enum is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontHinting
 * \sa TTF_GetFontHinting
 */
typedef enum TTF_HintingFlags
{
    TTF_HINTING_INVALID = -1,
    TTF_HINTING_NORMAL,         /**< Normal hinting applies standard grid-fitting. */
    TTF_HINTING_LIGHT,          /**< Light hinting applies subtle adjustments to improve rendering. */
    TTF_HINTING_MONO,           /**< Monochrome hinting adjusts the font for better rendering at lower resolutions. */
    TTF_HINTING_NONE,           /**< No hinting, the font is rendered without any grid-fitting. */
    TTF_HINTING_LIGHT_SUBPIXEL  /**< Light hinting with subpixel rendering for more precise font edges. */
} TTF_HintingFlags;

/**
 * Set a font's current hinter setting.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * The hinter setting is a single value:
 *
 * - `TTF_HINTING_NORMAL`
 * - `TTF_HINTING_LIGHT`
 * - `TTF_HINTING_MONO`
 * - `TTF_HINTING_NONE`
 * - `TTF_HINTING_LIGHT_SUBPIXEL` (available in SDL_ttf 3.0.0 and later)
 *
 * \param font the font to set a new hinter setting on.
 * \param hinting the new hinter setting.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontHinting
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetFontHinting(TTF_Font *font, TTF_HintingFlags hinting);

/**
 * Query the number of faces of a font.
 *
 * \param font the font to query.
 * \returns the number of FreeType font faces.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetNumFontFaces(const TTF_Font *font);

/**
 * Query a font's current FreeType hinter setting.
 *
 * The hinter setting is a single value:
 *
 * - `TTF_HINTING_NORMAL`
 * - `TTF_HINTING_LIGHT`
 * - `TTF_HINTING_MONO`
 * - `TTF_HINTING_NONE`
 * - `TTF_HINTING_LIGHT_SUBPIXEL` (available in SDL_ttf 3.0.0 and later)
 *
 * \param font the font to query.
 * \returns the font's current hinter value, or TTF_HINTING_INVALID if the
 *          font is invalid.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontHinting
 */
extern SDL_DECLSPEC TTF_HintingFlags SDLCALL TTF_GetFontHinting(const TTF_Font *font);

/**
 * Enable Signed Distance Field rendering for a font.
 *
 * SDF is a technique that helps fonts look sharp even when scaling and
 * rotating, and requires special shader support for display.
 *
 * This works with Blended APIs, and generates the raw signed distance values
 * in the alpha channel of the resulting texture.
 *
 * This updates any TTF_Text objects using this font, and clears
 * already-generated glyphs, if any, from the cache.
 *
 * \param font the font to set SDF support on.
 * \param enabled true to enable SDF, false to disable.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontSDF
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontSDF(TTF_Font *font, bool enabled);

/**
 * Query whether Signed Distance Field rendering is enabled for a font.
 *
 * \param font the font to query.
 * \returns true if enabled, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontSDF
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetFontSDF(const TTF_Font *font);

/**
 * Query a font's weight, in terms of the lightness/heaviness of the strokes.
 *
 * \param font the font to query.
 * \returns the font's current weight.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.4.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontWeight(const TTF_Font *font);

#define TTF_FONT_WEIGHT_THIN        100 /**< Thin (100) named font weight value */
#define TTF_FONT_WEIGHT_EXTRA_LIGHT 200 /**< ExtraLight (200) named font weight value */
#define TTF_FONT_WEIGHT_LIGHT       300 /**< Light (300) named font weight value */
#define TTF_FONT_WEIGHT_NORMAL      400 /**< Normal (400) named font weight value */
#define TTF_FONT_WEIGHT_MEDIUM      500 /**< Medium (500) named font weight value */
#define TTF_FONT_WEIGHT_SEMI_BOLD   600 /**< SemiBold (600) named font weight value */
#define TTF_FONT_WEIGHT_BOLD        700 /**< Bold (700) named font weight value */
#define TTF_FONT_WEIGHT_EXTRA_BOLD  800 /**< ExtraBold (800) named font weight value */
#define TTF_FONT_WEIGHT_BLACK       900 /**< Black (900) named font weight value */
#define TTF_FONT_WEIGHT_EXTRA_BLACK 950 /**< ExtraBlack (950) named font weight value */

/**
 * The horizontal alignment used when rendering wrapped text.
 *
 * \since This enum is available since SDL_ttf 3.0.0.
 */
typedef enum TTF_HorizontalAlignment
{
    TTF_HORIZONTAL_ALIGN_INVALID = -1,
    TTF_HORIZONTAL_ALIGN_LEFT,
    TTF_HORIZONTAL_ALIGN_CENTER,
    TTF_HORIZONTAL_ALIGN_RIGHT
} TTF_HorizontalAlignment;

/**
 * Set a font's current wrap alignment option.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to set a new wrap alignment option on.
 * \param align the new wrap alignment option.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontWrapAlignment
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetFontWrapAlignment(TTF_Font *font, TTF_HorizontalAlignment align);

/**
 * Query a font's current wrap alignment option.
 *
 * \param font the font to query.
 * \returns the font's current wrap alignment option.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontWrapAlignment
 */
extern SDL_DECLSPEC TTF_HorizontalAlignment SDLCALL TTF_GetFontWrapAlignment(const TTF_Font *font);

/**
 * Query the total height of a font.
 *
 * This is usually equal to point size.
 *
 * \param font the font to query.
 * \returns the font's height.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontHeight(const TTF_Font *font);

/**
 * Query the offset from the baseline to the top of a font.
 *
 * This is a positive value, relative to the baseline.
 *
 * \param font the font to query.
 * \returns the font's ascent.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontAscent(const TTF_Font *font);

/**
 * Query the offset from the baseline to the bottom of a font.
 *
 * This is a negative value, relative to the baseline.
 *
 * \param font the font to query.
 * \returns the font's descent.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontDescent(const TTF_Font *font);

/**
 * Set the spacing between lines of text for a font.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 * \param lineskip the new line spacing for the font.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontLineSkip
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetFontLineSkip(TTF_Font *font, int lineskip);

/**
 * Query the spacing between lines of text for a font.
 *
 * \param font the font to query.
 * \returns the font's recommended spacing.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontLineSkip
 */
extern SDL_DECLSPEC int SDLCALL TTF_GetFontLineSkip(const TTF_Font *font);

/**
 * Set if kerning is enabled for a font.
 *
 * Newly-opened fonts default to allowing kerning. This is generally a good
 * policy unless you have a strong reason to disable it, as it tends to
 * produce better rendering (with kerning disabled, some fonts might render
 * the word `kerning` as something that looks like `keming` for example).
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to set kerning on.
 * \param enabled true to enable kerning, false to disable.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetFontKerning
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetFontKerning(TTF_Font *font, bool enabled);

/**
 * Query whether or not kerning is enabled for a font.
 *
 * \param font the font to query.
 * \returns true if kerning is enabled, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontKerning
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetFontKerning(const TTF_Font *font);

/**
 * Query whether a font is fixed-width.
 *
 * A "fixed-width" font means all glyphs are the same width across; a
 * lowercase 'i' will be the same size across as a capital 'W', for example.
 * This is common for terminals and text editors, and other apps that treat
 * text as a grid. Most other things (WYSIWYG word processors, web pages, etc)
 * are more likely to not be fixed-width in most cases.
 *
 * \param font the font to query.
 * \returns true if the font is fixed-width, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_FontIsFixedWidth(const TTF_Font *font);

/**
 * Query whether a font is scalable or not.
 *
 * Scalability lets us distinguish between outline and bitmap fonts.
 *
 * \param font the font to query.
 * \returns true if the font is scalable, false otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontSDF
 */
extern SDL_DECLSPEC bool SDLCALL TTF_FontIsScalable(const TTF_Font *font);

/**
 * Query a font's family name.
 *
 * This string is dictated by the contents of the font file.
 *
 * Note that the returned string is to internal storage, and should not be
 * modified or free'd by the caller. The string becomes invalid, with the rest
 * of the font, when `font` is handed to TTF_CloseFont().
 *
 * \param font the font to query.
 * \returns the font's family name.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC const char * SDLCALL TTF_GetFontFamilyName(const TTF_Font *font);

/**
 * Query a font's style name.
 *
 * This string is dictated by the contents of the font file.
 *
 * Note that the returned string is to internal storage, and should not be
 * modified or free'd by the caller. The string becomes invalid, with the rest
 * of the font, when `font` is handed to TTF_CloseFont().
 *
 * \param font the font to query.
 * \returns the font's style name.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC const char * SDLCALL TTF_GetFontStyleName(const TTF_Font *font);

/**
 * Direction flags
 *
 * The values here are chosen to match
 * [hb_direction_t](https://harfbuzz.github.io/harfbuzz-hb-common.html#hb-direction-t)
 * .
 *
 * \since This enum is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetFontDirection
 */
typedef enum TTF_Direction
{
  TTF_DIRECTION_INVALID = 0,
  TTF_DIRECTION_LTR = 4,        /**< Left to Right */
  TTF_DIRECTION_RTL,            /**< Right to Left */
  TTF_DIRECTION_TTB,            /**< Top to Bottom */
  TTF_DIRECTION_BTT             /**< Bottom to Top */
} TTF_Direction;

/**
 * Set the direction to be used for text shaping by a font.
 *
 * This function only supports left-to-right text shaping if SDL_ttf was not
 * built with HarfBuzz support.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 * \param direction the new direction for text to flow.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontDirection(TTF_Font *font, TTF_Direction direction);

/**
 * Get the direction to be used for text shaping by a font.
 *
 * This defaults to TTF_DIRECTION_INVALID if it hasn't been set.
 *
 * \param font the font to query.
 * \returns the direction to be used for text shaping.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC TTF_Direction SDLCALL TTF_GetFontDirection(TTF_Font *font);

/**
 * Convert from a 4 character string to a 32-bit tag.
 *
 * \param string the 4 character string to convert.
 * \returns the 32-bit representation of the string.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TagToString
 */
extern SDL_DECLSPEC Uint32 SDLCALL TTF_StringToTag(const char *string);

/**
 * Convert from a 32-bit tag to a 4 character string.
 *
 * \param tag the 32-bit tag to convert.
 * \param string a pointer filled in with the 4 character representation of
 *               the tag.
 * \param size the size of the buffer pointed at by string, should be at least
 *             4.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TagToString
 */
extern SDL_DECLSPEC void SDLCALL TTF_TagToString(Uint32 tag, char *string, size_t size);

/**
 * Set the script to be used for text shaping by a font.
 *
 * This returns false if SDL_ttf isn't built with HarfBuzz support.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to modify.
 * \param script an
 *               [ISO 15924 code](https://unicode.org/iso15924/iso15924-codes.html)
 *               .
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_StringToTag
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontScript(TTF_Font *font, Uint32 script);

/**
 * Get the script used for text shaping a font.
 *
 * \param font the font to query.
 * \returns an
 *          [ISO 15924 code](https://unicode.org/iso15924/iso15924-codes.html)
 *          or 0 if a script hasn't been set.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TagToString
 */
extern SDL_DECLSPEC Uint32 SDLCALL TTF_GetFontScript(TTF_Font *font);

/**
 * Get the script used by a 32-bit codepoint.
 *
 * \param ch the character code to check.
 * \returns an
 *          [ISO 15924 code](https://unicode.org/iso15924/iso15924-codes.html)
 *          on success, or 0 on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function is thread-safe.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TagToString
 */
extern SDL_DECLSPEC Uint32 SDLCALL TTF_GetGlyphScript(Uint32 ch);

/**
 * Set language to be used for text shaping by a font.
 *
 * If SDL_ttf was not built with HarfBuzz support, this function returns
 * false.
 *
 * This updates any TTF_Text objects using this font.
 *
 * \param font the font to specify a language for.
 * \param language_bcp47 a null-terminated string containing the desired
 *                       language's BCP47 code. Or null to reset the value.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetFontLanguage(TTF_Font *font, const char *language_bcp47);

/**
 * Check whether a glyph is provided by the font for a UNICODE codepoint.
 *
 * \param font the font to query.
 * \param ch the codepoint to check.
 * \returns true if font provides a glyph for this character, false if not.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_FontHasGlyph(TTF_Font *font, Uint32 ch);

/**
 * The type of data in a glyph image
 *
 * \since This enum is available since SDL_ttf 3.0.0.
 */
typedef enum TTF_ImageType
{
    TTF_IMAGE_INVALID,
    TTF_IMAGE_ALPHA,    /**< The color channels are white */
    TTF_IMAGE_COLOR,    /**< The color channels have image data */
    TTF_IMAGE_SDF,      /**< The alpha channel has signed distance field information */
} TTF_ImageType;

/**
 * Get the pixel image for a UNICODE codepoint.
 *
 * \param font the font to query.
 * \param ch the codepoint to check.
 * \param image_type a pointer filled in with the glyph image type, may be
 *                   NULL.
 * \returns an SDL_Surface containing the glyph, or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_GetGlyphImage(TTF_Font *font, Uint32 ch, TTF_ImageType *image_type);

/**
 * Get the pixel image for a character index.
 *
 * This is useful for text engine implementations, which can call this with
 * the `glyph_index` in a TTF_CopyOperation
 *
 * \param font the font to query.
 * \param glyph_index the index of the glyph to return.
 * \param image_type a pointer filled in with the glyph image type, may be
 *                   NULL.
 * \returns an SDL_Surface containing the glyph, or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_GetGlyphImageForIndex(TTF_Font *font, Uint32 glyph_index, TTF_ImageType *image_type);

/**
 * Query the metrics (dimensions) of a font's glyph for a UNICODE codepoint.
 *
 * To understand what these metrics mean, here is a useful link:
 *
 * https://freetype.sourceforge.net/freetype2/docs/tutorial/step2.html
 *
 * \param font the font to query.
 * \param ch the codepoint to check.
 * \param minx a pointer filled in with the minimum x coordinate of the glyph
 *             from the left edge of its bounding box. This value may be
 *             negative.
 * \param maxx a pointer filled in with the maximum x coordinate of the glyph
 *             from the left edge of its bounding box.
 * \param miny a pointer filled in with the minimum y coordinate of the glyph
 *             from the bottom edge of its bounding box. This value may be
 *             negative.
 * \param maxy a pointer filled in with the maximum y coordinate of the glyph
 *             from the bottom edge of its bounding box.
 * \param advance a pointer filled in with the distance to the next glyph from
 *                the left edge of this glyph's bounding box.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetGlyphMetrics(TTF_Font *font, Uint32 ch, int *minx, int *maxx, int *miny, int *maxy, int *advance);

/**
 * Query the kerning size between the glyphs of two UNICODE codepoints.
 *
 * \param font the font to query.
 * \param previous_ch the previous codepoint.
 * \param ch the current codepoint.
 * \param kerning a pointer filled in with the kerning size between the two
 *                glyphs, in pixels, may be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetGlyphKerning(TTF_Font *font, Uint32 previous_ch, Uint32 ch, int *kerning);

/**
 * Calculate the dimensions of a rendered string of UTF-8 text.
 *
 * This will report the width and height, in pixels, of the space that the
 * specified string will take to fully render.
 *
 * \param font the font to query.
 * \param text text to calculate, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param w will be filled with width, in pixels, on return.
 * \param h will be filled with height, in pixels, on return.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetStringSize(TTF_Font *font, const char *text, size_t length, int *w, int *h);

/**
 * Calculate the dimensions of a rendered string of UTF-8 text.
 *
 * This will report the width and height, in pixels, of the space that the
 * specified string will take to fully render.
 *
 * Text is wrapped to multiple lines on line endings and on word boundaries if
 * it extends beyond `wrap_width` in pixels.
 *
 * If wrap_width is 0, this function will only wrap on newline characters.
 *
 * \param font the font to query.
 * \param text text to calculate, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param wrap_width the maximum width or 0 to wrap on newline characters.
 * \param w will be filled with width, in pixels, on return.
 * \param h will be filled with height, in pixels, on return.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetStringSizeWrapped(TTF_Font *font, const char *text, size_t length, int wrap_width, int *w, int *h);

/**
 * Calculate how much of a UTF-8 string will fit in a given width.
 *
 * This reports the number of characters that can be rendered before reaching
 * `max_width`.
 *
 * This does not need to render the string to do this calculation.
 *
 * \param font the font to query.
 * \param text text to calculate, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param max_width maximum width, in pixels, available for the string, or 0
 *                  for unbounded width.
 * \param measured_width a pointer filled in with the width, in pixels, of the
 *                       string that will fit, may be NULL.
 * \param measured_length a pointer filled in with the length, in bytes, of
 *                        the string that will fit, may be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_MeasureString(TTF_Font *font, const char *text, size_t length, int max_width, int *measured_width, size_t *measured_length);

/**
 * Render UTF-8 text at fast quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the colorkey, giving a transparent background. The 1 pixel
 * will be set to the text color.
 *
 * This will not word-wrap the string; you'll get a surface with a single line
 * of text, as long as the string requires. You can use
 * TTF_RenderText_Solid_Wrapped() instead if you need to wrap the output to
 * multiple lines.
 *
 * This will not wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Shaded,
 * TTF_RenderText_Blended, and TTF_RenderText_LCD.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended
 * \sa TTF_RenderText_LCD
 * \sa TTF_RenderText_Shaded
 * \sa TTF_RenderText_Solid
 * \sa TTF_RenderText_Solid_Wrapped
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Solid(TTF_Font *font, const char *text, size_t length, SDL_Color fg);

/**
 * Render word-wrapped UTF-8 text at fast quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the colorkey, giving a transparent background. The 1 pixel
 * will be set to the text color.
 *
 * Text is wrapped to multiple lines on line endings and on word boundaries if
 * it extends beyond `wrapLength` in pixels.
 *
 * If wrapLength is 0, this function will only wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Shaded_Wrapped,
 * TTF_RenderText_Blended_Wrapped, and TTF_RenderText_LCD_Wrapped.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param wrapLength the maximum width of the text surface or 0 to wrap on
 *                   newline characters.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended_Wrapped
 * \sa TTF_RenderText_LCD_Wrapped
 * \sa TTF_RenderText_Shaded_Wrapped
 * \sa TTF_RenderText_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Solid_Wrapped(TTF_Font *font, const char *text, size_t length, SDL_Color fg, int wrapLength);

/**
 * Render a single 32-bit glyph at fast quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the colorkey, giving a transparent background. The 1 pixel
 * will be set to the text color.
 *
 * The glyph is rendered without any padding or centering in the X direction,
 * and aligned normally in the Y direction.
 *
 * You can render at other quality levels with TTF_RenderGlyph_Shaded,
 * TTF_RenderGlyph_Blended, and TTF_RenderGlyph_LCD.
 *
 * \param font the font to render with.
 * \param ch the character to render.
 * \param fg the foreground color for the text.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderGlyph_Blended
 * \sa TTF_RenderGlyph_LCD
 * \sa TTF_RenderGlyph_Shaded
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderGlyph_Solid(TTF_Font *font, Uint32 ch, SDL_Color fg);

/**
 * Render UTF-8 text at high quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the specified background color, while other pixels have
 * varying degrees of the foreground color. This function returns the new
 * surface, or NULL if there was an error.
 *
 * This will not word-wrap the string; you'll get a surface with a single line
 * of text, as long as the string requires. You can use
 * TTF_RenderText_Shaded_Wrapped() instead if you need to wrap the output to
 * multiple lines.
 *
 * This will not wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid,
 * TTF_RenderText_Blended, and TTF_RenderText_LCD.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended
 * \sa TTF_RenderText_LCD
 * \sa TTF_RenderText_Shaded_Wrapped
 * \sa TTF_RenderText_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Shaded(TTF_Font *font, const char *text, size_t length, SDL_Color fg, SDL_Color bg);

/**
 * Render word-wrapped UTF-8 text at high quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the specified background color, while other pixels have
 * varying degrees of the foreground color. This function returns the new
 * surface, or NULL if there was an error.
 *
 * Text is wrapped to multiple lines on line endings and on word boundaries if
 * it extends beyond `wrap_width` in pixels.
 *
 * If wrap_width is 0, this function will only wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid_Wrapped,
 * TTF_RenderText_Blended_Wrapped, and TTF_RenderText_LCD_Wrapped.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \param wrap_width the maximum width of the text surface or 0 to wrap on
 *                   newline characters.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended_Wrapped
 * \sa TTF_RenderText_LCD_Wrapped
 * \sa TTF_RenderText_Shaded
 * \sa TTF_RenderText_Solid_Wrapped
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Shaded_Wrapped(TTF_Font *font, const char *text, size_t length, SDL_Color fg, SDL_Color bg, int wrap_width);

/**
 * Render a single UNICODE codepoint at high quality to a new 8-bit surface.
 *
 * This function will allocate a new 8-bit, palettized surface. The surface's
 * 0 pixel will be the specified background color, while other pixels have
 * varying degrees of the foreground color. This function returns the new
 * surface, or NULL if there was an error.
 *
 * The glyph is rendered without any padding or centering in the X direction,
 * and aligned normally in the Y direction.
 *
 * You can render at other quality levels with TTF_RenderGlyph_Solid,
 * TTF_RenderGlyph_Blended, and TTF_RenderGlyph_LCD.
 *
 * \param font the font to render with.
 * \param ch the codepoint to render.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \returns a new 8-bit, palettized surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderGlyph_Blended
 * \sa TTF_RenderGlyph_LCD
 * \sa TTF_RenderGlyph_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderGlyph_Shaded(TTF_Font *font, Uint32 ch, SDL_Color fg, SDL_Color bg);

/**
 * Render UTF-8 text at high quality to a new ARGB surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, using alpha
 * blending to dither the font with the given color. This function returns the
 * new surface, or NULL if there was an error.
 *
 * This will not word-wrap the string; you'll get a surface with a single line
 * of text, as long as the string requires. You can use
 * TTF_RenderText_Blended_Wrapped() instead if you need to wrap the output to
 * multiple lines.
 *
 * This will not wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid,
 * TTF_RenderText_Shaded, and TTF_RenderText_LCD.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended_Wrapped
 * \sa TTF_RenderText_LCD
 * \sa TTF_RenderText_Shaded
 * \sa TTF_RenderText_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Blended(TTF_Font *font, const char *text, size_t length, SDL_Color fg);

/**
 * Render word-wrapped UTF-8 text at high quality to a new ARGB surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, using alpha
 * blending to dither the font with the given color. This function returns the
 * new surface, or NULL if there was an error.
 *
 * Text is wrapped to multiple lines on line endings and on word boundaries if
 * it extends beyond `wrap_width` in pixels.
 *
 * If wrap_width is 0, this function will only wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid_Wrapped,
 * TTF_RenderText_Shaded_Wrapped, and TTF_RenderText_LCD_Wrapped.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param wrap_width the maximum width of the text surface or 0 to wrap on
 *                   newline characters.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended
 * \sa TTF_RenderText_LCD_Wrapped
 * \sa TTF_RenderText_Shaded_Wrapped
 * \sa TTF_RenderText_Solid_Wrapped
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_Blended_Wrapped(TTF_Font *font, const char *text, size_t length, SDL_Color fg, int wrap_width);

/**
 * Render a single UNICODE codepoint at high quality to a new ARGB surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, using alpha
 * blending to dither the font with the given color. This function returns the
 * new surface, or NULL if there was an error.
 *
 * The glyph is rendered without any padding or centering in the X direction,
 * and aligned normally in the Y direction.
 *
 * You can render at other quality levels with TTF_RenderGlyph_Solid,
 * TTF_RenderGlyph_Shaded, and TTF_RenderGlyph_LCD.
 *
 * \param font the font to render with.
 * \param ch the codepoint to render.
 * \param fg the foreground color for the text.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderGlyph_LCD
 * \sa TTF_RenderGlyph_Shaded
 * \sa TTF_RenderGlyph_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderGlyph_Blended(TTF_Font *font, Uint32 ch, SDL_Color fg);

/**
 * Render UTF-8 text at LCD subpixel quality to a new ARGB surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, and render
 * alpha-blended text using FreeType's LCD subpixel rendering. This function
 * returns the new surface, or NULL if there was an error.
 *
 * This will not word-wrap the string; you'll get a surface with a single line
 * of text, as long as the string requires. You can use
 * TTF_RenderText_LCD_Wrapped() instead if you need to wrap the output to
 * multiple lines.
 *
 * This will not wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid,
 * TTF_RenderText_Shaded, and TTF_RenderText_Blended.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended
 * \sa TTF_RenderText_LCD_Wrapped
 * \sa TTF_RenderText_Shaded
 * \sa TTF_RenderText_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_LCD(TTF_Font *font, const char *text, size_t length, SDL_Color fg, SDL_Color bg);

/**
 * Render word-wrapped UTF-8 text at LCD subpixel quality to a new ARGB
 * surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, and render
 * alpha-blended text using FreeType's LCD subpixel rendering. This function
 * returns the new surface, or NULL if there was an error.
 *
 * Text is wrapped to multiple lines on line endings and on word boundaries if
 * it extends beyond `wrap_width` in pixels.
 *
 * If wrap_width is 0, this function will only wrap on newline characters.
 *
 * You can render at other quality levels with TTF_RenderText_Solid_Wrapped,
 * TTF_RenderText_Shaded_Wrapped, and TTF_RenderText_Blended_Wrapped.
 *
 * \param font the font to render with.
 * \param text text to render, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \param wrap_width the maximum width of the text surface or 0 to wrap on
 *                   newline characters.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderText_Blended_Wrapped
 * \sa TTF_RenderText_LCD
 * \sa TTF_RenderText_Shaded_Wrapped
 * \sa TTF_RenderText_Solid_Wrapped
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderText_LCD_Wrapped(TTF_Font *font, const char *text, size_t length, SDL_Color fg, SDL_Color bg, int wrap_width);

/**
 * Render a single UNICODE codepoint at LCD subpixel quality to a new ARGB
 * surface.
 *
 * This function will allocate a new 32-bit, ARGB surface, and render
 * alpha-blended text using FreeType's LCD subpixel rendering. This function
 * returns the new surface, or NULL if there was an error.
 *
 * The glyph is rendered without any padding or centering in the X direction,
 * and aligned normally in the Y direction.
 *
 * You can render at other quality levels with TTF_RenderGlyph_Solid,
 * TTF_RenderGlyph_Shaded, and TTF_RenderGlyph_Blended.
 *
 * \param font the font to render with.
 * \param ch the codepoint to render.
 * \param fg the foreground color for the text.
 * \param bg the background color for the text.
 * \returns a new 32-bit, ARGB surface, or NULL if there was an error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_RenderGlyph_Blended
 * \sa TTF_RenderGlyph_Shaded
 * \sa TTF_RenderGlyph_Solid
 */
extern SDL_DECLSPEC SDL_Surface * SDLCALL TTF_RenderGlyph_LCD(TTF_Font *font, Uint32 ch, SDL_Color fg, SDL_Color bg);


/**
 * A text engine used to create text objects.
 *
 * This is a public interface that can be used by applications and libraries
 * to perform customize rendering with text objects. See
 * <SDL3_ttf/SDL_textengine.h> for details.
 *
 * There are three text engines provided with the library:
 *
 * - Drawing to an SDL_Surface, created with TTF_CreateSurfaceTextEngine()
 * - Drawing with an SDL 2D renderer, created with
 *   TTF_CreateRendererTextEngine()
 * - Drawing with the SDL GPU API, created with TTF_CreateGPUTextEngine()
 *
 * \since This struct is available since SDL_ttf 3.0.0.
 */
typedef struct TTF_TextEngine TTF_TextEngine;

/**
 * Internal data for TTF_Text
 *
 * \since This struct is available since SDL_ttf 3.0.0.
 */
typedef struct TTF_TextData TTF_TextData;

/**
 * Text created with TTF_CreateText()
 *
 * \since This struct is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateText
 * \sa TTF_GetTextProperties
 * \sa TTF_DestroyText
 */
typedef struct TTF_Text
{
    char *text;             /**< A copy of the UTF-8 string that this text object represents, useful for layout, debugging and retrieving substring text. This is updated when the text object is modified and will be freed automatically when the object is destroyed. */
    int num_lines;          /**< The number of lines in the text, 0 if it's empty */

    int refcount;           /**< Application reference count, used when freeing surface */

    TTF_TextData *internal; /**< Private */

} TTF_Text;

/**
 * Create a text engine for drawing text on SDL surfaces.
 *
 * \returns a TTF_TextEngine object or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_DestroySurfaceTextEngine
 * \sa TTF_DrawSurfaceText
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_CreateSurfaceTextEngine(void);

/**
 * Draw text to an SDL surface.
 *
 * `text` must have been created using a TTF_TextEngine from
 * TTF_CreateSurfaceTextEngine().
 *
 * \param text the text to draw.
 * \param x the x coordinate in pixels, positive from the left edge towards
 *          the right.
 * \param y the y coordinate in pixels, positive from the top edge towards the
 *          bottom.
 * \param surface the surface to draw on.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateSurfaceTextEngine
 * \sa TTF_CreateText
 */
extern SDL_DECLSPEC bool SDLCALL TTF_DrawSurfaceText(TTF_Text *text, int x, int y, SDL_Surface *surface);

/**
 * Destroy a text engine created for drawing text on SDL surfaces.
 *
 * All text created by this engine should be destroyed before calling this
 * function.
 *
 * \param engine a TTF_TextEngine object created with
 *               TTF_CreateSurfaceTextEngine().
 *
 * \threadsafety This function should be called on the thread that created the
 *               engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateSurfaceTextEngine
 */
extern SDL_DECLSPEC void SDLCALL TTF_DestroySurfaceTextEngine(TTF_TextEngine *engine);

/**
 * Create a text engine for drawing text on an SDL renderer.
 *
 * \param renderer the renderer to use for creating textures and drawing text.
 * \returns a TTF_TextEngine object or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               renderer.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_DestroyRendererTextEngine
 * \sa TTF_DrawRendererText
 * \sa TTF_CreateRendererTextEngineWithProperties
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_CreateRendererTextEngine(SDL_Renderer *renderer);

/**
 * Create a text engine for drawing text on an SDL renderer, with the
 * specified properties.
 *
 * These are the supported properties:
 *
 * - `TTF_PROP_RENDERER_TEXT_ENGINE_RENDERER`: the renderer to use for
 *   creating textures and drawing text
 * - `TTF_PROP_RENDERER_TEXT_ENGINE_ATLAS_TEXTURE_SIZE`: the size of the
 *   texture atlas
 *
 * \param props the properties to use.
 * \returns a TTF_TextEngine object or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               renderer.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateRendererTextEngine
 * \sa TTF_DestroyRendererTextEngine
 * \sa TTF_DrawRendererText
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_CreateRendererTextEngineWithProperties(SDL_PropertiesID props);

#define TTF_PROP_RENDERER_TEXT_ENGINE_RENDERER                 "SDL_ttf.renderer_text_engine.create.renderer"
#define TTF_PROP_RENDERER_TEXT_ENGINE_ATLAS_TEXTURE_SIZE       "SDL_ttf.renderer_text_engine.create.atlas_texture_size"

/**
 * Draw text to an SDL renderer.
 *
 * `text` must have been created using a TTF_TextEngine from
 * TTF_CreateRendererTextEngine(), and will draw using the renderer passed to
 * that function.
 *
 * \param text the text to draw.
 * \param x the x coordinate in pixels, positive from the left edge towards
 *          the right.
 * \param y the y coordinate in pixels, positive from the top edge towards the
 *          bottom.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateRendererTextEngine
 * \sa TTF_CreateText
 */
extern SDL_DECLSPEC bool SDLCALL TTF_DrawRendererText(TTF_Text *text, float x, float y);

/**
 * Destroy a text engine created for drawing text on an SDL renderer.
 *
 * All text created by this engine should be destroyed before calling this
 * function.
 *
 * \param engine a TTF_TextEngine object created with
 *               TTF_CreateRendererTextEngine().
 *
 * \threadsafety This function should be called on the thread that created the
 *               engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateRendererTextEngine
 */
extern SDL_DECLSPEC void SDLCALL TTF_DestroyRendererTextEngine(TTF_TextEngine *engine);

/**
 * Create a text engine for drawing text with the SDL GPU API.
 *
 * \param device the SDL_GPUDevice to use for creating textures and drawing
 *               text.
 * \returns a TTF_TextEngine object or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               device.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateGPUTextEngineWithProperties
 * \sa TTF_DestroyGPUTextEngine
 * \sa TTF_GetGPUTextDrawData
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_CreateGPUTextEngine(SDL_GPUDevice *device);

/**
 * Create a text engine for drawing text with the SDL GPU API, with the
 * specified properties.
 *
 * These are the supported properties:
 *
 * - `TTF_PROP_GPU_TEXT_ENGINE_DEVICE`: the SDL_GPUDevice to use for creating
 *   textures and drawing text.
 * - `TTF_PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE`: the size of the texture
 *   atlas
 *
 * \param props the properties to use.
 * \returns a TTF_TextEngine object or NULL on failure; call SDL_GetError()
 *          for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               device.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateGPUTextEngine
 * \sa TTF_DestroyGPUTextEngine
 * \sa TTF_GetGPUTextDrawData
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_CreateGPUTextEngineWithProperties(SDL_PropertiesID props);

#define TTF_PROP_GPU_TEXT_ENGINE_DEVICE                   "SDL_ttf.gpu_text_engine.create.device"
#define TTF_PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE       "SDL_ttf.gpu_text_engine.create.atlas_texture_size"

/**
 * Draw sequence returned by TTF_GetGPUTextDrawData
 *
 * \since This struct is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetGPUTextDrawData
 */
typedef struct TTF_GPUAtlasDrawSequence
{
    SDL_GPUTexture *atlas_texture;          /**< Texture atlas that stores the glyphs */
    SDL_FPoint *xy;                         /**< An array of vertex positions */
    SDL_FPoint *uv;                         /**< An array of normalized texture coordinates for each vertex */
    int num_vertices;                       /**< Number of vertices */
    int *indices;                           /**< An array of indices into the 'vertices' arrays */
    int num_indices;                        /**< Number of indices */
    TTF_ImageType image_type;               /**< The image type of this draw sequence */

    struct TTF_GPUAtlasDrawSequence *next;  /**< The next sequence (will be NULL in case of the last sequence) */
} TTF_GPUAtlasDrawSequence;

/**
 * Get the geometry data needed for drawing the text.
 *
 * `text` must have been created using a TTF_TextEngine from
 * TTF_CreateGPUTextEngine().
 *
 * The positive X-axis is taken towards the right and the positive Y-axis is
 * taken upwards for both the vertex and the texture coordinates, i.e, it
 * follows the same convention used by the SDL_GPU API. If you want to use a
 * different coordinate system you will need to transform the vertices
 * yourself.
 *
 * If the text looks blocky use linear filtering.
 *
 * \param text the text to draw.
 * \returns a NULL terminated linked list of TTF_GPUAtlasDrawSequence objects
 *          or NULL if the passed text is empty or in case of failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateGPUTextEngine
 * \sa TTF_CreateText
 */
extern SDL_DECLSPEC TTF_GPUAtlasDrawSequence * SDLCALL TTF_GetGPUTextDrawData(TTF_Text *text);

/**
 * Destroy a text engine created for drawing text with the SDL GPU API.
 *
 * All text created by this engine should be destroyed before calling this
 * function.
 *
 * \param engine a TTF_TextEngine object created with
 *               TTF_CreateGPUTextEngine().
 *
 * \threadsafety This function should be called on the thread that created the
 *               engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateGPUTextEngine
 */
extern SDL_DECLSPEC void SDLCALL TTF_DestroyGPUTextEngine(TTF_TextEngine *engine);

/**
 * The winding order of the vertices returned by TTF_GetGPUTextDrawData
 *
 * \since This enum is available since SDL_ttf 3.0.0.
 */
typedef enum TTF_GPUTextEngineWinding
{
    TTF_GPU_TEXTENGINE_WINDING_INVALID = -1,
    TTF_GPU_TEXTENGINE_WINDING_CLOCKWISE,
    TTF_GPU_TEXTENGINE_WINDING_COUNTER_CLOCKWISE
} TTF_GPUTextEngineWinding;

/**
 * Sets the winding order of the vertices returned by TTF_GetGPUTextDrawData
 * for a particular GPU text engine.
 *
 * \param engine a TTF_TextEngine object created with
 *               TTF_CreateGPUTextEngine().
 * \param winding the new winding order option.
 *
 * \threadsafety This function should be called on the thread that created the
 *               engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetGPUTextEngineWinding
 */
extern SDL_DECLSPEC void SDLCALL TTF_SetGPUTextEngineWinding(TTF_TextEngine *engine, TTF_GPUTextEngineWinding winding);

/**
 * Get the winding order of the vertices returned by TTF_GetGPUTextDrawData
 * for a particular GPU text engine
 *
 * \param engine a TTF_TextEngine object created with
 *               TTF_CreateGPUTextEngine().
 * \returns the winding order used by the GPU text engine or
 *          TTF_GPU_TEXTENGINE_WINDING_INVALID in case of error.
 *
 * \threadsafety This function should be called on the thread that created the
 *               engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetGPUTextEngineWinding
 */
extern SDL_DECLSPEC TTF_GPUTextEngineWinding SDLCALL TTF_GetGPUTextEngineWinding(const TTF_TextEngine *engine);

/**
 * Create a text object from UTF-8 text and a text engine.
 *
 * \param engine the text engine to use when creating the text object, may be
 *               NULL.
 * \param font the font to render with.
 * \param text the text to use, in UTF-8 encoding.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \returns a TTF_Text object or NULL on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               font and text engine.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_DestroyText
 */
extern SDL_DECLSPEC TTF_Text * SDLCALL TTF_CreateText(TTF_TextEngine *engine, TTF_Font *font, const char *text, size_t length);

/**
 * Get the properties associated with a text object.
 *
 * \param text the TTF_Text to query.
 * \returns a valid property ID on success or 0 on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL TTF_GetTextProperties(TTF_Text *text);

/**
 * Set the text engine used by a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param engine the text engine to use for drawing.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextEngine
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextEngine(TTF_Text *text, TTF_TextEngine *engine);

/**
 * Get the text engine used by a text object.
 *
 * \param text the TTF_Text to query.
 * \returns the TTF_TextEngine used by the text on success or NULL on failure;
 *          call SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetTextEngine
 */
extern SDL_DECLSPEC TTF_TextEngine * SDLCALL TTF_GetTextEngine(TTF_Text *text);

/**
 * Set the font used by a text object.
 *
 * When a text object has a font, any changes to the font will automatically
 * regenerate the text. If you set the font to NULL, the text will continue to
 * render but changes to the font will no longer affect the text.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param font the font to use, may be NULL.
 * \returns false if the text pointer is null; otherwise, true. call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextFont
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextFont(TTF_Text *text, TTF_Font *font);

/**
 * Get the font used by a text object.
 *
 * \param text the TTF_Text to query.
 * \returns the TTF_Font used by the text on success or NULL on failure; call
 *          SDL_GetError() for more information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetTextFont
 */
extern SDL_DECLSPEC TTF_Font * SDLCALL TTF_GetTextFont(TTF_Text *text);

/**
 * Set the direction to be used for text shaping a text object.
 *
 * This function only supports left-to-right text shaping if SDL_ttf was not
 * built with HarfBuzz support.
 *
 * \param text the text to modify.
 * \param direction the new direction for text to flow.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextDirection(TTF_Text *text, TTF_Direction direction);

/**
 * Get the direction to be used for text shaping a text object.
 *
 * This defaults to the direction of the font used by the text object.
 *
 * \param text the text to query.
 * \returns the direction to be used for text shaping.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC TTF_Direction SDLCALL TTF_GetTextDirection(TTF_Text *text);

/**
 * Set the script to be used for text shaping a text object.
 *
 * This returns false if SDL_ttf isn't built with HarfBuzz support.
 *
 * \param text the text to modify.
 * \param script an
 *               [ISO 15924 code](https://unicode.org/iso15924/iso15924-codes.html)
 *               .
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_StringToTag
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextScript(TTF_Text *text, Uint32 script);

/**
 * Get the script used for text shaping a text object.
 *
 * This defaults to the script of the font used by the text object.
 *
 * \param text the text to query.
 * \returns an
 *          [ISO 15924 code](https://unicode.org/iso15924/iso15924-codes.html)
 *          or 0 if a script hasn't been set on either the text object or the
 *          font.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TagToString
 */
extern SDL_DECLSPEC Uint32 SDLCALL TTF_GetTextScript(TTF_Text *text);

/**
 * Set the color of a text object.
 *
 * The default text color is white (255, 255, 255, 255).
 *
 * \param text the TTF_Text to modify.
 * \param r the red color value in the range of 0-255.
 * \param g the green color value in the range of 0-255.
 * \param b the blue color value in the range of 0-255.
 * \param a the alpha value in the range of 0-255.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextColor
 * \sa TTF_SetTextColorFloat
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextColor(TTF_Text *text, Uint8 r, Uint8 g, Uint8 b, Uint8 a);

/**
 * Set the color of a text object.
 *
 * The default text color is white (1.0f, 1.0f, 1.0f, 1.0f).
 *
 * \param text the TTF_Text to modify.
 * \param r the red color value, normally in the range of 0-1.
 * \param g the green color value, normally in the range of 0-1.
 * \param b the blue color value, normally in the range of 0-1.
 * \param a the alpha value in the range of 0-1.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextColorFloat
 * \sa TTF_SetTextColor
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextColorFloat(TTF_Text *text, float r, float g, float b, float a);

/**
 * Get the color of a text object.
 *
 * \param text the TTF_Text to query.
 * \param r a pointer filled in with the red color value in the range of
 *          0-255, may be NULL.
 * \param g a pointer filled in with the green color value in the range of
 *          0-255, may be NULL.
 * \param b a pointer filled in with the blue color value in the range of
 *          0-255, may be NULL.
 * \param a a pointer filled in with the alpha value in the range of 0-255,
 *          may be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextColorFloat
 * \sa TTF_SetTextColor
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextColor(TTF_Text *text, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);

/**
 * Get the color of a text object.
 *
 * \param text the TTF_Text to query.
 * \param r a pointer filled in with the red color value, normally in the
 *          range of 0-1, may be NULL.
 * \param g a pointer filled in with the green color value, normally in the
 *          range of 0-1, may be NULL.
 * \param b a pointer filled in with the blue color value, normally in the
 *          range of 0-1, may be NULL.
 * \param a a pointer filled in with the alpha value in the range of 0-1, may
 *          be NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextColor
 * \sa TTF_SetTextColorFloat
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextColorFloat(TTF_Text *text, float *r, float *g, float *b, float *a);

/**
 * Set the position of a text object.
 *
 * This can be used to position multiple text objects within a single wrapping
 * text area.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param x the x offset of the upper left corner of this text in pixels.
 * \param y the y offset of the upper left corner of this text in pixels.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextPosition
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextPosition(TTF_Text *text, int x, int y);

/**
 * Get the position of a text object.
 *
 * \param text the TTF_Text to query.
 * \param x a pointer filled in with the x offset of the upper left corner of
 *          this text in pixels, may be NULL.
 * \param y a pointer filled in with the y offset of the upper left corner of
 *          this text in pixels, may be NULL.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetTextPosition
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextPosition(TTF_Text *text, int *x, int *y);

/**
 * Set whether wrapping is enabled on a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param wrap_width the maximum width in pixels, 0 to wrap on newline
 *                   characters.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetTextWrapWidth
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextWrapWidth(TTF_Text *text, int wrap_width);

/**
 * Get whether wrapping is enabled on a text object.
 *
 * \param text the TTF_Text to query.
 * \param wrap_width a pointer filled in with the maximum width in pixels or 0
 *                   if the text is being wrapped on newline characters.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetTextWrapWidth
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextWrapWidth(TTF_Text *text, int *wrap_width);

/**
 * Set whether whitespace should be visible when wrapping a text object.
 *
 * If the whitespace is visible, it will take up space for purposes of
 * alignment and wrapping. This is good for editing, but looks better when
 * centered or aligned if whitespace around line wrapping is hidden. This
 * defaults false.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param visible true to show whitespace when wrapping text, false to hide
 *                it.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_TextWrapWhitespaceVisible
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextWrapWhitespaceVisible(TTF_Text *text, bool visible);

/**
 * Return whether whitespace is shown when wrapping a text object.
 *
 * \param text the TTF_Text to query.
 * \returns true if whitespace is shown when wrapping text, or false
 *          otherwise.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SetTextWrapWhitespaceVisible
 */
extern SDL_DECLSPEC bool SDLCALL TTF_TextWrapWhitespaceVisible(TTF_Text *text);

/**
 * Set the UTF-8 text used by a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param string the UTF-8 text to use, may be NULL.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_AppendTextString
 * \sa TTF_DeleteTextString
 * \sa TTF_InsertTextString
 */
extern SDL_DECLSPEC bool SDLCALL TTF_SetTextString(TTF_Text *text, const char *string, size_t length);

/**
 * Insert UTF-8 text into a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param offset the offset, in bytes, from the beginning of the string if >=
 *               0, the offset from the end of the string if < 0. Note that
 *               this does not do UTF-8 validation, so you should only insert
 *               at UTF-8 sequence boundaries.
 * \param string the UTF-8 text to insert.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_AppendTextString
 * \sa TTF_DeleteTextString
 * \sa TTF_SetTextString
 */
extern SDL_DECLSPEC bool SDLCALL TTF_InsertTextString(TTF_Text *text, int offset, const char *string, size_t length);

/**
 * Append UTF-8 text to a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param string the UTF-8 text to insert.
 * \param length the length of the text, in bytes, or 0 for null terminated
 *               text.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_DeleteTextString
 * \sa TTF_InsertTextString
 * \sa TTF_SetTextString
 */
extern SDL_DECLSPEC bool SDLCALL TTF_AppendTextString(TTF_Text *text, const char *string, size_t length);

/**
 * Delete UTF-8 text from a text object.
 *
 * This function may cause the internal text representation to be rebuilt.
 *
 * \param text the TTF_Text to modify.
 * \param offset the offset, in bytes, from the beginning of the string if >=
 *               0, the offset from the end of the string if < 0. Note that
 *               this does not do UTF-8 validation, so you should only delete
 *               at UTF-8 sequence boundaries.
 * \param length the length of text to delete, in bytes, or -1 for the
 *               remainder of the string.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_AppendTextString
 * \sa TTF_InsertTextString
 * \sa TTF_SetTextString
 */
extern SDL_DECLSPEC bool SDLCALL TTF_DeleteTextString(TTF_Text *text, int offset, int length);

/**
 * Get the size of a text object.
 *
 * The size of the text may change when the font or font style and size
 * change.
 *
 * \param text the TTF_Text to query.
 * \param w a pointer filled in with the width of the text, in pixels, may be
 *          NULL.
 * \param h a pointer filled in with the height of the text, in pixels, may be
 *          NULL.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextSize(TTF_Text *text, int *w, int *h);

/**
 * Flags for TTF_SubString
 *
 * \since This datatype is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_SubString
 */
typedef Uint32 TTF_SubStringFlags;

#define TTF_SUBSTRING_DIRECTION_MASK    0x000000FF  /**< The mask for the flow direction for this substring */
#define TTF_SUBSTRING_TEXT_START        0x00000100  /**< This substring contains the beginning of the text */
#define TTF_SUBSTRING_LINE_START        0x00000200  /**< This substring contains the beginning of line `line_index` */
#define TTF_SUBSTRING_LINE_END          0x00000400  /**< This substring contains the end of line `line_index` */
#define TTF_SUBSTRING_TEXT_END          0x00000800  /**< This substring contains the end of the text */

/**
 * The representation of a substring within text.
 *
 * \since This struct is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_GetNextTextSubString
 * \sa TTF_GetPreviousTextSubString
 * \sa TTF_GetTextSubString
 * \sa TTF_GetTextSubStringForLine
 * \sa TTF_GetTextSubStringForPoint
 * \sa TTF_GetTextSubStringsForRange
 */
typedef struct TTF_SubString
{
    TTF_SubStringFlags flags;   /**< The flags for this substring */
    int offset;                 /**< The byte offset from the beginning of the text */
    int length;                 /**< The byte length starting at the offset */
    int line_index;             /**< The index of the line that contains this substring */
    int cluster_index;          /**< The internal cluster index, used for quickly iterating */
    SDL_Rect rect;              /**< The rectangle, relative to the top left of the text, containing the substring */
} TTF_SubString;

/**
 * Get the substring of a text object that surrounds a text offset.
 *
 * If `offset` is less than 0, this will return a zero length substring at the
 * beginning of the text with the TTF_SUBSTRING_TEXT_START flag set. If
 * `offset` is greater than or equal to the length of the text string, this
 * will return a zero length substring at the end of the text with the
 * TTF_SUBSTRING_TEXT_END flag set.
 *
 * \param text the TTF_Text to query.
 * \param offset a byte offset into the text string.
 * \param substring a pointer filled in with the substring containing the
 *                  offset.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextSubString(TTF_Text *text, int offset, TTF_SubString *substring);

/**
 * Get the substring of a text object that contains the given line.
 *
 * If `line` is less than 0, this will return a zero length substring at the
 * beginning of the text with the TTF_SUBSTRING_TEXT_START flag set. If `line`
 * is greater than or equal to `text->num_lines` this will return a zero
 * length substring at the end of the text with the TTF_SUBSTRING_TEXT_END
 * flag set.
 *
 * \param text the TTF_Text to query.
 * \param line a zero-based line index, in the range [0 .. text->num_lines-1].
 * \param substring a pointer filled in with the substring containing the
 *                  offset.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextSubStringForLine(TTF_Text *text, int line, TTF_SubString *substring);

/**
 * Get the substrings of a text object that contain a range of text.
 *
 * \param text the TTF_Text to query.
 * \param offset a byte offset into the text string.
 * \param length the length of the range being queried, in bytes, or -1 for
 *               the remainder of the string.
 * \param count a pointer filled in with the number of substrings returned,
 *              may be NULL.
 * \returns a NULL terminated array of substring pointers or NULL on failure;
 *          call SDL_GetError() for more information. This is a single
 *          allocation that should be freed with SDL_free() when it is no
 *          longer needed.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC TTF_SubString ** SDLCALL TTF_GetTextSubStringsForRange(TTF_Text *text, int offset, int length, int *count);

/**
 * Get the portion of a text string that is closest to a point.
 *
 * This will return the closest substring of text to the given point.
 *
 * \param text the TTF_Text to query.
 * \param x the x coordinate relative to the left side of the text, may be
 *          outside the bounds of the text area.
 * \param y the y coordinate relative to the top side of the text, may be
 *          outside the bounds of the text area.
 * \param substring a pointer filled in with the closest substring of text to
 *                  the given point.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetTextSubStringForPoint(TTF_Text *text, int x, int y, TTF_SubString *substring);

/**
 * Get the previous substring in a text object
 *
 * If called at the start of the text, this will return a zero length
 * substring with the TTF_SUBSTRING_TEXT_START flag set.
 *
 * \param text the TTF_Text to query.
 * \param substring the TTF_SubString to query.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetPreviousTextSubString(TTF_Text *text, const TTF_SubString *substring, TTF_SubString *previous);

/**
 * Get the next substring in a text object
 *
 * If called at the end of the text, this will return a zero length substring
 * with the TTF_SUBSTRING_TEXT_END flag set.
 *
 * \param text the TTF_Text to query.
 * \param substring the TTF_SubString to query.
 * \param next a pointer filled in with the next substring.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_GetNextTextSubString(TTF_Text *text, const TTF_SubString *substring, TTF_SubString *next);

/**
 * Update the layout of a text object.
 *
 * This is automatically done when the layout is requested or the text is
 * rendered, but you can call this if you need more control over the timing of
 * when the layout and text engine representation are updated.
 *
 * \param text the TTF_Text to update.
 * \returns true on success or false on failure; call SDL_GetError() for more
 *          information.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC bool SDLCALL TTF_UpdateText(TTF_Text *text);

/**
 * Destroy a text object created by a text engine.
 *
 * \param text the text to destroy.
 *
 * \threadsafety This function should be called on the thread that created the
 *               text.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_CreateText
 */
extern SDL_DECLSPEC void SDLCALL TTF_DestroyText(TTF_Text *text);

/**
 * Dispose of a previously-created font.
 *
 * Call this when done with a font. This function will free any resources
 * associated with it. It is safe to call this function on NULL, for example
 * on the result of a failed call to TTF_OpenFont().
 *
 * The font is not valid after being passed to this function. String pointers
 * from functions that return information on this font, such as
 * TTF_GetFontFamilyName() and TTF_GetFontStyleName(), are no longer valid
 * after this call, as well.
 *
 * \param font the font to dispose of.
 *
 * \threadsafety This function should not be called while any other thread is
 *               using the font.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_OpenFont
 * \sa TTF_OpenFontIO
 */
extern SDL_DECLSPEC void SDLCALL TTF_CloseFont(TTF_Font *font);

/**
 * Deinitialize SDL_ttf.
 *
 * You must call this when done with the library, to free internal resources.
 * It is safe to call this when the library isn't initialized, as it will just
 * return immediately.
 *
 * Once you have as many quit calls as you have had successful calls to
 * TTF_Init, the library will actually deinitialize.
 *
 * Please note that this does not automatically close any fonts that are still
 * open at the time of deinitialization, and it is possibly not safe to close
 * them afterwards, as parts of the library will no longer be initialized to
 * deal with it. A well-written program should call TTF_CloseFont() on any
 * open fonts before calling this function!
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL TTF_Quit(void);

/**
 * Check if SDL_ttf is initialized.
 *
 * This reports the number of times the library has been initialized by a call
 * to TTF_Init(), without a paired deinitialization request from TTF_Quit().
 *
 * In short: if it's greater than zero, the library is currently initialized
 * and ready to work. If zero, it is not initialized.
 *
 * Despite the return value being a signed integer, this function should not
 * return a negative number.
 *
 * \returns the current number of initialization calls, that need to
 *          eventually be paired with this many calls to TTF_Quit().
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL_ttf 3.0.0.
 *
 * \sa TTF_Init
 * \sa TTF_Quit
 */
extern SDL_DECLSPEC int SDLCALL TTF_WasInit(void);

/* Ends C function definitions when using C++ */
#ifdef __cplusplus
}
#endif
#include <SDL3/SDL_close_code.h>

#endif /* SDL_TTF_H_ */

