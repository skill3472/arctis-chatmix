#!/bin/bash

echo "🗑️ Starting uninstall process for SteelSeries Arctis Chatmix Setup..."

# 1. Stop and disable the Systemd service
echo "🛑 Stopping background Python sync..."
systemctl --user stop arctis-chatmix.service 2>/dev/null || true
systemctl --user disable arctis-chatmix.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/arctis-chatmix.service"

# Reload systemd so it registers that the service is gone
systemctl --user daemon-reload

# 2. Remove the Autostart entry
echo "🧹 Removing desktop autostart entry..."
rm -f "$HOME/.config/autostart/arctis-audio.desktop"

# 3. Remove the Project Files directory
echo "📁 Deleting project files..."
rm -rf "$HOME/.local/share/arctis-chatmix"

# 4. Unload Virtual Audio Devices from the current session
echo "🎧 Removing virtual audio sinks and loopbacks..."
# This finds any active PipeWire/PulseAudio module containing our sink names and unloads them
pactl list short modules | grep -E "Game_Sink|Chat_Sink" | awk '{print $1}' | while read -r module_id; do
    pactl unload-module "$module_id" 2>/dev/null || true
done

echo "✅ Uninstallation complete!"
echo "Your audio settings have been safely restored to normal."
