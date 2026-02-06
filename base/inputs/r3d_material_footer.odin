/**
 * @brief Default material configuration.
 *
 * Initializes an R3D_Material structure with sensible default values for all
 * rendering parameters. Use this as a starting point for custom configurations.
 */
MATERIAL_BASE :: Material {
    albedo = {
        texture = {},
        color   = {255, 255, 255, 255},
    },
    emission = {
        texture = {},
        color   = {255, 255, 255, 255},
        energy  = 0.0,
    },
    normal = {
        texture = {},
        scale   = 1.0,
    },
    orm = {
        texture   = {},
        occlusion = 1.0,
        roughness = 1.0,
        metalness = 0.0,
    },
    uvOffset = {0.0, 0.0},
    uvScale  = {1.0, 1.0},
    alphaCutoff = 0.01,
    depth = {
        mode         = .LESS,
        offsetFactor = 0.0,
        offsetUnits  = 0.0,
        rangeNear    = 0.0,
        rangeFar     = 1.0,
    },
    stencil = {
        mode     = .ALWAYS,
        ref      = 0x00,
        mask     = 0xFF,
        opFail   = .KEEP,
        opZFail  = .KEEP,
        opPass   = .REPLACE,
    },
    transparencyMode = .DISABLED,
    billboardMode    = .DISABLED,
    blendMode        = .MIX,
    cullMode         = .BACK,
    unlit  = false,
    shader = nil,
}
