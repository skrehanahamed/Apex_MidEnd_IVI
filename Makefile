# ==============================================================================
# Apex IVI - Qt6 C++ Native Automotive System
# Developer: Sk Rehan Ahamed
# ==============================================================================

.PHONY: all build run clean pi pi-sync pi-build pi-run pi-kill pi-clean tiger vnc audio audio-kill pi-res pi-desktop pi-appliance help

# Raspberry Pi Target Settings
PI_IP   ?= 192.168.1.217
PI_USER ?= rehan
PI_HOST ?= $(PI_USER)@$(PI_IP)
PI_DIR  ?= ~/Apex_IVI

# Default target
all: build

# ------------------------------------------------------------------------------
# Local (macOS) Targets
# ------------------------------------------------------------------------------

# Build Qt6 C++ application with parallel compilation
build:
	@mkdir -p build
	@cmake -B build -S . -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt"
	@cmake --build build -j$(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)
	@echo "⚡ Apex IVI build complete: build/ApexIVI"

# Run Apex IVI native head unit locally
run: build
	@echo "🚀 Launching Apex IVI (1280x720 Native)..."
	@./build/ApexIVI

# Clean build artifacts locally
clean:
	@rm -rf build
	@echo "🧹 Clean complete."

# ------------------------------------------------------------------------------
# Raspberry Pi Targets
# ------------------------------------------------------------------------------

# Open TigerVNC viewer with dynamic remote screen resizing enabled
tiger:
	@pgrep -x vncviewer >/dev/null 2>&1 || (/Applications/TigerVNC.app/Contents/MacOS/vncviewer -RemoteResize=1 -FullScreen=0 -AutoSelect=0 -FullColor=1 -PreferredEncoding=Tight -CompressLevel=1 -QualityLevel=9 -PointerEventInterval=0 $(PI_IP) >/dev/null 2>&1 &)
	@osascript -e 'tell application "TigerVNC" to activate' >/dev/null 2>&1 || true

vnc: tiger

# Start live audio stream from Raspberry Pi PipeWire to Mac speakers
audio:
	@pgrep -f "pw-record.*ffplay" >/dev/null 2>&1 || (nohup bash scripts/pi_audio.sh $(PI_HOST) >/dev/null 2>&1 & echo "🔊 Live audio streaming to Mac speakers enabled.")

# Stop audio stream
audio-kill:
	@pkill -f "pw-record.*ffplay" >/dev/null 2>&1 || true
	@pkill -9 -x ffplay >/dev/null 2>&1 || true
	@echo "🔇 Audio stream stopped."

# Dynamically change resolution on Raspberry Pi (Usage: make pi-res RES=1080p | 720p | 600p | gui)
RES ?= gui
pi-res:
	@ssh -t $(PI_HOST) "pi-resolution $(RES)"

# Fast delta rsync to Raspberry Pi
pi-sync:
	@echo "📡 Syncing to Raspberry Pi 5..."
	@rsync -az --delete \
		--exclude='.git*' \
		--exclude='build*' \
		--exclude='.cache' \
		--exclude='.idea' \
		--exclude='.vscode' \
		--exclude='*.user' \
		--exclude='*.swp' \
		./ $(PI_HOST):$(PI_DIR)/
	@echo "✔ Code synced."

# Compile natively on Raspberry Pi
pi-build: pi-sync
	@echo "⚡ Building on Raspberry Pi 5..."
	@ssh -o BatchMode=yes $(PI_HOST) "cd $(PI_DIR) && cmake --build build -j\$$(nproc)"
	@echo "✔ Build complete."

# Kill any existing instance running on Raspberry Pi
pi-kill:
	@ssh -o BatchMode=yes $(PI_HOST) "killall -9 -q ApexIVI || true"
	@echo "✔ Apex IVI stopped."

# Build, deploy, and launch on Raspberry Pi
pi-run: pi-build tiger audio
	@echo "🚀 Launching Apex IVI..."
	@ssh -o BatchMode=yes $(PI_HOST) "killall -9 -q ApexIVI || true"
	@ssh -t $(PI_HOST) "cd $(PI_DIR) && export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 DISPLAY=:0 QT_QPA_PLATFORM=wayland QSG_RENDER_LOOP=threaded APEX_MAXIMIZED=1 && ./build/ApexIVI"

# Default shortcut for Raspberry Pi run
pi: pi-run

# Switch Raspberry Pi boot to Direct Automotive Appliance Mode (boots directly into Apex IVI fullscreen)
pi-appliance:
	@echo "🚗 Switching Raspberry Pi to Direct Automotive Appliance Mode..."
	@ssh $(PI_HOST) "echo 'Rehan@1997' | sudo -S sed -i 's/user-session=.*/user-session=apex-ivi/g' /etc/lightdm/lightdm.conf && echo 'Rehan@1997' | sudo -S sed -i 's/autologin-session=.*/autologin-session=apex-ivi/g' /etc/lightdm/lightdm.conf && echo 'Rehan@1997' | sudo -S systemctl restart lightdm"
	@echo "✔ Direct Boot Appliance Mode activated."

# Restore standard Raspberry Pi OS Desktop mode (taskbar, wallpaper, desktop icons)
pi-desktop:
	@echo "🖥️  Restoring standard Raspberry Pi OS Desktop mode..."
	@ssh $(PI_HOST) "echo 'Rehan@1997' | sudo -S sed -i 's/user-session=.*/user-session=rpd-labwc/g' /etc/lightdm/lightdm.conf && echo 'Rehan@1997' | sudo -S sed -i 's/autologin-session=.*/autologin-session=rpd-labwc/g' /etc/lightdm/lightdm.conf && echo 'Rehan@1997' | sudo -S systemctl restart lightdm"
	@echo "✔ Standard Raspberry Pi OS Desktop restored."

# Clean build artifacts on Raspberry Pi
pi-clean:
	@echo "🧹 Cleaning Raspberry Pi build cache..."
	@ssh $(PI_HOST) "rm -rf $(PI_DIR)/build"
	@echo "✔ Remote clean complete."

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
help:
	@echo "Apex IVI & Raspberry Pi Dynamic Screen Control"
	@echo ""
	@echo "Local macOS Targets:"
	@echo "  make build       - Compile native C++ & QML binary locally"
	@echo "  make run         - Build and launch native IVI window on Mac"
	@echo "  make clean       - Clean local CMake build cache"
	@echo ""
	@echo "Raspberry Pi Targets (Host: $(PI_HOST)):"
	@echo "  make tiger       - Open TigerVNC with dynamic remote resizing enabled"
	@echo "  make audio       - Stream live Pi audio directly to Mac speakers"
	@echo "  make audio-kill  - Stop live audio stream"
	@echo "  make pi-res      - Dynamic screen resolution picker (or RES=1080p / 720p / 600p)"
	@echo "  make pi          - Sync code, compile, and launch Apex IVI on Pi"
	@echo "  make pi-sync     - Fast rsync transfer of source files to Raspberry Pi"
	@echo "  make pi-build    - Compile natively on Raspberry Pi without launching"
	@echo "  make pi-kill     - Terminate running Apex IVI process on Raspberry Pi"
	@echo "  make pi-desktop  - Ensure standard Raspberry Pi OS Desktop is active"
	@echo "  make pi-clean    - Clean CMake build cache on Raspberry Pi"
	@echo ""
