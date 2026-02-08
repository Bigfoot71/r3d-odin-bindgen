/**
 * @brief Default environment configuration.
 *
 * Initializes an R3D_Environment structure with sensible default values for all
 * rendering parameters. Use this as a starting point for custom configurations.
 */
ENVIRONMENT_BASE :: Environment {
    background = {
        color    = rl.GRAY,
        energy   = 1.0,
        skyBlur  = 0.0,
        sky      = {},
        rotation = quaternion(x=0.0, y=0.0, z=0.0, w=1.0),
    },
    ambient = {
        color  = rl.BLACK,
        energy = 1.0,
        _map   = {},
    },
    ssao = {
        sampleCount = 16,
        intensity   = 0.5,
        power       = 1.5,
        radius      = 0.5,
        bias        = 0.02,
        enabled     = false,
    },
    ssil = {
        sampleCount  = 4,
        sliceCount   = 4,
        sampleRadius = 2.0,
        hitThickness = 0.5,
        aoPower      = 1.0,
        energy       = 1.0,
        bounce       = 0.5,
        convergence  = 0.5,
        enabled      = false,
    },
    ssr = {
        maxRaySteps = 32,
        binarySteps = 4,
        stepSize    = 0.125,
        thickness   = 0.2,
        maxDistance = 4.0,
        edgeFade    = 0.25,
        enabled     = false,
    },
    bloom = {
        mode          = .DISABLED,
        levels        = 0.5,
        intensity     = 0.05,
        threshold     = 0.0,
        softThreshold = 0.5,
        filterRadius  = 1.0,
    },
    fog = {
        mode      = .DISABLED,
        color     = {255, 255, 255, 255},
        start     = 1.0,
        end       = 50.0,
        density   = 0.05,
        skyAffect = 0.5,
    },
    dof = {
        mode        = .DISABLED,
        focusPoint  = 10.0,
        focusScale  = 1.0,
        maxBlurSize = 20.0,
    },
    tonemap = {
        mode     = .LINEAR,
        exposure = 1.0,
        white    = 1.0,
    },
    color = {
        brightness = 1.0,
        contrast   = 1.0,
        saturation = 1.0,
    },
}
