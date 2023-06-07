package all

import botan_bindings "vendor:botan/bindings"
import botan_blake2b  "vendor:botan/blake2b"
import gost           "vendor:botan/gost"
import keccak         "vendor:botan/keccak"
import md4            "vendor:botan/md4"
import md5            "vendor:botan/md5"
import ripemd         "vendor:botan/ripemd"
import sha1           "vendor:botan/sha1"
import sha2           "vendor:botan/sha2"
import sha3           "vendor:botan/sha3"
import shake          "vendor:botan/shake"
import siphash        "vendor:botan/siphash"
import skein512       "vendor:botan/skein512"
import sm3            "vendor:botan/sm3"
import streebog       "vendor:botan/streebog"
import tiger          "vendor:botan/tiger"
import whirlpool      "vendor:botan/whirlpool"

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

_ :: botan_bindings
_ :: botan_blake2b
_ :: gost
_ :: keccak
_ :: md4
_ :: md5
_ :: ripemd
_ :: sha1
_ :: sha2
_ :: sha3
_ :: shake
_ :: siphash
_ :: skein512
_ :: sm3
_ :: streebog
_ :: tiger
_ :: whirlpool


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