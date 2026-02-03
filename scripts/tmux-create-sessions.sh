#!/bin/bash

# Format: "session_name:path"
sessions=(
    "general:~/Documents"
)

# Create each session in detached mode
for entry in "${sessions[@]}"; do
    session="${entry%%:*}"
    path="${entry#*:}" # "general:~/Documents" becomes "~/Documents"
    path="${path/#\~/$HOME}" # "~/Documents" becomes "/Users/{user}/Documents"

    if tmux has-session -t "$session" 2>/dev/null; then
        echo "Session '$session' already exists, skipping..."
    else
        tmux new-session -d -s "$session" -c "$path"
        echo "Created session: $session (in $path)"
    fi
done

echo "Done! Use 'tmux ls' to see all sessions."
echo "Attach with: tmux attach"
