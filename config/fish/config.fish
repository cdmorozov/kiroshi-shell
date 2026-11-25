set -g fish_greeting
# Cyberpunk HUD colors
set -g fish_color_normal c8d6e0
set -g fish_color_command 7ec8a0
set -g fish_color_keyword ff3ea5
set -g fish_color_param c8d6e0
set -g fish_color_option ffa62b
set -g fish_color_quote 3fd47e
set -g fish_color_redirection ffa62b
set -g fish_color_end ffa62b
set -g fish_color_operator ffa62b
set -g fish_color_escape ff3ea5
set -g fish_color_error ff4d6a
set -g fish_color_comment 3a4a63
set -g fish_color_autosuggestion 3a4a63
set -g fish_color_cwd ffa62b
set -g fish_color_user 8fa3b8
set -g fish_color_host ff3ea5
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=1a2a44
set -g fish_color_search_match --background=1a2a44
set -g fish_pager_color_prefix 7ec8a0 --bold
set -g fish_pager_color_completion c8d6e0
set -g fish_pager_color_description 3a4a63
set -g fish_pager_color_progress ffa62b
set -g fish_pager_color_selected_background --background=1a2a44
set -gx BAT_THEME ansi
set -gx EZA_COLORS 'di=38;2;126;147;173:ex=38;2;111;190;140:ln=38;2;217;70;143'

if status is-interactive
    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init fish --cmd cd | source
    if type -q eza
        alias ls 'eza --icons --group-directories-first'
        alias ll 'eza -l --icons --group-directories-first --git'
        alias la 'eza -la --icons --group-directories-first --git'
        alias lt 'eza --tree --level=2 --icons'
    end
    type -q bat; and alias cat 'bat --paging=never'
    if type -q fastfetch
        if test "$TERM" = xterm-kitty
            set -l sf ~/.local/state/netrun/session
            mkdir -p (path dirname $sf)
            echo (math (cat $sf 2>/dev/null; or echo 0) + 1) > $sf
            if test -x ~/.local/bin/netrun-updates
                ~/.local/bin/netrun-updates &; disown
            end
            fastfetch -c ~/.config/fastfetch/netrun.jsonc
            echo
        else
            fastfetch
        end
    end
    ls
end
