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
readonly REQUIRED_TOOLS=(cmake ninja odin-c-bindgen)
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

# Internal r3d submodules
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

# ================================================================
# 2. CMake build (Linux + Windows in parallel)
# ================================================================

log_step "2" "Building libraries"

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
        log_error "$platform build failed — see $logfile"
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

# ================================================================
# 3. Copy static libraries
# ================================================================

log_step "3" "Copying libraries"

mkdir -p "$BINDING/r3d/linux" "$BINDING/r3d/windows"

for platform in linux windows; do
    src="$BINDING/build/$platform/lib/libr3d.a"
    dst="$BINDING/r3d/$platform/libr3d.a"

    if [[ ! -f "$src" ]]; then
        log_error "$src not found — check build logs"
        exit 1
    fi

    cp "$src" "$dst"
    log_dim "$platform: libr3d.a"
done
log_info "Libraries copied successfully"

# ================================================================
# 4. Prepare binding configuration
# ================================================================

log_step "4" "Preparing binding configuration"

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
CLANG_INCLUDE=""

# First try with llvm-config (reliable when LLVM is installed via llvm.sh)
if command -v llvm-config &>/dev/null; then
    LLVM_PREFIX=$(llvm-config --prefix)
    if [[ -f "$LLVM_PREFIX/lib/clang/$(llvm-config --version | cut -d' ' -f1)/include/stddef.h" ]]; then
        CLANG_INCLUDE="$LLVM_PREFIX/lib/clang/$(llvm-config --version | cut -d' ' -f1)/include"
    fi
fi

# Fallback: searches in standard paths
if [[ -z "$CLANG_INCLUDE" ]]; then
    CANDIDATE=$(find /usr/lib/clang /usr/lib/llvm-*/lib/clang -name "stddef.h" 2>/dev/null | head -1)
    if [[ -n "$CANDIDATE" ]]; then
        CLANG_INCLUDE=$(dirname "$CANDIDATE")
    fi
fi

if [[ -z "$CLANG_INCLUDE" ]]; then
    log_error "Could not find clang includes"
    exit 1
fi
log_dim "Detected clang includes: $CLANG_INCLUDE"

# Replace placeholder in bindgen.sjson
sed -i "s|@CLANG_INCLUDE@|$CLANG_INCLUDE|g" "$BINDING/bindgen.sjson"
log_info "Configuration prepared"

# ================================================================
# 5. Generate bindings (odin-c-bindgen)
# ================================================================

log_step "5" "Generating bindings"

# Run odin-c-bindgen from the binding directory
if (cd "$BINDING" && odin-c-bindgen .) 2>&1; then
    log_info "Bindings generated"
else
    log_error "odin-c-bindgen failed"
    exit 1
fi
echo ""

# ================================================================
# 6. Clean up and fix raylib types
# ================================================================

log_step "6" "Post-processing bindings"

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
echo -e "${C_BOLD}${C_GREEN}✓ Complete!${C_RESET} Output: ${C_CYAN}$BINDING/r3d${C_RESET}"

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
