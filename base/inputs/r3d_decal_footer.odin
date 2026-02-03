/**
 * @brief Default decal configuration.
 *
 * Contains a R3D_Decal structure with sensible default values for all rendering parameters.
 */
DECAL_BASE :: Decal {
    albedo = {
        texture = {},
        color = {255, 255, 255, 255},
    },
    emission = {
        texture = {},
        color = {255, 255, 255, 255},
        energy = 0.0,
    },
    normal = {
        texture = {},
        scale = 1.0,
    },
    orm = {
        texture = {},
        occlusion = 1.0,
        roughness = 1.0,
        metalness = 0.0,
    },
    uvOffset = {0.0, 0.0},
    uvScale = {1.0, 1.0},
    alphaCutoff = 0.01,
    normalThreshold = 0,
    fadeWidth = 0,
    applyColor = true,
    shader = nil,
}
