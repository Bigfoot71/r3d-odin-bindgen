# r3d-odin-bindgen

Automated Odin binding generator for [r3d](https://github.com/Bigfoot71/r3d).
This repository contains the tooling used to generate and maintain the [r3d-odin](https://github.com/Bigfoot71/r3d-odin) bindings.

## Overview

This repository serves two purposes:

1. **Automated binding generation** via GitHub Actions - Used to automatically generate and publish Odin bindings whenever r3d is updated
2. **Local binding generation** - You can clone this repository to generate bindings for custom r3d versions

The binding generator handles cross compilation for Linux and Windows, ensuring bindings include pre-compiled static libraries for both platforms.

## How It Works

### Automated Workflow (GitHub Actions)

When changes are pushed to the [r3d](https://github.com/Bigfoot71/r3d) repository:

1. r3d's CI builds static libraries for all platforms (Linux, Windows)
2. Upon successful build, this repository is triggered automatically
3. Pre-built libraries are downloaded from r3d's artifacts
4. Odin bindings are generated using the headers and pre-built libraries
5. Generated bindings are automatically committed to [r3d-odin](https://github.com/Bigfoot71/r3d-odin)

### Local Generation

If you working with modified r3d versions, the script can:

- **Use pre-built libraries** via `--prebuilt-libs` flag
- **Build from submodule** when libraries aren't provided

## Prerequisites

### Core Requirements

All usage modes require:

1. **[odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen)** by [Karl Zylinski](https://github.com/karl-zylinski)
2. **Clang** (versions 14, 17, 18, 19, 20, or 21)
3. **Perl** (for post-processing)

### Additional Requirements (build from source)

If not using pre-built libraries:

4. **CMake** (>= 3.8)
5. **Ninja** build system
6. **mingw-w64** cross-compiler (for Windows builds)
   ```bash
   # Debian/Ubuntu
   sudo apt install mingw-w64

   # Fedora
   sudo dnf install mingw64-gcc mingw64-gcc-c++
   ```

### Submodules

Clone all submodules recursively:

```bash
git submodule update --init --recursive
```

The r3d submodule contains:
- Header files (always required)
- External dependencies like raylib and assimp (required only when building from source)

### Configuration

**First-time setup:** Configure Clang include paths in `base/bindgen.sjson`

The placeholder `@CLANG_INCLUDE@` will be automatically replaced at runtime:

```json
"clang_include_paths": ["@CLANG_INCLUDE@"]
```

The script will auto-detect and configure this path during execution with:

```bash
clang -print-resource-dir
```

## Usage

### Using Pre-built Libraries

If you have pre-built r3d libraries:

```bash
./bindgen.sh --prebuilt-libs /path/to/libs
```

Expected directory structure:

```
/path/to/libs/
├── linux/libr3d.a
└── windows/libr3d.a
```

### Building from Source

Without pre-built libraries, the script compiles r3d automatically:

```bash
./bindgen.sh
```

This performs cross-platform compilation:
- **Linux build:** Vendors raylib and assimp
- **Windows build:** Uses mingw-w64 with vendored dependencies

### Output

All modes produce the same output in `binding/r3d/`:

```
binding/r3d/
├── *.odin                 # Generated binding files
├── linux/libr3d.a         # Linux static library
└── windows/libr3d.a       # Windows static library
```

Build logs are saved as `binding/build_{platform}.log` when building from source.

## Process Details

### 1. Validation
- Verifies required tools are available
- Checks r3d submodule is present
- Validates submodule dependencies (when building from source)

### 2. Library Acquisition
- **With `--prebuilt-libs`:** Copies provided libraries directly
- **Without flag:** Builds r3d for Linux and Windows in parallel

### 3. Binding Configuration
- Copies r3d headers to working directory
- Copies footer files (custom Odin additions)
- Auto-detects and configures Clang include paths
- Prepares `bindgen.sjson` configuration

### 4. Binding Generation
Runs `odin-c-bindgen` to generate Odin bindings from C headers

### 5. Post-Processing
Applies transformations to generated files:
- Converts tabs to spaces
- Realigns Doxygen comment blocks
- Updates file references (`.h` -> `.odin`)
- Prefixes raylib types with `rl.` namespace (e.g., `Vector3` -> `rl.Vector3`)

## Platform Support

**Development platform:** Linux only

The script generates bindings and libraries for:
- Linux (native compilation)
- Windows (cross-compilation via mingw-w64)

**Note:** macOS support could be added via CI but local generation remains Linux-only. Contributions for native Windows or macOS support are welcome.

## Troubleshooting

### Build Failures

**One platform fails:**
- Check logs: `binding/build_linux.log` or `binding/build_windows.log`
- Verify submodules: `git submodule update --init --recursive`

**odin-c-bindgen fails:**
- Ensure Clang is installed and accessible
- Verify `odin-c-bindgen` is in PATH
- Check that r3d headers are present

**mingw-w64 not found:**
- Install: `sudo apt install mingw-w64`
- Verify toolchain: `r3d/cmake/mingw-w64-x86_64.cmake`

### Pre-built Libraries

**Libraries not found:**
- Verify directory structure matches expected format
- Ensure both `linux/libr3d.a` and `windows/libr3d.a` exist
- Check file permissions

## Contributing

Contributions are welcome for:

- Native Windows script support
- macOS binding generation
- Improved cross-platform configuration detection
- Additional platform targets (BSDs, etc.)
- Build optimization and caching

## License

- **This binding generator script:** MIT License
- **Generated bindings:** Zlib License (same as r3d)

The generated Odin bindings are derivative works of r3d, not of this generator script.
