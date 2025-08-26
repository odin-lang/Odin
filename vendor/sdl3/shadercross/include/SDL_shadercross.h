/*
  Simple DirectMedia Layer Shader Cross Compiler
  Copyright (C) 2024 Sam Lantinga <slouken@libsdl.org>

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

#ifndef SDL_SHADERCROSS_H
#define SDL_SHADERCROSS_H

#include <SDL3/SDL.h>
#include <SDL3/SDL_begin_code.h>
#include <SDL3/SDL_gpu.h>

/* Set up for C function definitions, even when using C++ */
#ifdef __cplusplus
extern "C" {
#endif

/**
 * Printable format: "%d.%d.%d", MAJOR, MINOR, MICRO
 */
#define SDL_SHADERCROSS_MAJOR_VERSION 3
#define SDL_SHADERCROSS_MINOR_VERSION 0
#define SDL_SHADERCROSS_MICRO_VERSION 0

typedef enum SDL_ShaderCross_IOVarType {
    SDL_SHADERCROSS_IOVAR_TYPE_UNKNOWN,
    SDL_SHADERCROSS_IOVAR_TYPE_INT8,
    SDL_SHADERCROSS_IOVAR_TYPE_UINT8,
    SDL_SHADERCROSS_IOVAR_TYPE_INT16,
    SDL_SHADERCROSS_IOVAR_TYPE_UINT16,
    SDL_SHADERCROSS_IOVAR_TYPE_INT32,
    SDL_SHADERCROSS_IOVAR_TYPE_UINT32,
    SDL_SHADERCROSS_IOVAR_TYPE_INT64,
    SDL_SHADERCROSS_IOVAR_TYPE_UINT64,
    SDL_SHADERCROSS_IOVAR_TYPE_FLOAT16,
    SDL_SHADERCROSS_IOVAR_TYPE_FLOAT32,
    SDL_SHADERCROSS_IOVAR_TYPE_FLOAT64
} SDL_ShaderCross_IOVarType;

typedef enum SDL_ShaderCross_ShaderStage
{
   SDL_SHADERCROSS_SHADERSTAGE_VERTEX,
   SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT,
   SDL_SHADERCROSS_SHADERSTAGE_COMPUTE
} SDL_ShaderCross_ShaderStage;

typedef struct SDL_ShaderCross_IOVarMetadata {
    char *name;                             /**< The UTF-8 name of the variable. */
    Uint32 location;                        /**< The location of the variable. */
    SDL_ShaderCross_IOVarType vector_type;  /**< The vector type of the variable. */
    Uint32 vector_size;                     /**< The number of components in the vector type of the variable. */
} SDL_ShaderCross_IOVarMetadata;

typedef struct SDL_ShaderCross_GraphicsShaderMetadata
{
    Uint32 num_samplers;                     /**< The number of samplers defined in the shader. */
    Uint32 num_storage_textures;             /**< The number of storage textures defined in the shader. */
    Uint32 num_storage_buffers;              /**< The number of storage buffers defined in the shader. */
    Uint32 num_uniform_buffers;              /**< The number of uniform buffers defined in the shader. */
    Uint32 num_inputs;                       /**< The number of inputs defined in the shader. */
    SDL_ShaderCross_IOVarMetadata *inputs;   /**< The inputs defined in the shader. */
    Uint32 num_outputs;                      /**< The number of outputs defined in the shader. */
    SDL_ShaderCross_IOVarMetadata *outputs;  /**< The outputs defined in the shader. */
} SDL_ShaderCross_GraphicsShaderMetadata;

typedef struct SDL_ShaderCross_ComputePipelineMetadata
{
    Uint32 num_samplers;                    /**< The number of samplers defined in the shader. */
    Uint32 num_readonly_storage_textures;   /**< The number of readonly storage textures defined in the shader. */
    Uint32 num_readonly_storage_buffers;    /**< The number of readonly storage buffers defined in the shader. */
    Uint32 num_readwrite_storage_textures;  /**< The number of read-write storage textures defined in the shader. */
    Uint32 num_readwrite_storage_buffers;   /**< The number of read-write storage buffers defined in the shader. */
    Uint32 num_uniform_buffers;             /**< The number of uniform buffers defined in the shader. */
    Uint32 threadcount_x;                   /**< The number of threads in the X dimension. */
    Uint32 threadcount_y;                   /**< The number of threads in the Y dimension. */
    Uint32 threadcount_z;                   /**< The number of threads in the Z dimension. */
} SDL_ShaderCross_ComputePipelineMetadata;

typedef struct SDL_ShaderCross_SPIRV_Info
{
    const Uint8 *bytecode;                     /**< The SPIRV bytecode. */
    size_t bytecode_size;                      /**< The length of the SPIRV bytecode. */
    const char *entrypoint;                    /**< The entry point function name for the shader in UTF-8. */
    SDL_ShaderCross_ShaderStage shader_stage;  /**< The shader stage to transpile the shader with. */
    bool enable_debug;                         /**< Allows debug info to be emitted when relevant. Can be useful for graphics debuggers like RenderDoc. */
    const char *name;                          /**< A UTF-8 name to associate with the shader. Optional, can be NULL. */

    SDL_PropertiesID props;                    /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
} SDL_ShaderCross_SPIRV_Info;

#define SDL_SHADERCROSS_PROP_SPIRV_PSSL_COMPATIBILITY "SDL.shadercross.spirv.pssl.compatibility"

#define SDL_SHADERCROSS_PROP_SPIRV_MSL_VERSION "SDL.shadercross.spirv.msl.version"

typedef struct SDL_ShaderCross_HLSL_Define
{
    char *name;   /**< The define name. */
    char *value;  /**< An optional value for the define. Can be NULL. */
} SDL_ShaderCross_HLSL_Define;

typedef struct SDL_ShaderCross_HLSL_Info
{
    const char *source;                        /**< The HLSL source code for the shader. */
    const char *entrypoint;                    /**< The entry point function name for the shader in UTF-8. */
    const char *include_dir;                   /**< The include directory for shader code. Optional, can be NULL. */
    SDL_ShaderCross_HLSL_Define *defines;      /**< An array of defines. Optional, can be NULL. If not NULL, must be terminated with a fully NULL define struct. */
    SDL_ShaderCross_ShaderStage shader_stage;  /**< The shader stage to compile the shader with. */
    bool enable_debug;                         /**< Allows debug info to be emitted when relevant. Can be useful for graphics debuggers like RenderDoc. */
    const char *name;                          /**< A UTF-8 name to associate with the shader. Optional, can be NULL. */

    SDL_PropertiesID props;                    /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
} SDL_ShaderCross_HLSL_Info;

/**
 * Initializes SDL_shadercross
 *
 * \threadsafety This should only be called once, from a single thread.
 * \returns true on success, false otherwise.
 */
extern SDL_DECLSPEC bool SDLCALL SDL_ShaderCross_Init(void);
/**
 * De-initializes SDL_shadercross
 *
 * \threadsafety This should only be called once, from a single thread.
 */
extern SDL_DECLSPEC void SDLCALL SDL_ShaderCross_Quit(void);

/**
 * Get the supported shader formats that SPIRV cross-compilation can output
 *
 * \threadsafety It is safe to call this function from any thread.
 * \returns GPU shader formats supported by SPIRV cross-compilation.
 */
extern SDL_DECLSPEC SDL_GPUShaderFormat SDLCALL SDL_ShaderCross_GetSPIRVShaderFormats(void);

/**
 * Transpile to MSL code from SPIRV code.
 *
 * You must SDL_free the returned string once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \returns an SDL_malloc'd string containing MSL code.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_TranspileMSLFromSPIRV(
    const SDL_ShaderCross_SPIRV_Info *info);

/**
 * Transpile to HLSL code from SPIRV code.
 *
 * You must SDL_free the returned string once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \returns an SDL_malloc'd string containing HLSL code.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_TranspileHLSLFromSPIRV(
    const SDL_ShaderCross_SPIRV_Info *info);

/**
 * Compile DXBC bytecode from SPIRV code.
 *
 * You must SDL_free the returned buffer once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \param size filled in with the bytecode buffer size.
 * \returns an SDL_malloc'd buffer containing DXBC bytecode.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_CompileDXBCFromSPIRV(
    const SDL_ShaderCross_SPIRV_Info *info,
    size_t *size);

/**
 * Compile DXIL bytecode from SPIRV code.
 *
 * You must SDL_free the returned buffer once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \param size filled in with the bytecode buffer size.
 * \returns an SDL_malloc'd buffer containing DXIL bytecode.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_CompileDXILFromSPIRV(
    const SDL_ShaderCross_SPIRV_Info *info,
    size_t *size);

/**
 * Compile an SDL GPU shader from SPIRV code. If your shader source is HLSL, you should obtain SPIR-V bytecode from SDL_ShaderCross_CompileSPIRVFromHLSL().
 *
 * \param device the SDL GPU device.
 * \param info a struct describing the shader to transpile.
 * \param metadata a struct describing shader metadata. Can be obtained from SDL_ShaderCross_ReflectGraphicsSPIRV().
 * \param props a properties object filled in with extra shader metadata.
 * \returns a compiled SDL_GPUShader.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC SDL_GPUShader * SDLCALL SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(
    SDL_GPUDevice *device,
    const SDL_ShaderCross_SPIRV_Info *info,
    const SDL_ShaderCross_GraphicsShaderMetadata *metadata,
    SDL_PropertiesID props);

/**
 * Compile an SDL GPU compute pipeline from SPIRV code. If your shader source is HLSL, you should obtain SPIR-V bytecode from SDL_ShaderCross_CompileSPIRVFromHLSL().
 *
 * \param device the SDL GPU device.
 * \param info a struct describing the shader to transpile.
 * \param metadata a struct describing shader metadata. Can be obtained from SDL_ShaderCross_ReflectComputeSPIRV().
 * \param props a properties object filled in with extra shader metadata.
 * \returns a compiled SDL_GPUComputePipeline.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC SDL_GPUComputePipeline * SDLCALL SDL_ShaderCross_CompileComputePipelineFromSPIRV(
    SDL_GPUDevice *device,
    const SDL_ShaderCross_SPIRV_Info *info,
    const SDL_ShaderCross_ComputePipelineMetadata *metadata,
    SDL_PropertiesID props);

/**
 * Reflect graphics shader info from SPIRV code. If your shader source is HLSL, you should obtain SPIR-V bytecode from SDL_ShaderCross_CompileSPIRVFromHLSL(). This must be freed with SDL_free() when you are done with the metadata.
 *
 * \param bytecode the SPIRV bytecode.
 * \param bytecode_size the length of the SPIRV bytecode.
 * \param props a properties object filled in with extra shader metadata, provided by the user.
 * \returns A metadata struct on success, NULL otherwise. The struct must be free'd when it is no longer needed.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC SDL_ShaderCross_GraphicsShaderMetadata * SDLCALL SDL_ShaderCross_ReflectGraphicsSPIRV(
    const Uint8 *bytecode,
    size_t bytecode_size,
    SDL_PropertiesID props);

/**
 * Reflect compute pipeline info from SPIRV code. If your shader source is HLSL, you should obtain SPIR-V bytecode from SDL_ShaderCross_CompileSPIRVFromHLSL(). This must be freed with SDL_free() when you are done with the metadata.
 *
 * \param bytecode the SPIRV bytecode.
 * \param bytecode_size the length of the SPIRV bytecode.
 * \param props a properties object filled in with extra shader metadata, provided by the user.
 * \returns A metadata struct on success, NULL otherwise.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC SDL_ShaderCross_ComputePipelineMetadata * SDLCALL SDL_ShaderCross_ReflectComputeSPIRV(
    const Uint8 *bytecode,
    size_t bytecode_size,
    SDL_PropertiesID props);

/**
 * Get the supported shader formats that HLSL cross-compilation can output
 *
 * \returns GPU shader formats supported by HLSL cross-compilation.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC SDL_GPUShaderFormat SDLCALL SDL_ShaderCross_GetHLSLShaderFormats(void);

/**
 * Compile to DXBC bytecode from HLSL code via a SPIRV-Cross round trip.
 *
 * You must SDL_free the returned buffer once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \param size filled in with the bytecode buffer size.
 * \returns an SDL_malloc'd buffer containing DXBC bytecode.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_CompileDXBCFromHLSL(
    const SDL_ShaderCross_HLSL_Info *info,
    size_t *size);

/**
 * Compile to DXIL bytecode from HLSL code via a SPIRV-Cross round trip.
 *
 * You must SDL_free the returned buffer once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \param size filled in with the bytecode buffer size.
 * \returns an SDL_malloc'd buffer containing DXIL bytecode.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_CompileDXILFromHLSL(
    const SDL_ShaderCross_HLSL_Info *info,
    size_t *size);

/**
 * Compile to SPIRV bytecode from HLSL code.
 *
 * You must SDL_free the returned buffer once you are done with it.
 *
 * \param info a struct describing the shader to transpile.
 * \param size filled in with the bytecode buffer size.
 * \returns an SDL_malloc'd buffer containing SPIRV bytecode.
 *
 * \threadsafety It is safe to call this function from any thread.
 */
extern SDL_DECLSPEC void * SDLCALL SDL_ShaderCross_CompileSPIRVFromHLSL(
    const SDL_ShaderCross_HLSL_Info *info,
    size_t *size);

#ifdef __cplusplus
}
#endif
#include <SDL3/SDL_close_code.h>

#endif /* SDL_SHADERCROSS_H */
