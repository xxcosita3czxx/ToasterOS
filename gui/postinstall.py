import sys
import sdl2

def run():
    if sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO) != 0:
        print("SDL_Init Error:", sdl2.SDL_GetError().decode())
        return 1

    # Get current display mode for display 0
    display_mode = sdl2.SDL_DisplayMode()
    if sdl2.SDL_GetCurrentDisplayMode(0, display_mode) != 0:
        print("SDL_GetCurrentDisplayMode Error:", sdl2.SDL_GetError().decode())
        return 1
    width = display_mode.w
    height = display_mode.h

    window = sdl2.SDL_CreateWindow(
        b"KMSDRM Test",
        sdl2.SDL_WINDOWPOS_UNDEFINED,
        sdl2.SDL_WINDOWPOS_UNDEFINED,
        width,
        height,
        sdl2.SDL_WINDOW_FULLSCREEN
    )
    if not window:
        print("SDL_CreateWindow Error:", sdl2.SDL_GetError().decode())
        return 1

    renderer = sdl2.SDL_CreateRenderer(window, -1, 0)
    if not renderer:
        print("SDL_CreateRenderer Error:", sdl2.SDL_GetError().decode())
        return 1

    sdl2.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255)
    sdl2.SDL_RenderClear(renderer)
    sdl2.SDL_RenderPresent(renderer)

    running = True
    event = sdl2.SDL_Event()
    while running:
        while sdl2.SDL_PollEvent(event):
            if event.type == sdl2.SDL_QUIT:
                running = False

    sdl2.SDL_DestroyRenderer(renderer)
    sdl2.SDL_DestroyWindow(window)
    sdl2.SDL_Quit()
    return 0

if __name__ == "__main__":
    sys.exit(run())