/**
 * @brief Bitfield type used to specify rendering layers for 3D objects.
 *
 * This type is used by `R3D_Mesh` and `R3D_Sprite` objects to indicate
 * which rendering layer(s) they belong to. Active layers are controlled
 * globally via the functions:
 * 
 * - void R3D_EnableLayers(R3D_Layer bitfield);
 * - void R3D_DisableLayers(R3D_Layer bitfield);
 *
 * A mesh or sprite will be rendered if at least one of its assigned layers is active.
 *
 * For simplicity, 16 layers are defined in this header, but the maximum number
 * of layers is 32 for an uint32_t.
 */
Layer :: enum u32 {
    LAYER_01 = 1 << 0,
    LAYER_02 = 1 << 1,
    LAYER_03 = 1 << 2,
    LAYER_04 = 1 << 3,
    LAYER_05 = 1 << 4,
    LAYER_06 = 1 << 5,
    LAYER_07 = 1 << 6,
    LAYER_08 = 1 << 7,
    LAYER_09 = 1 << 8,
    LAYER_10 = 1 << 9,
    LAYER_11 = 1 << 10,
    LAYER_12 = 1 << 11,
    LAYER_13 = 1 << 12,
    LAYER_14 = 1 << 13,
    LAYER_15 = 1 << 14,
    LAYER_16 = 1 << 15,
    LAYER_ALL = 0xFFFFFFFF,
}
