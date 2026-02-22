#!/bin/bash
set -euo pipefail

# ANSI color codes :3
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_RED='\033[0;31m'
readonly C_BLUE='\033[0;34m'
readonly C_CYAN='\033[0;36m'

# Paths
readonly DIR="./r3d/include/r3d"
readonly BINDING="./binding"
readonly BASE="./base"
readonly CMAKE_COMMON="-DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -G Ninja"

# Platform-specific vendor flags
readonly VENDOR_FLAGS_LINUX="-DR3D_RAYLIB_VENDORED=ON -DR3D_ASSIMP_VENDORED=ON"
readonly VENDOR_FLAGS_WINDOWS="-DR3D_RAYLIB_VENDORED=ON -DR3D_ASSIMP_VENDORED=ON"

# Parse command line arguments
PREBUILT_LIBS_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --prebuilt-libs)
            PREBUILT_LIBS_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--prebuilt-libs <directory>]"
            exit 1
            ;;
    esac
done

# Helper functions
log_step() {
    echo -e "${C_BOLD}${C_BLUE}▸ Step $1:${C_RESET} ${C_CYAN}$2${C_RESET}"
}

log_info() {
    echo -e "  ${C_GREEN}✓${C_RESET} $1"
}

log_warn() {
    echo -e "  ${C_YELLOW}⚠${C_RESET} $1"
}

log_error() {
    echo -e "  ${C_RED}✗${C_RESET} $1" >&2
}

log_dim() {
    echo -e "  ${C_DIM}$1${C_RESET}"
}

# ================================================================
# 1. Preliminary checks
# ================================================================

log_step "1" "Preliminary checks"

# Required tools
readonly REQUIRED_TOOLS=(odin-c-bindgen)
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        log_error "'$tool' not found in PATH"
        exit 1
    fi
done
log_info "All required tools available: ${REQUIRED_TOOLS[*]}"

# Main r3d submodule
if [[ ! -d "$DIR" ]] || [[ -z "$(ls -A "$DIR" 2>/dev/null)" ]]; then
    log_error "$DIR is missing or empty"
    log_dim "Run: git submodule update --init --recursive"
    exit 1
fi
log_info "r3d submodule present"

# ================================================================
# 2. Handle libraries (pre-built or build from source)
# ================================================================

if [[ -n "$PREBUILT_LIBS_DIR" ]]; then
    log_step "2" "Using pre-built libraries"

    # Check all required libraries before doing anything
    MISSING_LIBS=()

    [[ ! -f "$PREBUILT_LIBS_DIR/linux/libr3d.a" ]]    && MISSING_LIBS+=("linux/libr3d.a")
    [[ ! -f "$PREBUILT_LIBS_DIR/linux/libassimp.a" ]]  && MISSING_LIBS+=("linux/libassimp.a")
    [[ ! -f "$PREBUILT_LIBS_DIR/windows/libr3d.a" ]]   && MISSING_LIBS+=("windows/libr3d.a")
    [[ ! -f "$PREBUILT_LIBS_DIR/windows/libassimp.a" ]] && MISSING_LIBS+=("windows/libassimp.a")

    if [[ ${#MISSING_LIBS[@]} -gt 0 ]]; then
        log_warn "The following libraries are missing from '$PREBUILT_LIBS_DIR':"
        for lib in "${MISSING_LIBS[@]}"; do
            log_dim "  - $lib"
        done
        log_warn "Cannot use pre-built libraries - falling back to automatic build from source"
        PREBUILT_LIBS_DIR=""
    else
        mkdir -p "$BINDING/r3d/linux" "$BINDING/r3d/windows"

        for platform in linux windows; do
            for lib in libr3d.a libassimp.a; do
                cp "$PREBUILT_LIBS_DIR/$platform/$lib" "$BINDING/r3d/$platform/$lib"
                log_dim "$platform: $lib (pre-built)"
            done
        done

        log_info "Pre-built libraries ready"
    fi
fi

if [[ -z "$PREBUILT_LIBS_DIR" ]]; then
    log_step "2" "Building libraries from source"

    # Additional tools required for building
    for tool in cmake ninja; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "'$tool' not found in PATH (required for building libraries)"
            exit 1
        fi
    done

    # Internal r3d submodules check
    readonly CRITICAL_SUBMODULES=(
        "r3d/external/assimp/CMakeLists.txt"
        "r3d/external/raylib/src/raylib.h"
    )
    for sub in "${CRITICAL_SUBMODULES[@]}"; do
        if [[ ! -f "$sub" ]]; then
            log_error "$sub not found"
            log_dim "Run: cd r3d && git submodule update --init --recursive"
            exit 1
        fi
    done
    log_info "Internal submodules present"

    readonly BUILD_LINUX="$BINDING/build/linux"
    readonly BUILD_WIN="$BINDING/build/windows"
    mkdir -p "$BUILD_LINUX" "$BUILD_WIN"

    # Temporary directory for error sentinels
    readonly ERRDIR=$(mktemp -d)
    trap "rm -rf $ERRDIR" EXIT

    # Generic build function with platform specific logging
    build_platform() {
        local platform="$1"
        local build_dir="$2"
        local extra_flags="$3"
        local logfile="$BINDING/build_${platform}.log"

        log_dim "Building for $platform (log: $logfile)"

        if (
            cd "$build_dir"
            cmake ../../../r3d $CMAKE_COMMON $extra_flags 2>&1
            ninja 2>&1
        ) > "$logfile" 2>&1; then
            log_info "$platform build successful"
        else
            log_error "$platform build failed - see $logfile"
            touch "$ERRDIR/$platform"
        fi
    }

    # Launch builds in parallel
    build_platform "linux"   "$BUILD_LINUX" "$VENDOR_FLAGS_LINUX" &
    build_platform "windows" "$BUILD_WIN"   "$VENDOR_FLAGS_WINDOWS -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake" &

    wait

    # Check for build failures
    if compgen -G "$ERRDIR/*" > /dev/null; then
        log_error "Build failed for: $(ls "$ERRDIR" | tr '\n' ' ')"
        exit 1
    fi

    # Copy static libraries
    log_step "3" "Copying built libraries"

    mkdir -p "$BINDING/r3d/linux" "$BINDING/r3d/windows"

    for platform in linux windows; do
        build_dir="$BINDING/build/$platform"

        for lib in libr3d.a libassimp.a; do
            src=$(find "$build_dir" -name "$lib" | head -1)

            if [[ -z "$src" ]]; then
                log_error "$lib not found in $build_dir - check build logs"
                exit 1
            fi

            cp "$src" "$BINDING/r3d/$platform/$lib"
            log_dim "$platform: $lib"
        done
    done

    log_info "Libraries copied successfully"
fi

# ================================================================
# 3. Prepare binding configuration
# ================================================================

NEXT_STEP=$([[ -z "$PREBUILT_LIBS_DIR" ]] && echo "4" || echo "3")
log_step "$NEXT_STEP" "Preparing binding configuration"

# Create inputs directory
mkdir -p "$BINDING/inputs"

# Copy r3d headers
cp -r ./r3d/include/r3d/* "$BINDING/inputs/"
log_dim "Copied r3d headers"

# Copy footer files from base
cp -r "$BASE/inputs/"* "$BINDING/inputs/"
log_dim "Copied footer files"

# Copy imports.odin to binding directory
cp "$BASE/imports.odin" "$BINDING/"
log_dim "Copied imports.odin"

# Copy and configure bindgen.sjson
cp "$BASE/bindgen.sjson" "$BINDING/"

# Auto-detect clang include path
CLANG_INCLUDE=$(clang -print-resource-dir)/include

if [[ ! -f "$CLANG_INCLUDE/stddef.h" ]]; then
    log_error "Could not find clang includes at $CLANG_INCLUDE"
    exit 1
fi
log_dim "Detected clang includes: $CLANG_INCLUDE"

# Replace placeholder in bindgen.sjson
sed -i "s|@CLANG_INCLUDE@|$CLANG_INCLUDE|g" "$BINDING/bindgen.sjson"
log_info "Configuration prepared"

# ================================================================
# 4. Generate bindings (odin-c-bindgen)
# ================================================================

NEXT_STEP=$((NEXT_STEP + 1))
log_step "$NEXT_STEP" "Generating bindings"

# Run odin-c-bindgen from the binding directory
if (cd "$BINDING" && odin-c-bindgen .) 2>&1; then
    log_info "Bindings generated"
else
    log_error "odin-c-bindgen failed"
    exit 1
fi
echo ""

# ================================================================
# 5. Clean up and fix raylib types
# ================================================================

NEXT_STEP=$((NEXT_STEP + 1))
log_step "$NEXT_STEP" "Post-processing bindings"

# Remove the generated 'r3d.odin' file, which is unnecessary
# TODO: Check whether we can ignore it via odin-c-bindgen
if [[ -f "$BINDING/r3d/r3d.odin" ]]; then
    rm "$BINDING/r3d/r3d.odin"
    log_dim "Removed r3d.odin"
fi

# Raylib types to prefix with 'rl.'
# Ordered: compound types before base types
readonly RAYLIB_TYPES=(
    "RenderTexture2D" "RenderTexture"
    "Texture2D" "TextureCube" "Texture"
    "RayCollision" "Ray"
    "BoundingBox" "Rectangle"
    "Vector2" "Vector3" "Vector4" "Quaternion"
    "Matrix" "Color" "Transform"
    "Camera3D" "CameraMode" "CameraProjection" "Camera"
    "Image" "TextureFilter" "TextureWrap" "PixelFormat"
)

# Build sed arguments for type substitution
SED_ARGS=()
for type in "${RAYLIB_TYPES[@]}"; do
    SED_ARGS+=(-e "s/\b${type}\b/rl.${type}/g")
done

# Process each generated .odin file
shopt -s nullglob
odin_files=("$BINDING"/r3d/*.odin)

if [[ ${#odin_files[@]} -eq 0 ]]; then
    log_warn "No .odin files found in $BINDING/r3d"
else
    for file in "${odin_files[@]}"; do
        # Convert tabs to 4 spaces
        sed -i 's/\t/    /g' "$file"

        # Realign Doxygen comment blocks
        perl -pi -e '
            BEGIN { $indent = undef; }
            if (/^([ ]*)\/\*/) {
                $indent = $1;
            } elsif (defined $indent && /^[ ]*(\*.*)$/) {
                $_ = $indent . " " . $1 . "\n";
            }
            if (defined $indent && /\*\/\s*$/) {
                $indent = undef;
            }
        ' "$file"

        # Fix file references in comments: .h -> .odin
        sed -i -E '/^[[:space:]]*(\/\*|\*).*\.h/{ s/\.h\b/.odin/g; }' "$file"

        # Prefix raylib types with 'rl.'
        sed -i "${SED_ARGS[@]}" "$file"
    done

    log_info "Processed ${#odin_files[@]} binding file(s)"
fi

# ================================================================
# Done
# ================================================================

echo ""
if [[ -n "$PREBUILT_LIBS_DIR" ]]; then
    echo -e "${C_BOLD}${C_GREEN}✓ Complete!${C_RESET} ${C_DIM}(using pre-built libs)${C_RESET} Output: ${C_CYAN}$BINDING/r3d${C_RESET}"
else
    echo -e "${C_BOLD}${C_GREEN}✓ Complete!${C_RESET} ${C_DIM}(built from source)${C_RESET} Output: ${C_CYAN}$BINDING/r3d${C_RESET}"
fi

# ================================================================
# LICENSE
# ================================================================

# MIT License
#
# Copyright (c) 2026 Le Juez Victor
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
