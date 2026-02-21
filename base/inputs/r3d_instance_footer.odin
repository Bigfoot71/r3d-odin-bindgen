/**
 * @brief Bitmask defining which instance attributes are present.
 */
InstanceFlag :: enum u32 {
    POSITION = 0,   ///< Vector3
    ROTATION = 1,   ///< Quaternion
    SCALE    = 2,   ///< Vector3
    COLOR    = 3,   ///< Color
    CUSTOM   = 4,   ///< Vector4
}

InstanceFlags :: bit_set[InstanceFlag; u32]
