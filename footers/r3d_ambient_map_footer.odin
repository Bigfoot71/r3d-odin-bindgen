/**
 * @brief Bit-flags controlling what components are generated.
 *
 * - R3D_AMBIENT_ILLUMINATION -> generate diffuse irradiance
 * - R3D_AMBIENT_REFLECTION   -> generate specular prefiltered map
 */
AmbientFlag :: enum u32 {
    ILLUMINATION = 0,
    REFLECTION   = 1,
}

AmbientFlags :: bit_set[AmbientFlag; u32]
