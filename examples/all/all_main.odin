package all

// Imports every package
// This is useful for knowing what exists and producing documentation with `odin doc`

import bufio            "core:bufio"
import bytes            "core:bytes"

import c                "core:c"
import libc             "core:c/libc"

import compress         "core:compress"
import shoco            "core:compress/shoco"
import gzip             "core:compress/gzip"
import zlib             "core:compress/zlib"

import avl              "core:container/avl"
import bit_array        "core:container/bit_array"
import priority_queue   "core:container/priority_queue"
import queue            "core:container/queue"
import small_array      "core:container/small_array"
import lru              "core:container/lru"
import list             "core:container/intrusive/list"
import rbtree           "core:container/rbtree"
import topological_sort "core:container/topological_sort"

import crypto           "core:crypto"
import aead             "core:crypto/aead"
import aes              "core:crypto/aes"
import blake2b          "core:crypto/blake2b"
import blake2s          "core:crypto/blake2s"
import chacha20         "core:crypto/chacha20"
import chacha20poly1305 "core:crypto/chacha20poly1305"
import crypto_hash      "core:crypto/hash"
import ed25519          "core:crypto/ed25519"
import hkdf             "core:crypto/hkdf"
import hmac             "core:crypto/hmac"
import kmac             "core:crypto/kmac"
import keccak           "core:crypto/legacy/keccak"
import md5              "core:crypto/legacy/md5"
import sha1             "core:crypto/legacy/sha1"
import pbkdf2           "core:crypto/pbkdf2"
import poly1305         "core:crypto/poly1305"
import ristretto255     "core:crypto/ristretto255"
import sha2             "core:crypto/sha2"
import sha3             "core:crypto/sha3"
import shake            "core:crypto/shake"
import sm3              "core:crypto/sm3"
import tuplehash        "core:crypto/tuplehash"
import x25519           "core:crypto/x25519"

import pe               "core:debug/pe"
import trace            "core:debug/trace"

import dynlib           "core:dynlib"
import net              "core:net"

import ansi             "core:encoding/ansi"
import base32           "core:encoding/base32"
import base64           "core:encoding/base64"
import cbor             "core:encoding/cbor"
import csv              "core:encoding/csv"
import endian           "core:encoding/endian"
import hxa              "core:encoding/hxa"
import ini              "core:encoding/ini"
import json             "core:encoding/json"
import varint           "core:encoding/varint"
import xml              "core:encoding/xml"
import uuid             "core:encoding/uuid"
import uuid_legacy      "core:encoding/uuid/legacy"

import fmt              "core:fmt"
import hash             "core:hash"
import xxhash           "core:hash/xxhash"

import image            "core:image"
import bmp              "core:image/bmp"
import netpbm           "core:image/netpbm"
import png              "core:image/png"
import qoi              "core:image/qoi"
import tga              "core:image/tga"

import io               "core:io"
import log              "core:log"

import math             "core:math"
import big              "core:math/big"
import bits             "core:math/bits"
import fixed            "core:math/fixed"
import linalg           "core:math/linalg"
import glm              "core:math/linalg/glsl"
import hlm              "core:math/linalg/hlsl"
import noise            "core:math/noise"
import rand             "core:math/rand"
import ease             "core:math/ease"
import cmplx            "core:math/cmplx"

import mem              "core:mem"
import tlsf             "core:mem/tlsf"
import virtual          "core:mem/virtual"

import ast              "core:odin/ast"
import doc_format       "core:odin/doc-format"
import odin_parser      "core:odin/parser"
import odin_tokenizer   "core:odin/tokenizer"

import spall            "core:prof/spall"

import os               "core:os"

import slashpath        "core:path/slashpath"
import filepath         "core:path/filepath"

import relative         "core:relative"

import reflect          "core:reflect"
import runtime          "base:runtime"
import simd             "core:simd"
import x86              "core:simd/x86"
import slice            "core:slice"
import slice_heap       "core:slice/heap"
import sort             "core:sort"
import strconv          "core:strconv"
import strings          "core:strings"
import sync             "core:sync"
import testing          "core:testing"

import edit             "core:text/edit"
import i18n             "core:text/i18n"
import match            "core:text/match"
import regex            "core:text/regex"
import scanner          "core:text/scanner"
import table            "core:text/table"

import thread           "core:thread"
import time             "core:time"
import datetime         "core:time/datetime"
import flags            "core:flags"

import orca             "core:sys/orca"
import sysinfo          "core:sys/info"

import unicode          "core:unicode"
import utf8             "core:unicode/utf8"
import utf8string       "core:unicode/utf8/utf8string"
import utf16            "core:unicode/utf16"

main :: proc(){}


_ :: bufio
_ :: bytes
_ :: c
_ :: libc
_ :: compress
_ :: shoco
_ :: gzip
_ :: zlib
_ :: avl
_ :: bit_array
_ :: priority_queue
_ :: queue
_ :: small_array
_ :: lru
_ :: list
_ :: rbtree
_ :: topological_sort
_ :: crypto
_ :: crypto_hash
_ :: aead
_ :: aes
_ :: blake2b
_ :: blake2s
_ :: chacha20
_ :: chacha20poly1305
_ :: ed25519
_ :: hmac
_ :: hkdf
_ :: kmac
_ :: keccak
_ :: md5
_ :: pbkdf2
_ :: poly1305
_ :: ristretto255
_ :: sha1
_ :: sha2
_ :: sha3
_ :: shake
_ :: sm3
_ :: tuplehash
_ :: x25519
_ :: pe
_ :: trace
_ :: dynlib
_ :: net
_ :: ansi
_ :: base32
_ :: base64
_ :: csv
_ :: hxa
_ :: ini
_ :: json
_ :: varint
_ :: xml
_ :: endian
_ :: cbor
_ :: fmt
_ :: hash
_ :: xxhash
_ :: image
_ :: bmp
_ :: netpbm
_ :: png
_ :: qoi
_ :: tga
_ :: io
_ :: log
_ :: math
_ :: big
_ :: bits
_ :: fixed
_ :: linalg
_ :: glm
_ :: hlm
_ :: noise
_ :: rand
_ :: ease
_ :: cmplx
_ :: mem
_ :: tlsf
_ :: virtual
_ :: ast
_ :: doc_format
_ :: odin_parser
_ :: odin_tokenizer
_ :: os
_ :: spall
_ :: slashpath
_ :: filepath
_ :: relative
_ :: reflect
_ :: runtime
_ :: simd
_ :: x86
_ :: slice
_ :: slice_heap
_ :: sort
_ :: strconv
_ :: strings
_ :: sync
_ :: testing
_ :: scanner
_ :: i18n
_ :: match
_ :: regex
_ :: table
_ :: edit
_ :: thread
_ :: time
_ :: datetime
_ :: flags
_ :: orca
_ :: sysinfo
_ :: unicode
_ :: uuid
_ :: uuid_legacy
_ :: utf8
_ :: utf8string
_ :: utf16
