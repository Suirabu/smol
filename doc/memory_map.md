# Memory Map

v0.1.0

The information described in this document is not final as may be subject to change in the future.

## Memory Map

### Random Access Memory (0000-2FFF)

| Start | End | Name |
|-------|-----|------|
| 0000 | 0BFF | Tile Map |
| 0C00 | 0EFF | Tile Attribute Table |
| 0F00 | 0F7F | Sprite Attribute Table |
| 0F80 | 0F9F | Color Palette Data |
| 0FA0 | 0FFF | I/O Registers |
| 1000 | 17FF | Tile Data |
| 1800 | 1FFF | Sprite Data |
| 2000 | 2FFF | Work RAM |

### Read-Only Memory (3000-9FFF)

| Start | End | Name |
|-------|-----|------|
| 3000 | 9FFF | Program Data |


## Specifics

### Tile Map (0000-0BFF)

64 by 48 tile map. One byte per tile containing a 7-bit offset to tile data in the "Tile data" section (1000-1FFF).


### Tile Attribute Table (0C00-0EFF)

Holds color data for all tiles, two bits per tile.
This index refers to a color palette in the lower half of the color palette data section.

palette = 0x0F80 + index * 4;


## Sprite Attribute Table

Holds attributes for 32 sprites.

### Sprite attribute structure

- Byte 3: Sprite index
- Byte 2: X position
- Byte 1: Y position
- Byte 0: Sprite attributes
    - Bits 7-6: Unused
    - Bit 5: Priority
        Draw this sprite after drawing all other sprites *without* the priority bit set.
    - Bit 4: Draw color 0
        If this bit is set, pixels using the 0th color in the sprite's palette will be drawn normally,
        otherwise they will not be drawn.
    - Bit 3: Flip X
    - Bit 2: Flip Y
    - Bits 1-0: Color palette index
        This index refers to a color palette in the upper half of the color palette data section.

        palette = 0x0F90 + index * 4;

## Color Palette Data

Color palettes consist of 4 colors. Colors are defined using 8-bit RGB color encoding (RRRGGGBB).
8 palettes can be fit inside the palette data section.
The first 4 are used exclusively for tiles, wheras the remaining 4 are used exclusively for sprites.

### I/O Registers

**/!\ WIP**
TODO: Audio I/O. Think about serial communication?

| Offset | Size | Description |
|--------|------|-------------|
| +0     | 1    | Input bitmask |


## Tile Data

16 bytes per tile. Tiles are described pixel-by-pixel from left to right, top to bottom.
Each pixel is described as a 2-bit index to a color in a color palette.


## Sprite Data

16 bytes per sprite. Sprites are described pixel-by-pixel from left to right, top to bottom.
Each pixel is described as a 2-bit index to a color in a color palette.


## Work RAM

This memory is free to be utilized by programs running on the system.

