const Cpu = @import("cpu.zig").Cpu;
usingnamespace @import("memory.zig");

pub const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn renderCurrentState(renderer: *c.SDL_Renderer, cpu: Cpu) !void {
    const mem_state = @bitCast(Memory, cpu.memory[0..0x2000].*);

    // Render tiles
    var tx: usize = 0;
    var ty: usize = 0;
    while(ty < TileMap.height) : ({ ty += 1; }) {
        while(tx < TileMap.width) : ({ tx += 1; }) {
            const tile_index = (try mem_state.tile_map.getTile(tx, ty)).index;
            const tile_data = mem_state.tile_data.tiles[tile_index];
            // TODO: We can forego using the `getAttribute()` helper function
            // and taking on the overhead that that entails since we already
            // have our tile's index at hand.
            // For the sake of clarity I'll just continue using the helper
            // function anyways unless I find it causes significant overhead
            const palette_index = try mem_state.tile_attribute_table.getAttribute(tx, ty);
            const palette = mem_state.color_palette_table.background_palettes[palette_index];

            var px: usize = 0;
            var py: usize = 0;
            while(py < TileMap.height) : ({ py += 1; }) {
                while(px < TileMap.width) : ({ px += 1; }) {
                    const color_index = try tile_data.getPixelValue(px, py);
                    const color = palette.colors[color_index].asSdlColor();
                    _ = c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 0xFF);
                    _ = c.SDL_RenderDrawPoint(renderer, @intCast(c_int, tx) * 8 + @intCast(c_int, px), @intCast(c_int, ty) * 8 + @intCast(c_int, py));
                }
            }
        }
    }
}
