function fish_greeting
	microfetch
end

set -U fish_greeting

if status is-interactive
    if command -q starship
        # Starship custom prompt
        starship init fish | source
    end

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    if command -q sesh
        sesh completion fish | source
    end

    if command -q direnv
        direnv hook fish | source
    end

    if command -q atuin
        atuin init fish | source
    end

    if command -q eza
        alias l 'eza --icons=auto --group-directories-first'
        alias ll 'eza -lah --icons=auto --group-directories-first --git'
        alias lt 'eza --tree --level=2 --icons=auto'
    end
end

set -gx COLORTERM truecolor
set -gx EDITOR nvim
