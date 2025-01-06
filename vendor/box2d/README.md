![Box2D Logo](https://box2d.org/images/logo.svg)

# Status
[![Build Status](https://github.com/erincatto/box2c/actions/workflows/build.yml/badge.svg)](https://github.com/erincatto/box2c/actions)

# Box2D v3.0 Notes
This repository is beta and ready for testing. It should build on recent versions of clang and gcc. However, you will need the latest Visual Studio version for C11 atomics to compile (17.8.3+).

AVX2 CPU support is assumed. You can turn this off in the CMake options and use SSE2 instead.

# Box2D
Box2D is a 2D physics engine for games.

## Contributing
Please do not submit pull requests with new features or core library changes. Instead, please file an issue first for discussion. For bugs, I prefer detailed bug reports over pull requests.

# Giving Feedback
Please visit the discussions tab, file an issue, or start a chat on discord.

## Community
- [Discord](https://discord.gg/NKYgCBP)

## License
Box2D is developed by Erin Catto, and uses the [MIT license](https://en.wikipedia.org/wiki/MIT_License).

## Sponsorship
Support development of Box2D through [Github Sponsors](https://github.com/sponsors/erincatto)

## Ports, wrappers, and Bindings
- https://github.com/odin-lang/Odin/tree/master/vendor/box2d
- https://github.com/EnokViking/Box2DBeef
- https://github.com/HolyBlackCat/box2cpp