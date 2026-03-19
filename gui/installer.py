import sdl2
import sdl2.ext
import sys
import os
import subprocess
from animations import AnimationManager
test_mode = False

def resource_path(rel_path):
    # PyInstaller creates a temp folder and stores path in _MEIPASS
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, rel_path)
    return os.path.join(os.path.abspath("."), rel_path)

if not test_mode:
    os.system("rc-service networking stop")
    os.system("rc-service wpa_supplicant stop")
    os.system("rc-service NetworkManager restart")

wifi_networks = os.popen("nmcli -t -f SSID dev wifi | grep -v '^$'").read().splitlines()

if test_mode:
    wifi_networks = ["HomeWiFi", "OfficeWiFi", "CafeWiFi"]


wifi_networks.append("Use Ethernet")

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

def draw_button(renderer, font_manager, text, x, y, w, h, color=(80,80,80), text_color=(255,255,255)):
    renderer.fill((x, y, w, h), color)
    tw_surface = font_manager.render(text, size=24, color=text_color)
    tw = tw_surface.w
    th = tw_surface.h
    renderer.copy(sdl2.ext.Texture(renderer, tw_surface), dstrect=(x + (w-tw)//2, y + (h-th)//2, tw, th))

def get_key_at_pos(keys, x, y, key_x, key_y, key_w, key_h):
    for row_idx, row in enumerate(keys):
        for col_idx, key in enumerate(row):
            bx = key_x + col_idx * (key_w + 5)
            by = key_y + row_idx * (key_h + 5)
            if bx <= x <= bx + key_w and by <= y <= by + key_h:
                return (row_idx, col_idx)
    return None

def connect_wifi(ssid, password):
    # Use nmcli to connect to the WiFi network
    try:
        # Remove previous connection if exists
        if not test_mode:
            subprocess.run(["nmcli", "connection", "delete", ssid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass
    try:
        # Try to connect
        result = subprocess.run(
            ["nmcli", "dev", "wifi", "connect", ssid, "password", password],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
    except Exception as e:
        if not test_mode:
            return False, str(e)
        else:
            result.returncode = 0  # Simulate success in test mode
    if result.returncode == 0:
        return True, "Connected successfully!"
    elif test_mode:
        return True, "Test mode: Simulated connection success."
    else:
        return False, result.stderr.strip() or "Failed to connect."

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
    animation_manager = AnimationManager(renderer, resource_path("Anims/"), window)
    font_manager = sdl2.ext.FontManager(resource_path("m6x11pluscs.ttf"), size=24)
    running = True
    animation_manager.load_animations()
    animation_manager.run_animation("load")
    selected_index = 0
    entering_password = False
    password = ""
    ssid = None
    show_networks = True  # Track if we are showing the network list
    connection_status = None  # None, "connecting", "success", or error message
    keyboard_keys = [
        ['1','2','3','4','5','6','7','8','9','0'],
        ['q','w','e','r','t','y','u','i','o','p',"/"],
        ['a','s','d','f','g','h','j','k','l',".",","],
        ['z','x','c','v','b','n','m','<','>','$','!','?','OK']
    ]
    
    # Calculate keyboard dimensions and position
    screen_width = display_mode.w
    screen_height = display_mode.h
    key_w, key_h = 60, 50
    # Update keyboard_width to match new number of keys in the longest row
    max_keys_per_row = max(len(row) for row in keyboard_keys)
    keyboard_width = max_keys_per_row * (key_w + 5) - 5
    keyboard_height = len(keyboard_keys) * (key_h + 5) - 5
    
    # Position keyboard at bottom, centered, max 1/2 screen height
    max_keyboard_height = screen_height // 2
    if keyboard_height > max_keyboard_height:
        key_h = (max_keyboard_height - 15) // 4  # Adjust key height if needed
        keyboard_height = 4 * (key_h + 5) - 5
    
    key_x = (screen_width - keyboard_width) // 2  # Center horizontally
    key_y = screen_height - keyboard_height - 20  # 20px margin from bottom

    while running:
        renderer.clear((0, 0, 40))
        if show_networks:
            draw_text(renderer, font_manager, "Select WiFi Network:", 20, 20)
            # Draw WiFi list
            for i, net in enumerate(wifi_networks):
                color = (255,255,0) if i == selected_index else (255,255,255)
                draw_text(renderer, font_manager, net, 40, 60 + i*40, color=color)
        else:
            # Only show selected network, password input, and Back button
            password_y = key_y - 80
            draw_text(renderer, font_manager, f"Enter password for {ssid}:", 20, password_y - 30)
            masked = "*"*len(password) if password else "_"
            draw_text(renderer, font_manager, masked, 40, password_y)
            draw_keyboard(renderer, font_manager, keyboard_keys, key_x, key_y, key_w, key_h)
            # Draw Back button at top left
            back_btn_x, back_btn_y, back_btn_w, back_btn_h = 20, 20, 120, 40
            draw_button(renderer, font_manager, "Back", back_btn_x, back_btn_y, back_btn_w, back_btn_h, color=(120,40,40))
            # Show connection status if present
            if connection_status:
                draw_text(renderer, font_manager, connection_status, 40, key_y - 130, color=(255,0,0) if "fail" in connection_status.lower() else (0,255,0))

        renderer.present()

        events = sdl2.ext.get_events()
        for event in events:
            if event.type == sdl2.SDL_QUIT:
                running = False
            elif event.type == sdl2.SDL_MOUSEBUTTONDOWN:
                mx, my = event.button.x, event.button.y
                if show_networks:
                    # Select network by tapping
                    for i in range(len(wifi_networks)):
                        if 60 + i*40 <= my <= 100 + i*40:
                            selected_index = i
                            ssid = wifi_networks[i]
                            if ssid == "Use Ethernet":
                                print("Ethernet selected. No WiFi password required.")
                                running = False
                            else:
                                show_networks = False
                                entering_password = True
                                password = ""
                else:
                    # Check Back button
                    back_btn_x, back_btn_y, back_btn_w, back_btn_h = 20, 20, 120, 40
                    if back_btn_x <= mx <= back_btn_x + back_btn_w and back_btn_y <= my <= back_btn_y + back_btn_h:
                        show_networks = True
                        entering_password = False
                        password = ""
                        ssid = None
                        connection_status = None
                        continue
                    key_idx = get_key_at_pos(keyboard_keys, mx, my, key_x, key_y, key_w, key_h)
                    if key_idx:
                        row, col = key_idx
                        key = keyboard_keys[row][col]
                        if key == '<':
                            password = password[:-1]
                        elif key == 'OK':
                            if not password:
                                connection_status = "Password required."
                                continue
                            connection_status = "Connecting..."
                            renderer.present()
                            sdl2.SDL_Delay(100)  # Small delay to show "Connecting..."
                            success, msg = connect_wifi(ssid, password)
                            if success:
                                connection_status = "Connected successfully!"
                                renderer.present()
                                sdl2.SDL_Delay(1000)
                                running = False
                            else:
                                connection_status = f"Failed: {msg}"
                        else:
                            password += key
            elif event.type == sdl2.SDL_FINGERDOWN:
                mx = int(event.tfinger.x * screen_width)
                my = int(event.tfinger.y * screen_height)
                if show_networks:
                    for i in range(len(wifi_networks)):
                        if 60 + i*40 <= my <= 100 + i*40:
                            selected_index = i
                            ssid = wifi_networks[i]
                            if ssid == "Use Ethernet":
                                print("Ethernet selected. No WiFi password required.")
                                running = False
                            else:
                                show_networks = False
                                entering_password = True
                                password = ""
                else:
                    back_btn_x, back_btn_y, back_btn_w, back_btn_h = 20, 20, 120, 40
                    if back_btn_x <= mx <= back_btn_x + back_btn_w and back_btn_y <= my <= back_btn_y + back_btn_h:
                        show_networks = True
                        entering_password = False
                        password = ""
                        ssid = None
                        connection_status = None
                        continue
                    key_idx = get_key_at_pos(keyboard_keys, mx, my, key_x, key_y, key_w, key_h)
                    if key_idx:
                        row, col = key_idx
                        key = keyboard_keys[row][col]
                        if key == '<':
                            password = password[:-1]
                        elif key == 'OK':
                            if not password:
                                connection_status = "Password required."
                                continue
                            connection_status = "Connecting..."
                            renderer.present()
                            sdl2.SDL_Delay(100)
                            success, msg = connect_wifi(ssid, password)
                            if success:
                                connection_status = "Connected successfully!"
                                renderer.present()
                                sdl2.SDL_Delay(1000)
                                running = False
                            else:
                                connection_status = f"Failed: {msg}"
                        else:
                            password += key
            elif event.type == sdl2.SDL_KEYDOWN:
                if entering_password and not show_networks:
                    if event.key.keysym.sym == sdl2.SDLK_RETURN:
                        if not password:
                            connection_status = "Password required."
                            continue
                        connection_status = "Connecting..."
                        renderer.present()
                        sdl2.SDL_Delay(100)
                        success, msg = connect_wifi(ssid, password)
                        if success:
                            connection_status = "Connected successfully!"
                            renderer.present()
                            sdl2.SDL_Delay(1000)
                            running = False
                        else:
                            connection_status = f"Failed: {msg}"
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

