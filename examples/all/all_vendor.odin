package all

import botan_bindings "vendor:botan/bindings"
import botan_blake2b  "vendor:botan/blake2b"
import keccak         "vendor:botan/legacy/keccak"
import md5            "vendor:botan/legacy/md5"
import sha1           "vendor:botan/legacy/sha1"
import sha2           "vendor:botan/sha2"
import sha3           "vendor:botan/sha3"
import shake          "vendor:botan/shake"
import siphash        "vendor:botan/siphash"
import sm3            "vendor:botan/sm3"

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

// NOTE(bill): only one can be checked at a time
import lua_5_4    "vendor:lua/5.4"

import nvg       "vendor:nanovg"
import nvg_gl    "vendor:nanovg/gl"
import fontstash "vendor:fontstash"

import xlib       "vendor:x11/xlib"

_ :: botan_bindings
_ :: botan_blake2b
_ :: keccak
_ :: md5
_ :: sha1
_ :: sha2
_ :: sha3
_ :: shake
_ :: siphash
_ :: sm3


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

_ :: lua_5_4

_ :: nvg
_ :: nvg_gl
_ :: fontstash

_ :: xlib


// NOTE: needed for doc generator

import NS  "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import MTK "vendor:darwin/MetalKit"
import CA  "vendor:darwin/QuartzCore"

_ :: NS
_ :: MTL
_ :: MTK
_ :: CA


import D3D11 "vendor:directx/d3d11"
import D3D12 "vendor:directx/d3d12"
import DXGI  "vendor:directx/dxgi"

_ :: D3D11
_ :: D3D12
_ :: DXGI


import cm "vendor:commonmark"
_ :: cm


import stb_easy_font "vendor:stb/easy_font"
import stbi          "vendor:stb/image"
import stbrp         "vendor:stb/rect_pack"
import stbtt         "vendor:stb/truetype"
import stb_vorbis    "vendor:stb/vorbis"

_ :: stb_easy_font
_ :: stbi
_ :: stbrp
_ :: stbtt
_ :: stb_vorbis

