pub const Memory = packed struct {
    tile_map: TileMap,
    tile_attribute_table: TileAttributeTable,
    sprite_attribute_table: SpriteAttributeTable,
    color_palette_table: ColorPaletteTable,
    io_registers: IoRegisters,
    tile_data: TileData,
    sprite_data: SpriteData,
};

pub const TileMap = packed struct {
    const Self = @This();

    pub const width = 64;
    pub const height = 48;
    const num_tiles = width * height;
    
    tiles: [num_tiles]TileIndex,

    pub fn getTile(self: Self, x: usize, y: usize) !TileIndex {
        const index = y * width + x;

        if(index >= num_tiles) {
            return error.OutOfBounds;
        }
        return self.tiles[index];
    }
};

pub const TileIndex = packed struct {
    _: u1,
    index: u7,
};

pub const TileAttributeTable = packed struct {
    const Self = @This();

    attributes: [TileMap.num_tiles / 4]u8,

    pub fn getAttribute(self: Self, x: usize, y: usize) !u2 {
        const index = y * TileMap.width + x;
        const offset = index % 4;

        if(index >= TileMap.num_tiles) {
            return error.OutOfBounds;
        }
        return @truncate(u2, self.attributes[index / 4] >> (6 - @truncate(u3, offset) * 2));
    }
};

pub const SpriteAttributeTable = packed struct {
    const Self = @This();

    const num_sprites = 32;

    attributes: [num_sprites]SpriteAttributes,
};

pub const SpriteAttributes = packed struct {
    // Sprite data index
    _: u1,      // Unused  
    index: u7,
    
    // On-screen position
    x_pos: u8,
    y_pos: u8,

    // Attributes
    __: u2,      // Unused
    priority: bool,
    draw_color_zero: bool,
    flip_x: bool,
    flip_y: bool,
    palette_index: u2,
};

pub const ColorPaletteTable = packed struct {
    background_palettes: [4]ColorPalette,
    sprite_palette: [4]ColorPalette,
};

pub const ColorPalette = packed struct {
    colors: [4]Color,
};

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Color = packed struct {
    const Self = @This();

    red: u3,
    green: u3,
    blue: u2,

    pub fn asSdlColor(self: Self) c.SDL_Color {
        // FIXME: This is *not* the right way to convert 8-bit RGB to 24-bit
        // RGB as it cannot cleanly map 3 bit values to 8 bit values. This will
        // need to be fixed.
        return c.SDL_Color {
            .r = @intCast(u8, self.red) * (255 / 0b111),
            .g = @intCast(u8, self.green) * (255 / 0b111),
            .b = @intCast(u8, self.blue) * (255 / 0b11),
            .a = 0xFF,
        };
    }
};

// TODO: Define and implement IO registers
pub const IoRegisters = packed struct {
    _: u768,
};

pub const TileData = packed struct {
    const num_tiles = 128;

    tiles: [num_tiles]GraphicData,
};

pub const SpriteData = packed struct {
    const num_sprites = 128;

    tiles: [num_sprites]GraphicData,
};

pub const GraphicData = packed struct {
    const Self = @This();

    const width = 8;
    const height = 8;
    const num_pixels = width * height;

    pixels: [num_pixels / 4]u8,

    pub fn getPixelValue(self: Self, x: usize, y: usize) !u2 {
        const index = (y * width + x);
        const offset = (y * width + x) % 4;

        if(index >= num_pixels) {
            return error.OutOfBounds;
        }
        return @truncate(u2, self.pixels[index / 4] >> (6 - @truncate(u3, offset) * 2));
    }
};

const expect = @import("std").testing.expect;

test "Memory sizes" {
    try expect(@sizeOf(Memory) == 0x2000);
    try expect(@sizeOf(TileMap) == 0xC00);
    try expect(@sizeOf(TileIndex) == 0x01);
    try expect(@sizeOf(TileAttributeTable) == 0x300);
    try expect(@sizeOf(SpriteAttributeTable) == 0x80);
    try expect(@sizeOf(SpriteAttributes) == 0x04);
    try expect(@sizeOf(ColorPaletteTable) == 0x20);
    try expect(@sizeOf(ColorPalette) == 0x04);
    try expect(@sizeOf(Color) == 0x01);
    try expect(@sizeOf(IoRegisters) == 0x60);
    try expect(@sizeOf(TileData) == 0x800);
    try expect(@sizeOf(SpriteData) == 0x800);
    try expect(@sizeOf(GraphicData) == 0x10);
}
