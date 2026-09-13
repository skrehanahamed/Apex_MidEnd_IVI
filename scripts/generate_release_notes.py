#!/usr/bin/env python3
# ==============================================================================
# Project: Apex MidEnd IVI - Automotive In-Vehicle Infotainment System
# Developer: Sk Rehan Ahamed
# File: generate_release_notes.py
# ==============================================================================

import sys

def generate(tag):
    body = f"""## Apex HORIZON MidEnd IVI - Automotive In-Vehicle Infotainment {tag}

Date of Release: September 14, 2026

### Key Subsystems and Enhancements in {tag}

#### 1. Native Android Auto Projection (AASDK Engine)
- Android Open Accessory (AOA) 2.0 protocol enumeration and automated handshake directly from the IVI binary.
- Embedded TLS session negotiation, cryptographic channel setup, and Protobuf service multiplexing.
- Low-latency multi-threaded H.264 video decoding pipeline streaming 1280x720 at 60 FPS with zero copy delivery.
- Real-time absolute touch coordinate normalization and hardware keycode injection.

#### 2. Deterministic Audio Prioritization and PipeWire Arbitration
- Channel 4 Media Audio Monitoring: Instantly detects mobile projection audio streams and claims audio focus.
- Sub-Millisecond FM Radio Cutoff: Direct process termination and buffer purge eliminating all audio overlap (<1 ms cutoff).
- Multi-Stream Output: Dedicated audio pipelines for Media (48 kHz Stereo) and Guidance/System Voice (16 kHz Mono).
- Reverse Media Arbitration: Automatically sends pause keycodes to Android Auto when native radio or Bluetooth is selected.

#### 3. Dual-Projection Cockpit Modes
- Split-Screen Multi-View: Default dashboard view combining navigation, media player widget, and fast navigation rail.
- Full Map View: Dedicated one-tap projection mode expanding navigation to full-screen 1280x720 display.
- Seamless OEM Return: Vehicle home icon returns directly to the native IVI cockpit without session termination.

#### 4. Automated USB Hotplug and Endpoint Reset
- Added apex-usb-reset.py using Linux USBDEVFS_RESET ioctl to reset accessory mode endpoints without physical cable re-plugging.
- Eliminates reconnect reboot loops on mobile device disconnect.

#### 5. Cross-Platform Engine and CI Automation
- Full compatibility with Qt 6.5+ across Linux (x86_64 and ARM64), macOS (Universal Apple Silicon / Intel), and Windows.
- Automated GitHub Actions build validation and multi-platform packaging pipeline.
- Conditional compilation: Full hardware acceleration on Raspberry Pi 5 / Yocto target; desktop development stubs for CI runners.

#### 6. Core OEM Cockpit Subsystems
- Bluetooth Audio and Phonebook: BlueZ 5 AVRCP metadata display, PBAP contact synchronization, and indexed search.
- Active Telephony: Integrated dial pad, call logs, in-call screen with timer, mic mute, and private mode toggles.
- Live Broadcast Radio: Instant AAC/MP3 stream acceleration and rotary tuning simulation.

---

### Third-Party Credits and Attribution
We gratefully acknowledge the open-source projects and communities that contributed foundational components:
- f1xpl / aasdk: Foundational Android Auto Protocol SDK.
- openauto & crankshaft: Automotive projection reference architectures.
- aa-proxy-rs: Protocol insights and AOA negotiation references.
- PipeWire & WirePlumber: Automotive low-latency audio multiplexing.
- The Yocto Project & Raspberry Pi Ltd.: Embedded automotive Linux BSP and GPU stacks.

Full licensing details are available in THIRD_PARTY_LICENSES.md.

---

### Downloadable Prebuilt Archives
| Platform | Archive Package | Architecture |
| :--- | :--- | :--- |
| Ubuntu Linux | ApexIVI-Ubuntu-x86_64.zip | x86_64 (glibc / X11 / OpenGL) |
| macOS | ApexIVI-macOS.zip | Universal (Apple Silicon & Intel) |
| Windows | ApexIVI-Windows-x64.zip | x64 (Standalone with Qt Runtime) |

See README.md for full system architecture, build guides, and hardware documentation.

Engineered by Sk Rehan Ahamed | Automotive Digital Cockpit Systems
"""

    with open('release_body.md', 'w', encoding='utf-8') as out:
        out.write(body)
    print(f"Generated release_body.md for {tag}")

if __name__ == '__main__':
    tag_arg = sys.argv[1] if len(sys.argv) > 1 else 'v1.2.0'
    generate(tag_arg)
