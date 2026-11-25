#!/usr/bin/env bash
# NETRUNNER.OS rice installer for Fedora 44 (tested), Debian/Kali and Arch (experimental).
# Safe by default: backs up whatever it replaces, asks before using sudo, can do a dry run.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
FONTS="$HOME/.local/share/fonts"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.netrunner-backup-$STAMP"

PACKAGES=1 FONTS_DL=1 TOOLS=1 FIREFOX=0 VSCODE=0 SPOTIFY=0 DRY=0 YES=0
usage() { cat <<USAGE
Usage: ./install.sh [options]
  --no-packages   do not touch dnf (you installed the dependencies yourself)
  --no-fonts      skip downloading Rajdhani / Tektur / JetBrainsMono Nerd Font
  --no-tools      skip downloading starship and yazi
  --firefox       also install the Firefox theme and start page
  --vscode        also install the Night City HUD VS Code theme
  --spotify       also theme Flatpak Spotify (Spicetify) and keep it warm in the background
  --all           firefox + vscode + spotify
  --dry-run       print what would happen, change nothing
  -y, --yes       do not ask for confirmation
USAGE
}
for a in "$@"; do case "$a" in
    --no-packages) PACKAGES=0 ;; --no-fonts) FONTS_DL=0 ;; --no-tools) TOOLS=0 ;;
    --firefox) FIREFOX=1 ;; --vscode) VSCODE=1 ;; --spotify) SPOTIFY=1 ;;
    --all) FIREFOX=1 VSCODE=1 SPOTIFY=1 ;; --dry-run) DRY=1 ;; -y|--yes) YES=1 ;;
    -h|--help) usage; exit 0 ;; *) echo "unknown option: $a"; usage; exit 1 ;;
esac; done

c() { printf '\033[38;2;79;163;174m%s\033[0m\n' "$*"; }
w() { printf '\033[38;2;255;166;43m%s\033[0m\n' "$*"; }
run() { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

[ "$(id -u)" = 0 ] && { echo "Do not run this as root; it asks for sudo only where needed."; exit 1; }
# the configs live next to this script; a lone install.sh (curl | bash, single-file download) has nothing to copy
for d in hypr quickshell kitty fish fastfetch; do
    [ -d "$SRC/config/$d" ] || { echo "config/$d not found next to install.sh ($SRC)."; echo "Clone the whole repo and run it from there:"
        echo "  git clone https://github.com/cdmorozov/kiroshi-shell && cd kiroshi-shell && ./install.sh"; exit 1; }
done
# distro family: fedora (tested), debian (Debian/Kali/Ubuntu, experimental), arch (Arch/CachyOS/EndeavourOS, experimental)
detect_distro() {
    local id like
    id="$(. /etc/os-release 2>/dev/null; echo "${ID:-}")"; like="$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-}")"
    case " $id $like " in
        *" fedora "*|*" rhel "*) echo fedora ;;
        *" debian "*|*" ubuntu "*|*" kali "*) echo debian ;;
        *" arch "*) echo arch ;;
        *) echo unknown ;;
    esac
}
DISTRO="${NETRUNNER_DISTRO:-$(detect_distro)}"
case "$DISTRO" in
    fedora) ;;
    debian|arch) w "$DISTRO family: support is experimental, Fedora is the tested one. Missing packages are skipped with a warning." ;;
    *) w "Unknown distro: packages are skipped. Install the dependencies listed in README yourself; configs still install."; PACKAGES=0 ;;
esac

c "NETRUNNER.OS installer"
echo "  configs  -> $CFG   (existing ones are copied to $BACKUP first)"
echo "  scripts  -> $BIN"
[ "$PACKAGES" = 1 ] && echo "  packages -> $DISTRO package manager (sudo)"
if [ "$YES" = 0 ] && [ "$DRY" = 0 ]; then read -rp "Continue? [y/N] " ans; [[ "$ans" =~ ^[Yy]$ ]] || exit 0; fi

# ---------------------------------------------------------------- packages
install_each() {  # install_each <installer cmd...> -- <packages...>; one by one so a missing package does not abort the rest
    local cmd=() pkgs=() missing=() seen=0 a
    for a in "$@"; do if [ "$a" = "--" ]; then seen=1; elif [ "$seen" = 1 ]; then pkgs+=("$a"); else cmd+=("$a"); fi; done
    for a in "${pkgs[@]}"; do run "${cmd[@]}" "$a" || missing+=("$a"); done
    [ "${#missing[@]}" -gt 0 ] && w "  not available from your repos, install by hand if you need them: ${missing[*]}"
    return 0
}
if [ "$PACKAGES" = 1 ]; then
    c "[1/6] packages ($DISTRO)"
    case "$DISTRO" in
    fedora)
        fv="$(. /etc/os-release; echo "${VERSION_ID:-0}")"
        run sudo dnf -y install dnf-plugins-core || true
        # sdegler/hyprland (Hyprland 0.55+, Lua config) only builds for Fedora 44 and newer
        if [ "$fv" = rawhide ] || [ "$fv" -ge 44 ] 2>/dev/null; then
            run sudo dnf -y copr enable sdegler/hyprland || w "  could not enable COPR sdegler/hyprland, Hyprland packages will be missing"
        else
            w "  Fedora $fv: no Hyprland 0.55+ build exists for it (the config needs one). Everything else installs;"
            w "  for the desktop itself upgrade to Fedora 44: https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/"
            run sudo dnf -y copr enable errornointernet/quickshell || w "  could not enable COPR errornointernet/quickshell"
        fi
        FPK=(hyprland hyprlock hypridle hyprpaper hyprpolkitagent hyprshot
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk quickshell
            kitty fish eza bat zoxide fzf fd-find ripgrep fastfetch jq mpv cava rofi
            grim slurp wl-clipboard cliphist brightnessctl playerctl libnotify
            pavucontrol nm-connection-editor blueman nautilus gnome-control-center
            pipewire-utils wireplumber papirus-icon-theme p7zip p7zip-plugins ffmpegthumbnailer poppler-utils nwg-look unzip curl)
        # one transaction, skipping what this release lacks; if that still fails, go package by package
        run sudo dnf -y install --skip-unavailable "${FPK[@]}" || install_each sudo dnf -y install -- "${FPK[@]}" ;;
    debian)
        # Needs Hyprland 0.55+ (Lua config): Debian testing/unstable (Kali rolling follows testing) or trixie-backports.
        run sudo apt-get update || w "  apt-get update failed, trying with the current package lists"
        install_each sudo apt-get install -y -- hyprland hyprlock hypridle hyprpaper hyprpolkitagent hyprshot \
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk quickshell \
            kitty fish eza bat zoxide fzf fd-find ripgrep fastfetch jq mpv cava rofi \
            grim slurp wl-clipboard cliphist brightnessctl playerctl libnotify-bin \
            pavucontrol nm-connection-editor blueman nautilus gnome-control-center \
            pipewire-bin wireplumber papirus-icon-theme 7zip ffmpegthumbnailer poppler-utils nwg-look unzip curl \
            fonts-noto-cjk fonts-jetbrains-mono qml6-module-qtquick qml6-module-qtquick-shapes qml6-module-qtquick-window \
            qml6-module-qtquick-templates qml6-module-qtquick-layouts qml6-module-qtqml-workerscript
        v="$(dpkg-query -W -f='${Version}' hyprland 2>/dev/null || true)"
        [ -n "$v" ] && echo "  Hyprland $v installed (needs 0.55 or newer for the Lua config)"
        # Debian ships these under other names; hyprshot is a single script that Debian does not package
        if [ "$DRY" = 0 ] && ! command -v hyprshot >/dev/null; then mkdir -p "$BIN"
            curl -fsSL -o "$BIN/hyprshot" https://raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot && chmod +x "$BIN/hyprshot" || w "  hyprshot download failed (screenshot key will not work)"
        fi
        if [ "$DRY" = 0 ]; then mkdir -p "$BIN"
            command -v fdfind >/dev/null && [ ! -e "$BIN/fd" ] && ln -s "$(command -v fdfind)" "$BIN/fd"
            command -v batcat >/dev/null && [ ! -e "$BIN/bat" ] && ln -s "$(command -v batcat)" "$BIN/bat"
        fi ;;
    arch)
        install_each sudo pacman -S --needed --noconfirm -- hyprland hyprlock hypridle hyprpaper hyprpolkitagent hyprshot \
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk quickshell \
            kitty fish eza bat zoxide fzf fd ripgrep fastfetch jq mpv cava rofi \
            grim slurp wl-clipboard cliphist brightnessctl playerctl libnotify \
            pavucontrol nm-connection-editor blueman nautilus gnome-control-center \
            pipewire wireplumber papirus-icon-theme p7zip ffmpegthumbnailer poppler nwg-look unzip curl noto-fonts-cjk ;;
    esac
else c "[1/6] packages: skipped"; fi

# ---------------------------------------------------------------- fonts
if [ "$FONTS_DL" = 1 ]; then
    c "[2/6] fonts (Rajdhani, Tektur, JetBrainsMono Nerd Font)"
    run mkdir -p "$FONTS/Rajdhani" "$FONTS/Tektur" "$FONTS/JetBrainsMonoNF"
    G=https://raw.githubusercontent.com/google/fonts/main/ofl
    for f in Bold Medium SemiBold Regular Light; do run curl -fsSL -o "$FONTS/Rajdhani/Rajdhani-$f.ttf" "$G/rajdhani/Rajdhani-$f.ttf" || w "  Rajdhani-$f failed"; done
    run curl -fsSL -o "$FONTS/Tektur/Tektur[wdth,wght].ttf" "$G/tektur/Tektur%5Bwdth%2Cwght%5D.ttf" || w "  Tektur failed"
    if [ "$DRY" = 0 ]; then
        tmp="$(mktemp -d)"
        curl -fsSL -o "$tmp/jb.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
            && unzip -qo "$tmp/jb.zip" '*.ttf' -d "$FONTS/JetBrainsMonoNF" || w "  Nerd Font failed"
        rm -rf "${tmp:?}"
        fc-cache -f >/dev/null
    else echo "  [dry-run] download JetBrainsMono Nerd Font, fc-cache"; fi
else c "[2/6] fonts: skipped"; fi

# ---------------------------------------------------------------- tools
run mkdir -p "$BIN"
if [ "$TOOLS" = 1 ]; then
    c "[3/6] starship + yazi (official release binaries into $BIN)"
    if [ "$(uname -m)" = x86_64 ]; then
        command -v starship >/dev/null || run bash -c "curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b '$BIN'"
        if [ ! -x "$BIN/yazi" ] && [ "$DRY" = 0 ]; then
            tmp="$(mktemp -d)"
            curl -fsSL -o "$tmp/y.zip" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip \
                && unzip -qo "$tmp/y.zip" -d "$tmp" && install -m755 "$tmp"/yazi-*/yazi "$tmp"/yazi-*/ya "$BIN/" || w "  yazi failed"
            rm -rf "${tmp:?}"
        fi
    else w "  not x86_64, install starship and yazi yourself"; fi
else c "[3/6] tools: skipped"; fi

# ---------------------------------------------------------------- configs
c "[4/6] configs"
deploy() {  # deploy <dir name in repo/config>
    local s="$SRC/config/$1" d="$CFG/$1"
    if [ "$DRY" = 1 ]; then echo "  [dry-run] $1 -> $d"; return; fi
    if [ -e "$d" ]; then mkdir -p "$BACKUP/config"; cp -a "$d" "$BACKUP/config/$1"; fi
    mkdir -p "$d"; cp -a "$s/." "$d/"
}
for dir in hypr quickshell kitty fish fastfetch rofi cava mpv yazi gtk-3.0 gtk-4.0 fontconfig; do deploy "$dir"; done
if [ "$DRY" = 0 ]; then
    if [ -f "$CFG/starship.toml" ]; then mkdir -p "$BACKUP/config"; cp -a "$CFG/starship.toml" "$BACKUP/config/starship.toml"; fi
    cp "$SRC/config/starship.toml" "$CFG/starship.toml"
    # paths inside configs are templated
    grep -rIl '@HOME@' "$CFG/hypr" "$CFG/fastfetch" 2>/dev/null | xargs -r sed -i "s|@HOME@|$HOME|g"
    # first wallpaper (wallpaper-sync swaps it for whatever you pick in GNOME Settings -> Background)
    [ -f "$CFG/hypr/wall.png" ] || cp "$SRC/assets/wall.png" "$CFG/hypr/wall.png"
    ln -sfn "$CFG/hypr/wall.png" "$CFG/hypr/wall-current"
    mkdir -p "$BIN" "$CFG/systemd/user" "$HOME/.local/share/applications" "$HOME/.cache/netrun" "$HOME/.local/state/netrun"
    install -m755 "$SRC"/bin/* "$BIN/"
    cp "$SRC/systemd/hyprland-session.target" "$CFG/systemd/user/"
    # GNOME Settings hides itself outside GNOME; this copy shows up in the launcher and works under Hyprland
    if [ -f /usr/share/applications/org.gnome.Settings.desktop ]; then
        sed -e '/^OnlyShowIn=/d' -e 's|^Exec=gnome-control-center|Exec=env XDG_CURRENT_DESKTOP=GNOME gnome-control-center|' \
            /usr/share/applications/org.gnome.Settings.desktop > "$HOME/.local/share/applications/org.gnome.Settings.desktop"
    fi
    # dark mode for GTK / libadwaita / portals
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark 2>/dev/null || true
    if command -v fish >/dev/null; then w "  tip: chsh -s $(command -v fish)   (optional: make fish your login shell)"; fi
else echo "  [dry-run] templates, scripts, wallpaper, systemd target, dark mode"; fi

# ---------------------------------------------------------------- optional parts
if [ "$FIREFOX" = 1 ]; then
    c "[5/6] Firefox"
    prof="$(ls -d "$HOME"/.config/mozilla/firefox/*.default-release "$HOME"/.mozilla/firefox/*.default-release 2>/dev/null | head -1 || true)"
    if [ -n "$prof" ]; then
        if [ "$DRY" = 0 ]; then
            mkdir -p "$prof/chrome" "$BACKUP/firefox"; cp -a "$prof/chrome/." "$BACKUP/firefox/" 2>/dev/null || true
            cp "$SRC/firefox/userChrome.css" "$SRC/firefox/userContent.css" "$prof/chrome/"
            cp "$SRC/firefox/user.js" "$prof/user.js"
        fi
        echo "  profile: $prof  (restart Firefox)"
    else w "  no Firefox profile found: start Firefox once, then run ./install.sh --firefox --no-packages --no-fonts --no-tools"; fi
fi
if [ "$VSCODE" = 1 ]; then
    c "[5/6] VS Code theme"
    if [ "$DRY" = 0 ]; then
        mkdir -p "$HOME/.vscode/extensions"
        rm -rf "${HOME:?}/.vscode/extensions/netrun.night-city-hud-1.0.0"
        cp -r "$SRC/vscode/night-city-hud" "$HOME/.vscode/extensions/netrun.night-city-hud-1.0.0"
    fi
    echo '  pick "Night City HUD" in Ctrl+K Ctrl+T'
fi
if [ "$SPOTIFY" = 1 ]; then
    c "[5/6] Spotify (Flatpak) + Spicetify"
    if ! flatpak list 2>/dev/null | grep -q com.spotify.Client; then w "  install it first: flatpak install flathub com.spotify.Client"
    elif [ "$DRY" = 1 ]; then echo "  [dry-run] spicetify theme, wayland flags, warm start"
    else
        sp="/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
        mkdir -p "$CFG/spicetify/Themes"; cp -r "$SRC/config/spicetify/Themes/NightCity" "$CFG/spicetify/Themes/"
        [ -x "$HOME/.spicetify/spicetify" ] || curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
        export PATH="$HOME/.spicetify:$PATH"
        sudo chmod -R a+wr "$sp"
        spicetify config spotify_path "$sp" prefs_path "$HOME/.var/app/com.spotify.Client/config/spotify/prefs" current_theme NightCity color_scheme hud inject_css 1 replace_colors 1 overwrite_assets 1
        spicetify backup apply || w "  spicetify failed: run Spotify once and log in, then re-run with --spotify"
        mkdir -p "$HOME/.var/app/com.spotify.Client/config"
        printf '%s\n' '--enable-features=UseOzonePlatform,VaapiVideoDecoder' '--ozone-platform=wayland' '--enable-gpu-rasterization' '--ignore-gpu-blocklist' > "$HOME/.var/app/com.spotify.Client/config/spotify-flags.conf"
        sed -i 's|--@spotify@ ||' "$CFG/hypr/hyprland.lua"
        sed 's|^Exec=.*|Exec=spotify-toggle|' /var/lib/flatpak/exports/share/applications/com.spotify.Client.desktop > "$HOME/.local/share/applications/com.spotify.Client.desktop"
        echo "  Spotify now starts hidden at login; Super+Shift+M shows/hides it instantly"
    fi
fi

c "[6/6] done"
if [ "$DRY" = 1 ]; then echo "Dry run only, nothing changed."; exit 0; fi
cat <<MSG

Log out, pick "Hyprland" in the gear menu on the login screen, sign in.
Keys: Super+D apps, Super+Enter terminal, Super+M radio, Super+A sound, Super+W Wi-Fi, Super+B Bluetooth,
      Super+Tab windows, Super+E files, Super+N messages, Super+Esc power menu, Super+L lock.
Previous configs are saved in: $BACKUP
Roll back with ./uninstall.sh
MSG
