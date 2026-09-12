#!/usr/bin/env python3
# ==============================================================================
# Project: Apex MidEnd IVI - Automotive In-Vehicle Infotainment System
# Developer: Sk Rehan Ahamed
# File: generate_release_notes.py
# ==============================================================================

import sys

def generate(tag):
    body = f"""## Apex HORIZON MidEnd IVI - Automotive In-Vehicle Infotainment {tag}

### Key Subsystems & Features in {tag}

#### 1. Bluetooth Audio & Modern Media Card
- **Centered Typography**: Completely overhauled Bluetooth media player UI with centered titles and artist labels (`font.pixelSize: 44` / `25`), matching broadcast FM/AM specifications.
- **AVRCP & Metadata Synchronization**: Real-time parsing of track title, artist name, playback position, and album art fallback with BlueZ 5 AVRCP integration.
- **PipeWire Audio Sink**: High-fidelity wireless audio streaming over A2DP directly into the vehicle audio pipeline.

#### 2. PBAP Bluetooth Phonebook Synchronization
- **Direct Contact Pulling**: Direct integration with OpenOBEX and D-Bus PBAP profiles (`telecom/pb.vcf`) from paired smartphones.
- **High-Performance vCard Parser**: Asynchronous parsing supporting vCard 2.1 and 3.0 formats into an indexed contact list.
- **Fast Contact Search**: Instant alphanumeric search filter and auto-generated initials avatars.

#### 3. OEM Telephony Subsystem & Active In-Call Management
- **Full Automotive Phone Screen**: Integrated dial pad, recent call logs (incoming, outgoing, missed), speed dials, and device pairing management.
- **Active In-Call Screen UI**:
  - Live call duration timer and contact identity display.
  - Aligned End Call, Mic Mute, and Private/Hands-Free mode toggles.
  - Exact geometric alignment matching the right-hand sidebar keypad controls.
- **Deterministic Audio Prioritization**:
  - Incoming or active phone calls automatically pause background radio and Bluetooth media playback.
  - Media playback resumes smoothly when the call ends.

#### 4. Live Broadcast Radio & Direct Indian Streams
- **Direct Stream Acceleration**: Integrated high-speed, direct AAC/MP3 Indian radio streams for instantaneous playback.
- **Rotary Tuning Optimization**: Debounced frequency rolling and seek controls with persistent favorite memory presets.
- **Perceptual Loudness Curve**: Natural volume response curve across system audio channels.

#### 5. Cross-Platform Engine & Dynamic Resolution
- Full compatibility with Qt 6.5+ across Linux (x86_64 / ARM64), macOS (Universal), and Windows 10/11.
- Dynamic screen resizing and aspect ratio adaptation for 8-inch, 10.25-inch, and standard Display Audio panels.

---

### Downloadable Prebuilt Archives
| Platform | Archive Package | Architecture |
| :--- | :--- | :--- |
| **Ubuntu Linux** | `ApexIVI-Ubuntu-x86_64.zip` | x86_64 (glibc / X11 / OpenGL) |
| **macOS** | `ApexIVI-macOS.zip` | Universal (Apple Silicon & Intel) |
| **Windows** | `ApexIVI-Windows-x64.zip` | x64 (Standalone with Qt Runtime DLLs) |

See [README.md](https://github.com/skrehanahamed/Apex_MidEnd_IVI#readme) for full system architecture, build guides, and hardware documentation.

<sub>Engineered by **Sk Rehan Ahamed** | Automotive Digital Cockpit Systems</sub>
"""

    with open('release_body.md', 'w', encoding='utf-8') as out:
        out.write(body)
    print(f"Generated release_body.md for {tag}")

if __name__ == '__main__':
    tag_arg = sys.argv[1] if len(sys.argv) > 1 else 'v1.1.0'
    generate(tag_arg)
