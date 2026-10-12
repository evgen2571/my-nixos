if test -r /run/secrets/openrouter-api-key
    set -gx OPENROUTER_API_KEY \
        (string trim -- (cat /run/secrets/openrouter-api-key))
end
