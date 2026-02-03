/**
 * @brief Bit-flags controlling what components are generated.
 *
 * - R3D_PROBE_ILLUMINATION -> generate diffuse irradiance
 * - R3D_PROBE_REFLECTION   -> generate specular prefiltered map
 */
ProbeFlag :: enum u32 {
    ILLUMINATION = 0,
    REFLECTION   = 1,
}

ProbeFlags :: bit_set[ProbeFlag; u32]
