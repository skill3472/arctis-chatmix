# SteelSeries Arctis Chatmix for Linux

A lightweight, plug-and-play solution to enable the physical Chatmix dial on SteelSeries Arctis headsets (like the Arctis Nova 7) on Linux. 

By default, Linux does not recognize the Chatmix dial. This project creates a background service that automatically reads the hardware dial and seamlessly crossfades your audio between two virtual audio devices (Game and Chat), mimicking the official Windows software behavior.

For a list of all supported devices, [check headsetcontrol's README here](https://github.com/Sapd/HeadsetControl/blob/master/README.md). Note that this script has a hardcoded "steelseries" string to help find the right audio device. This script should work with other supported headphones if you change that value.

## Features
* **Proper Crossfade Logic:** The center of the dial keeps both channels at 100% volume, smoothly fading out the opposite channel as you turn it.
* **Anti-Jitter Deadbands:** Ignores microscopic hardware fluctuations so your volume doesn't bounce around when you aren't touching the dial.
* **Dynamic Hardware Detection:** Automatically finds your headset, even if you move it to a different USB port.
* **Silent & Automatic:** Runs as a lightweight Systemd background service. Automatically starts on boot and restarts itself if it crashes.

## Prerequisites
Before installing, you must have the following installed on your system:
1. **[headsetcontrol](https://github.com/Sapd/HeadsetControl):** This is required to read the hardware data from your USB receiver. Make sure the `headsetcontrol` command works in your terminal.
2. **[uv](https://github.com/astral-sh/uv):** An extremely fast Python package and project manager.
3. **PipeWire or PulseAudio:** Standard on almost all modern Linux distributions (Ubuntu, Fedora, Arch, etc.).

## Installation

You can install and configure everything automatically with a single command. Open your terminal and run:

```bash
curl -sSL https://raw.githubusercontent.com/skill3472/arctis-chatmix/main/install.sh | bash
```

### How to Use It
Once installed, open your system's sound settings or a tool like `pavucontrol`. You will see two new output devices:
* **Game_Audio**
* **Chat_Audio**

1. Set your system's default audio output to **Game_Audio**.
2. Open TeamSpeak (or your voice chat app), go to its Audio Settings, and set the Output Device to **Chat_Audio**.
3. Turn the dial on your headset!

## Uninstallation

Want to remove it? This command will stop the background services, delete the project files, and instantly restore your live audio routing back to normal:

```bash
curl -sSL https://raw.githubusercontent.com/skill3472/arctis-chatmix/main/uninstall.sh | bash
```

## Troubleshooting

If the script is running but the volume isn't changing, you can check the live logs of the background service to see what it's doing:
```bash
systemctl --user status arctis-chatmix.service
```
To view a continuous live stream of the logs as you turn the dial:
```bash
journalctl --user -u arctis-chatmix.service -f
```
If after selecting any of the audio devices, you still don't head anything, try launching pavucontrol and seeing if the loopback streams for the virtual devices are set to your actual SteelSeries headset. Ensure they aren't muted.
