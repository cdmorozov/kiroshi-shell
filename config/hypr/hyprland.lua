-- NETRUNNER.OS — Hyprland 0.57+ (Lua config)
-- navy surfaces, thin teal lines, Arasaka red only for alerts

local terminal    = "kitty"
local fileManager = "nautilus"
local launcher    = "qs -p ~/.config/quickshell ipc call launcher toggle"
local mainMod     = "SUPER"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))  -- user tools (yazi, ya, rice-*)
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- autostart
local logdir = os.getenv("HOME") .. "/.cache/hypr-start"
local function start(name, cmd)
    hl.exec_cmd("mkdir -p " .. logdir .. " && " .. cmd .. " > " .. logdir .. "/" .. name .. ".log 2>&1")
end

hl.on("hyprland.start", function()
    start("session", "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target")
    start("polkit",  "systemctl --user start hyprpolkitagent")
    start("paper",   "hyprpaper")
    --@spotify@ start("spotify", "flatpak run com.spotify.Client")   -- warm start: hidden on special:music
    start("wallsync", "wallpaper-sync")   -- follows GNOME Settings > Background
    start("clip",    "wl-paste --watch cliphist store")
    start("hud",     "qs -p ~/.config/quickshell")
    -- hypridle (auto-lock) stays off until hyprlock has been tested once with Super+L:
    start("idle", "hypridle")
end)

-- release graphical-session.target on exit so a later GNOME login starts clean
hl.on("hyprland.shutdown", function()
    pcall(os.execute, "systemctl --user stop hyprland-session.target")
end)

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 14,
        border_size = 2,
        col = {
            -- teal edge fading into navy, like the HUD frames in the reference
            active_border   = { colors = { "rgba(4fa3aeff)", "rgba(16233aff)", "rgba(4fa3aeff)" }, angle = 45 },
            inactive_border = "rgba(16233acc)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding         = 3,          -- sharp, HUD-like corners
        active_opacity   = 1.0,
        inactive_opacity = 0.92,
        shadow = {
            enabled      = true,
            range        = 18,
            render_power = 3,
            color        = "rgba(000000aa)",
        },
        glow = {                       -- faint neon halo around the focused window
            enabled        = true,
            range          = 10,
            render_power   = 3,
            color          = "rgba(4fa3ae40)",
            color_inactive = "rgba(00000000)",
        },
        blur = {
            enabled = true,
            size    = 6,
            passes  = 3,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        focus_on_activate       = true,
    },
    input = {
        kb_layout    = "us,ru,ua",
        kb_options   = "grp:win_space_toggle",   -- Super+Space switches layout, same as GNOME
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
            disable_while_typing = true,
        },
    },
})

-- snappy, slightly glitchy-feeling motion
hl.curve("snap",         { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},   {0.32, 1}   } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},      {1, 1}      } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5},  {0.75, 1}   } })
hl.animation({ leaf = "global",        enabled = true, speed = 10,  bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4,   bezier = "snap" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.5, bezier = "snap",         style = "popin 85%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.6, bezier = "linear",       style = "popin 85%" })
hl.animation({ leaf = "border",        enabled = true, speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "almostLinear" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "slidefade 15%" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- blur behind the bar, launcher and notifications
hl.layer_rule({ name = "blur-netrun-power", match = { namespace = "netrun-power" }, blur = true })
hl.layer_rule({ name = "blur-netrun-switcher", match = { namespace = "netrun-switcher" }, blur = true })
hl.layer_rule({ name = "blur-netrun-osd", match = { namespace = "netrun-osd" }, blur = true })
hl.layer_rule({ name = "blur-netrun-history", match = { namespace = "netrun-history" }, blur = true })
hl.layer_rule({ name = "blur-netrun-radio", match = { namespace = "netrun-radio" }, blur = true })
hl.layer_rule({ name = "blur-netrun-launcher", match = { namespace = "netrun-launcher" }, blur = true })
hl.layer_rule({ name = "blur-netrun-bar", match = { namespace = "netrun-bar" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" },      blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-rofi",   match = { namespace = "rofi" },        blur = true, ignore_alpha = 0.2, dim_around = true })
hl.layer_rule({ name = "blur-swaync", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-logout", match = { namespace = "logout_dialog" }, blur = true })

hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ name = "firefox-glass", match = { class = "^(org.mozilla.firefox|firefox)$" }, opacity = "0.78 0.70", no_blur = true })
--@spotify@ hl.window_rule({ name = "spotify-hidden", match = { class = "^([Ss]potify|com.spotify.Client)$" }, workspace = "special:music silent" })
hl.window_rule({ name = "spotify-glass", match = { class = "^([Ss]potify|com.spotify.Client)$" }, opacity = "0.84 0.76", no_blur = true })
hl.window_rule({ name = "vscode-glass", match = { class = "^(code|Code|code-oss)$" }, opacity = "0.80 0.72", no_blur = true })
hl.window_rule({ name = "float-pavucontrol", match = { class = "org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ name = "float-nm-editor",   match = { class = "nm-connection-editor" },       float = true })

-- keys -----------------------------------------------------------------
hl.bind(mainMod .. " + Return",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T",           hl.dsp.exec_cmd(terminal))      -- one-handed terminal
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + R",           hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + Tab",         hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call switcher toggle"))
hl.bind(mainMod .. " + W",           hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call panels net"))   -- Wi-Fi panel
hl.bind(mainMod .. " + B",           hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call panels bt"))    -- Bluetooth panel
hl.bind(mainMod .. " + M",           hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call radio toggle"))  -- RADIOPORT player
hl.bind(mainMod .. " + A",           hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call sound toggle"))   -- audio mixer
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd("kitty --class yazi -e " .. os.getenv("HOME") .. "/.local/bin/yazi"))  -- Yazi
hl.bind(mainMod .. " + ALT + E",     hl.dsp.exec_cmd(fileManager))      -- Nautilus
hl.bind(mainMod .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L",           hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exit())                         -- emergency: back to login screen
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call power toggle"))
hl.bind(mainMod .. " + I",           hl.dsp.exec_cmd("env XDG_CURRENT_DESKTOP=GNOME gnome-control-center"))   -- system settings
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call notifs history"))   -- message log
hl.bind(mainMod .. " + SHIFT + N",   hl.dsp.exec_cmd("qs -p ~/.config/quickshell ipc call notifs clear"))     -- dismiss toasts
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p '> CLIP' | cliphist decode | wl-copy"))
hl.bind("Print",                     hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("SHIFT + Print",             hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",          hl.dsp.workspace.toggle_special("magic"))
--@spotify@ hl.bind(mainMod .. " + SHIFT + M",  hl.dsp.exec_cmd("spotify-toggle"))   -- show / hide Spotify (kept running in the background)
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && qs -p ~/.config/quickshell ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && qs -p ~/.config/quickshell ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
