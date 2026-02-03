# r3d-odin binding generator

This is a script that automates the generation of Odin bindings for [r3d](https://github.com/Bigfoot71/r3d), including cross-compilation of static libraries for both Linux and Windows.

> [!WARNING]
> **This is currently a "works on my machine" setup.**
> It's primarily for personal use, including this readme.
> Only works for Linux, but contributions to improve portability are welcome.

## Prerequisites

### Required Tools

1. **CMake** (>= 3.8)
2. **Ninja** build system
3. **[odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen)** (by [Karl Zylinski](https://github.com/karl-zylinski))
4. **mingw-w64** cross-compiler (for Windows builds)
   ```bash
   # Debian/Ubuntu
   sudo apt install mingw-w64
   # Fedora
   sudo dnf install mingw64-gcc mingw64-gcc-c++
   ```
5. **Perl** (for post-processing)

### System Libraries (Linux builds only)

- `raylib` development headers
- `assimp` development headers

```bash
# Debian/Ubuntu
sudo apt install libraylib-dev libassimp-dev
# Fedora
sudo dnf install raylib-devel assimp-devel
```

### Submodules

**Critical:** Clone all submodules recursively before running the script:

```bash
git submodule update --init --recursive
```

This is especially important for the Windows build, which vendors `raylib` and `assimp` from r3d's submodules.

### Configuration

**Edit `bindgen.sjson` before first run:**

The `clang_include_paths` field is currently hardcoded to:
```json
"clang_include_paths": ["/usr/lib/clang/21/include"]
```

Update this path to match your system's Clang installation:
```bash
# Find your clang include directory
find /usr/lib/clang -name "stddef.h" 2>/dev/null | head -1 | xargs dirname
```

## How It Works

The script performs the following steps:

### 1. **Validation**
- Checks for required tools (`cmake`, `ninja`, `odin-c-bindgen`)
- Verifies r3d submodule and its dependencies are present

### 2. **cross platform Compilation**
Builds r3d as a static library for both platforms **in parallel**:

- **Linux build:** Uses system installed `raylib` and `assimp`
- **Windows build:** Uses mingw-w64 toolchain with vendored dependencies

Output: `libr3d.a` for each platform

### 3. **Library Placement**
Copies the compiled static libraries to the binding directory:
```
binding/r3d/
├── linux/libr3d.a
└── windows/libr3d.a
```

### 4. **Binding Generation**
- Copies r3d headers and footer files to `binding/inputs/`
- Runs `odin-c-bindgen` to generate Odin bindings from C headers

### 5. **Post-Processing**
Cleans up and fixes the generated `.odin` files:
- Converts tabs to spaces
- Realigns Doxygen comment blocks
- Updates file references (`.h` -> `.odin`)
- Prefixes raylib types with `rl.` namespace (e.g. `Vector3` -> `rl.Vector3`)

## Usage

```bash
./generate_binding.sh
```

Output will be in `binding/r3d/`:
- `*.odin` Generated Odin binding files
- `linux/libr3d.a` Linux static library
- `windows/libr3d.a` Windows static library

Build logs for each platform are saved as `binding/build_{platform}.log`.

## Troubleshooting

**Build fails for one platform:**
- Check the corresponding log file: `binding/build_linux.log` or `binding/build_windows.log`
- Ensure all submodules are initialized: `git submodule update --init --recursive`

**odin-c-bindgen fails:**
- Verify `bindgen.sjson` paths are correct for your system
- Ensure Clang headers are accessible

**mingw not found:**
- Install: `sudo apt install mingw-w64`
- Verify toolchain file exists: `r3d/cmake/mingw-w64-x86_64.cmake`

## Contributing

Contributions are welcome, especially for:
- Windows native script support
- Improved cross platform configuration detection
- Additional platform targets (macOS, BSDs)

## License

- **This binding generator script:** MIT License
- **Generated bindings:** Zlib License (same as the r3d library)
