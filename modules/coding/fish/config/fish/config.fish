function fish_greeting
	microfetch
end

set -U fish_greeting

if status is-interactive
    # Starship custom prompt
    starship init fish | source

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end

set -gx COLORTERM truecolor
set -gx EDITOR nvim
COMPLETE=fish tms | source
