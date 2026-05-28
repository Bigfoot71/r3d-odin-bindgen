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
        intensity   = 1.0,
        power       = 1.0,
        maxRadius   = 0.2,
        radius      = 1.0,
        bias        = 0.03,
        enabled     = false,
    },
    ssil = {
        sampleCount = 16,
        giIntensity = 1.0,
        aoIntensity = 1.0,
        aoPower     = 1.0,
        maxRadius   = 0.2,
        radius      = 4.0,
        bias        = 0.03,
        enabled     = false,
    },
    ssgi = {
        sliceCount = 4,
        edgeFade = 0.1,
        distanceFalloff = 1.0,
        normalRejection = 0.0,
        intensity = 1.0,
        denoiseSteps = 4,
        enabled = false,
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
        nearScale   = 1.0,
        maxBlurSize = 20.0,
    },
    bloom = {
        mode          = .DISABLED,
        levels        = 0.5,
        intensity     = 0.05,
        threshold     = 0.0,
        softThreshold = 0.5,
        filterRadius  = 1.0,
    },
    autoExposure = {
        minEV                = -1.0,
        maxEV                = 1.0,
        exposureCompensation = 0.0,
        adaptationToBright   = 0.5,
        adaptationToDark     = 1.0,
        enabled = false,
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
