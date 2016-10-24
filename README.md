
# ulubis-sdl

ulubis-sdl is a backend for [the ulubis window compositor](https://github.com/malcolmstill/ulubis). It allows ulubis to run on X via SDL.

# Requirements

ulubis-sdl requires: cffi and cl-sdl2.

# Installation

After installing ulubis with `(ql:quickload :ulubis)`, scripts in the `build` directory will automatically download `ulubis-sdl`. Otherwise you can run `(ql:quickload :ulubis-sdl)` directly.