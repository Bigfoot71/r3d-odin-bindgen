/**
 * @brief Bitmask defining which instance attributes are present.
 */
InstanceFlag :: enum u32 {
    POSITION = 0,
    ROTATION = 1,
    SCALE = 2,
    COLOR = 3,
    CUSTOM = 4,
}

InstanceFlags :: bit_set[InstanceFlag; u32]
