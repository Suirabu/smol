const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const window_width = 200;
const window_height = 160;

pub fn main() anyerror!void {
    // Initialize SDL subsystems
    if(c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return error.SdlInitError;
    }
    defer c.SDL_Quit();

    // Create window
    const window: *c.SDL_Window = c.SDL_CreateWindow(
        "Smol Emulator",
        c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED,
        window_width, window_height,
        c.SDL_WINDOW_SHOWN
    ) orelse {
        return error.SdlWindowError;
    };
    defer c.SDL_DestroyWindow(window);

    // Create renderer
    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        return error.SdlRendererError;
    };
    defer c.SDL_DestroyRenderer(renderer);
    
    loop: while(true) {
        // Poll events
        var e: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&e) != 0) {
            switch(e.@"type") {
                c.SDL_QUIT => break :loop,
                else => {},
            }
        }

        _ = c.SDL_RenderClear(renderer);

        c.SDL_RenderPresent(renderer);

        // TODO: Adjust delay to compensate for processing time
        c.SDL_Delay(1000 / 60);
    }
}
