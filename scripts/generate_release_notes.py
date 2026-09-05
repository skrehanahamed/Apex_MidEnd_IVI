#!/usr/bin/env python3
# ==============================================================================
# Project: Apex MidEnd IVI - Automotive In-Vehicle Infotainment System
# Developer: Sk Rehan Ahamed
# File: generate_release_notes.py
# ==============================================================================

import sys
import os
import re

def generate(tag):
    v = tag.lstrip('v')
    notes = ''
    readme_path = 'README.md'
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            content = f.read()
        pattern = rf'## Release Notes[^\n]*{re.escape(v)}[\s\S]*?(?=\n---\n|\n## Release Notes|\Z)'
        match = re.search(pattern, content)
        if match:
            notes = match.group(0).strip()

    body = f"## Apex MidEnd IVI - Automotive In-Vehicle Infotainment - {tag}\n\n"
    body += "### Downloadable Prebuilt Archives\n"
    body += "| Platform | Archive Package | Architecture |\n"
    body += "| :--- | :--- | :--- |\n"
    body += "| **Ubuntu Linux** | `ApexIVI-Ubuntu-x86_64.zip` | x86_64 (glibc / X11 / OpenGL) |\n"
    body += "| **macOS** | `ApexIVI-macOS.zip` | Universal (Apple Silicon & Intel) |\n"
    body += "| **Windows** | `ApexIVI-Windows-x64.zip` | x64 (Standalone with Qt Runtime DLLs) |\n\n"

    body += "### System Highlights\n"
    body += "- **Dual-Card Cockpit Home**: Live FM tuner metadata & phone projection\n"
    body += "- **Full Two-Tone Radio**: Cyan FM/AM badge with crisp white frequency digits & live Icecast streams\n"
    body += "- **DRVM Camera & Assist**: Reverse guidelines with ultrasonic obstacle radar\n"
    body += "- **Voice Memo Studio**: Dynamic waveform audio visualizer & storage management\n"
    body += "- **OEM Volume HUD**: Auto-dismissing bottom floating slider\n\n"

    if notes:
        body += "---\n\n" + notes + "\n"
    else:
        body += "See [README.md](https://github.com/skrehanahamed/Apex_MidEnd_IVI#readme) for full documentation, subsystem architecture, and build guides.\n\n"

    body += "<sub>Made with ❤️ by **Sk Rehan** and with the help of **Antigravity** and **ChatGPT**</sub>\n"

    with open('release_body.md', 'w', encoding='utf-8') as out:
        out.write(body)
    print(f"Generated release_body.md for {tag}")

if __name__ == '__main__':
    tag_arg = sys.argv[1] if len(sys.argv) > 1 else 'v1.0.0'
    generate(tag_arg)
