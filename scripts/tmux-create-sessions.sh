#!/bin/bash

# List of session names
sessions=(
    "general"
)

# Create each session in detached mode
for session in "${sessions[@]}"; do
    # Check if session already exists
    if tmux has-session -t "$session" 2>/dev/null; then
        echo "Session '$session' already exists, skipping..."
    else
        tmux new-session -d -s "$session"
        echo "Created session: $session"
    fi
done

echo "Done! Use 'tmux ls' to see all sessions."
echo "Attach with: tmux attach"
