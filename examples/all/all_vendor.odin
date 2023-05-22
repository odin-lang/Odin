package all

import botan      "vendor:botan"
import cgltf      "vendor:cgltf"
// import commonmark "vendor:commonmark"
import ENet       "vendor:ENet"
import exr        "vendor:OpenEXRCore"
import ggpo       "vendor:ggpo"
import gl         "vendor:OpenGL"
import glfw       "vendor:glfw"
import microui    "vendor:microui"
import miniaudio  "vendor:miniaudio"
import PM         "vendor:portmidi"
import rl         "vendor:raylib"
import zlib       "vendor:zlib"

import SDL        "vendor:sdl2"
import SDLNet     "vendor:sdl2/net"
import IMG        "vendor:sdl2/image"
import MIX        "vendor:sdl2/mixer"
import TTF        "vendor:sdl2/ttf"

import vk         "vendor:vulkan"

import NS         "vendor:darwin/Foundation"
import MTL        "vendor:darwin/Metal"
import MTK        "vendor:darwin/MetalKit"
import CA         "vendor:darwin/QuartzCore"

// NOTE(bill): only one can be checked at a time
import lua_5_4    "vendor:lua/5.4"

_ :: botan
_ :: cgltf
// _ :: commonmark
_ :: ENet
_ :: exr
_ :: ggpo
_ :: gl
_ :: glfw
_ :: microui
_ :: miniaudio
_ :: PM
_ :: rl
_ :: zlib

_ :: SDL
_ :: SDLNet
_ :: IMG
_ :: MIX
_ :: TTF

_ :: vk

_ :: NS
_ :: MTL
_ :: MTK
_ :: CA

_ :: lua_5_4