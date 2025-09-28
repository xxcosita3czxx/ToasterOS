import sdl2
import sdl2.ext
import sys
import os


def resource_path(rel_path):
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, rel_path)
    return os.path.join(os.path.abspath("."), rel_path)

# Dummy WiFi networks for demonstration
wifi_networks = ["HomeWiFi", "OfficeNet", "CafeFree", "Guest123"]

def draw_text(renderer, font_manager, text, x, y, color=(255,255,255)):
    surface = font_manager.render(text, size=24, color=color)
    texture = sdl2.ext.Texture(renderer, surface)
    renderer.copy(texture, dstrect=(x, y, surface.w, surface.h))

def draw_keyboard(renderer, font_manager, keys, x, y, key_w, key_h, pressed_idx=None):
    for row_idx, row in enumerate(keys):
        for col_idx, key in enumerate(row):
            key_x = x + col_idx * (key_w + 5)
            key_y = y + row_idx * (key_h + 5)
            color = (100, 100, 200) if pressed_idx == (row_idx, col_idx) else (50, 50, 100)
            # Use renderer.fill with correct parameter order: rect, color
            renderer.fill((key_x, key_y, key_w, key_h), color)
            draw_text(renderer, font_manager, key, key_x + 10, key_y + 10, color=(255,255,255))

def get_key_at_pos(keys, x, y, key_x, key_y, key_w, key_h):
    for row_idx, row in enumerate(keys):
        for col_idx, key in enumerate(row):
            bx = key_x + col_idx * (key_w + 5)
            by = key_y + row_idx * (key_h + 5)
            if bx <= x <= bx + key_w and by <= y <= by + key_h:
                return (row_idx, col_idx)
    return None

def main():
    sdl2.ext.init()
    # Create a borderless fullscreen window
    display_index = 0
    display_mode = sdl2.SDL_DisplayMode()
    sdl2.SDL_GetCurrentDisplayMode(display_index, display_mode)
    window = sdl2.ext.Window(
        "Installer - WiFi Setup",
        size=(display_mode.w, display_mode.h),
        flags=sdl2.SDL_WINDOW_BORDERLESS | sdl2.SDL_WINDOW_FULLSCREEN
    )
    window.show()
    renderer = sdl2.ext.Renderer(window)
    font_manager = sdl2.ext.FontManager(resource_path("m6x11pluscs.ttf"), size=24)
    running = True
    selected_index = 0
    entering_password = False
    password = ""
    ssid = None
    keyboard_keys = [
        ['1','2','3','4','5','6','7','8','9','0'],
        ['q','w','e','r','t','y','u','i','o','p',"/"],
        ['a','s','d','f','g','h','j','k','l',".",","],
        ['z','x','c','v','b','n','m','<','OK']
    ]
    
    # Calculate keyboard dimensions and position
    screen_width = display_mode.w
    screen_height = display_mode.h
    key_w, key_h = 60, 50
    keyboard_width = 10 * (key_w + 5) - 5  # 10 keys per row with 5px spacing
    keyboard_height = 4 * (key_h + 5) - 5  # 4 rows with 5px spacing
    
    # Position keyboard at bottom, centered, max 1/2 screen height
    max_keyboard_height = screen_height // 2
    if keyboard_height > max_keyboard_height:
        key_h = (max_keyboard_height - 15) // 4  # Adjust key height if needed
        keyboard_height = 4 * (key_h + 5) - 5
    
    key_x = (screen_width - keyboard_width) // 2  # Center horizontally
    key_y = screen_height - keyboard_height - 20  # 20px margin from bottom

    while running:
        renderer.clear((0, 0, 40))
        draw_text(renderer, font_manager, "Select WiFi Network:", 20, 20)
        # Draw WiFi list
        for i, net in enumerate(wifi_networks):
            color = (255,255,0) if i == selected_index else (255,255,255)
            draw_text(renderer, font_manager, net, 40, 60 + i*40, color=color)
        if entering_password:
            # Position password input above keyboard
            password_y = key_y - 80
            draw_text(renderer, font_manager, f"Enter password for {ssid}:", 20, password_y - 30)
            masked = "*"*len(password) if password else "_"
            draw_text(renderer, font_manager, masked, 40, password_y)
            draw_keyboard(renderer, font_manager, keyboard_keys, key_x, key_y, key_w, key_h)
        renderer.present()

        events = sdl2.ext.get_events()
        for event in events:
            if event.type == sdl2.SDL_QUIT:
                running = False
            elif event.type == sdl2.SDL_MOUSEBUTTONDOWN:
                mx, my = event.button.x, event.button.y
                if not entering_password:
                    # Select network by tapping
                    for i in range(len(wifi_networks)):
                        if 60 + i*40 <= my <= 100 + i*40:
                            selected_index = i
                            ssid = wifi_networks[i]
                            entering_password = True
                            password = ""
                else:
                    key_idx = get_key_at_pos(keyboard_keys, mx, my, key_x, key_y, key_w, key_h)
                    if key_idx:
                        row, col = key_idx
                        key = keyboard_keys[row][col]
                        if key == '<':
                            password = password[:-1]
                        elif key == 'OK':
                            print(f"Selected SSID: {ssid}, Password: {password}")
                            running = False
                        else:
                            password += key
            elif event.type == sdl2.SDL_KEYDOWN:
                if entering_password:
                    if event.key.keysym.sym == sdl2.SDLK_RETURN:
                        print(f"Selected SSID: {ssid}, Password: {password}")
                        running = False
                    elif event.key.keysym.sym == sdl2.SDLK_BACKSPACE:
                        password = password[:-1]
                    elif event.key.keysym.sym >= 32 and event.key.keysym.sym <= 126:
                        # Only handle printable ASCII characters
                        ch = chr(event.key.keysym.sym)
                        if ch.isprintable():
                            password += ch

    sdl2.ext.quit()

if __name__ == "__main__":
    main()

