//+build windows
package all

import botan     "vendor:botan"
import ENet      "vendor:ENet"
import gl        "vendor:OpenGL"
import glfw      "vendor:glfw"
import microui   "vendor:microui"
import miniaudio "vendor:miniaudio"
import PM        "vendor:portmidi"
import rl        "vendor:raylib"

import SDL    "vendor:sdl2"
import SDLNet "vendor:sdl2/net"
import IMG    "vendor:sdl2/image"
import MIX    "vendor:sdl2/mixer"
import TTF    "vendor:sdl2/ttf"

import stb_easy_font "vendor:stb/easy_font"
import stbi          "vendor:stb/image"
import stbrp         "vendor:stb/rect_pack"
import stbtt         "vendor:stb/truetype"
import stb_vorbis    "vendor:stb/vorbis"

import vk "vendor:vulkan"

import D3D11 "vendor:directx/d3d11"
import D3D12 "vendor:directx/d3d12"
import DXGI  "vendor:directx/dxgi"

// note these are technicaly darwin only but they are added to aid with documentation generation
import NS  "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA  "vendor:darwin/QuartzCore"


_ :: botan
_ :: ENet
_ :: gl
_ :: glfw
_ :: microui
_ :: miniaudio
_ :: PM
_ :: rl
_ :: SDL
_ :: SDLNet
_ :: IMG
_ :: MIX
_ :: TTF
_ :: stb_easy_font
_ :: stbi
_ :: stbrp
_ :: stbtt
_ :: stb_vorbis
_ :: vk
_ :: D3D11
_ :: D3D12
_ :: DXGI
_ :: NS
_ :: MTL
_ :: CA