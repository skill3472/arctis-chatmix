#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🎧 Starting SteelSeries Arctis Chatmix Setup..."

# 1. Define Paths
INSTALL_DIR="$HOME/.local/share/arctis-chatmix"
CONFIG_DIR="$HOME/.config/systemd/user"
AUTOSTART_DIR="$HOME/.config/autostart"

# Ensure directories exist
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$AUTOSTART_DIR"

# 2. Find dependencies
UV_PATH=$(command -v uv || true)
if [ -z "$UV_PATH" ]; then
    echo "❌ Error: 'uv' is not installed or not in PATH."
    echo "Please install uv (https://github.com/astral-sh/uv) and try again."
    exit 1
fi

HEADSETCONTROL_PATH=$(command -v headsetcontrol || true)
if [ -z "$HEADSETCONTROL_PATH" ]; then
    echo "❌ Error: 'headsetcontrol' is not installed or not in PATH."
    exit 1
fi

echo "📦 Creating project files in $INSTALL_DIR..."

# 3. Generate the Python Script
cat << 'EOF' > "$INSTALL_DIR/main.py"
import subprocess
import re
import time

def get_chatmix():
    try:
        result = subprocess.run(['headsetcontrol', '-m'], capture_output=True, text=True)
        match = re.search(r"Chatmix:\s*(\d+)", result.stdout)
        return int(match.group(1)) if match else None
    except Exception:
        return None

def set_volumes(mix_val):
    # Center deadzone (62-66) keeps both at 100% easily
    if 62 <= mix_val <= 66:
        game_vol = 1.0
        chat_vol = 1.0
    elif mix_val < 62:
        game_vol = 1.0
        chat_vol = mix_val / 62.0
    else:
        chat_vol = 1.0
        game_vol = (128 - mix_val) / (128.0 - 66.0)

    subprocess.run(['pactl', 'set-sink-volume', 'Game_Sink', f'{int(game_vol * 100)}%'])
    subprocess.run(['pactl', 'set-sink-volume', 'Chat_Sink', f'{int(chat_vol * 100)}%'])

if __name__ == "__main__":
    print("Starting Chatmix Sync...")

    last_val = None
    # Minimum physical steps required to trigger an update (removes jitter)
    JITTER_THRESHOLD = 2

    try:
        while True:
            current_val = get_chatmix()

            if current_val is not None:
                # If this is the first run, OR the value changed enough to break the threshold
                if last_val is None or abs(current_val - last_val) >= JITTER_THRESHOLD:
                    set_volumes(current_val)
                    last_val = current_val # Update our memory

            time.sleep(0.5)
    except KeyboardInterrupt:
        print("Stopped.")
EOF

# 4. Generate the Audio Routing Bash Script
# Note: We do headset detection AT RUNTIME here, so it survives USB port changes.
cat << 'EOF' > "$INSTALL_DIR/setup_audio.sh"
#!/bin/bash
sleep 5

# Create Virtual Sinks
pactl list short sinks | grep -q "Game_Sink" || pactl load-module module-null-sink sink_name=Game_Sink sink_properties=device.description=Game_Audio
pactl list short sinks | grep -q "Chat_Sink" || pactl load-module module-null-sink sink_name=Chat_Sink sink_properties=device.description=Chat_Audio

# Dynamically find the exact SteelSeries hardware name
HEADSET_SINK=$(pactl list short sinks | grep -i "steelseries" | awk '{print $2}' | head -n 1)

if [ -n "$HEADSET_SINK" ]; then
    pactl list short modules | grep -q "source=Game_Sink.monitor" || pactl load-module module-loopback source=Game_Sink.monitor sink="$HEADSET_SINK"
    pactl list short modules | grep -q "source=Chat_Sink.monitor" || pactl load-module module-loopback source=Chat_Sink.monitor sink="$HEADSET_SINK"
    echo "Audio routed to $HEADSET_SINK successfully."
else
    echo "Warning: SteelSeries headset not found. Virtual sinks created without hardware loopback."
fi
EOF
chmod +x "$INSTALL_DIR/setup_audio.sh"

# 5. Generate Autostart Entry for Audio Routing
cat << EOF > "$AUTOSTART_DIR/arctis-audio.desktop"
[Desktop Entry]
Type=Application
Exec=$INSTALL_DIR/setup_audio.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Arctis Audio Routing
Comment=Creates virtual sinks and loopbacks for Arctis headset
EOF

# 6. Generate Systemd Service for Python Sync
cat << EOF > "$CONFIG_DIR/arctis-chatmix.service"
[Unit]
Description=SteelSeries Chatmix Python Sync
After=pipewire.service pulseaudio.service

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$UV_PATH run main.py
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

# 7. Enable and Start Services
echo "🚀 Enabling and starting background services..."
systemctl --user daemon-reload
systemctl --user enable --now arctis-chatmix.service

# Run the audio setup once right now so the user doesn't have to reboot
"$INSTALL_DIR/setup_audio.sh"

echo "✅ Setup Complete!"
echo "Game_Audio and Chat_Audio have been created. You can now map your games and Discord."
