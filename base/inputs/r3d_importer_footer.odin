/**
 * @typedef R3D_ImportFlags
 * @brief Flags controlling importer behavior.
 *
 * These flags define how the importer processes the source asset.
 */
ImportFlag :: enum u32 {

    /**
     * @brief Keep a CPU-side copy of mesh data.
     *
     * When enabled, raw mesh data is preserved in RAM after model import.
     */
    MESH_DATA = 0,

    /**
     * @brief Enable high-quality import processing.
     *
     * When enabled, the importer uses a higher-quality post-processing
     * (e.g. smooth normals, mesh optimization, data validation).
     * This mode is intended for editor usage and offline processing.
     *
     * When disabled, a faster import preset is used, suitable for runtime.
     */
    QUALITY = 1,

}

ImportFlags :: bit_set[ImportFlag; u32]
