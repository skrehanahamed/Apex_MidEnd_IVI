# Third-Party Licenses and Open-Source Acknowledgments

Apex IVI utilizes and builds upon the following open-source software projects and libraries. We express our gratitude to the authors and open-source communities who have created and maintained these foundational technologies.

---

## 1. AASDK (Android Auto SDK)
- Author / Maintainer: f1xpl (https://github.com/f1xpl/aasdk)
- License: GNU General Public License v3.0 (GPL-3.0)
- Description: Open-source implementation of the Android Auto protocol client SDK. Apex IVI uses AASDK for cryptographic handshake encapsulation, channel multiplexing, and Protocol Buffer message serialization.

---

## 2. OpenAuto and Crankshaft
- Authors / Maintainers: f1xpl, OpenCarDev Team (https://github.com/f1xpl/openauto, https://github.com/opencardev/crankshaft)
- License: GNU General Public License v3.0 (GPL-3.0)
- Description: Landmark open-source automotive head unit software stacks that provided architectural patterns for embedded automotive hardware integration.

---

## 3. aa-proxy-rs
- Author: Steffen K. (https://github.com/steffen-k/aa-proxy-rs)
- License: MIT License / Apache 2.0
- Description: High-performance Rust reverse-engineering implementation of the Android Auto accessory protocol and USB frame parser.

---

## 4. PipeWire and WirePlumber
- Authors / Maintainers: Wim Taymans, Collabora, and the PipeWire Community (https://pipewire.org)
- License: MIT License / LGPL-2.1
- Description: Pro-audio and automotive low-latency multimedia routing framework. Used in Apex IVI for multi-channel stream routing (Media, Speech, System alerts) and dynamic latency management.

---

## 5. Qt 6 Framework
- Maintainer: The Qt Company (https://www.qt.io)
- License: LGPL-3.0 / Commercial
- Description: Application framework and graphical presentation engine utilized for Qt Quick, QML rendering, and core C++ event handling.

---

## 6. The Yocto Project & meta-raspberrypi
- Maintainers: The Linux Foundation and Raspberry Pi Ltd. (https://www.yoctoproject.org)
- License: MIT License
- Description: Industrial embedded Linux build framework and hardware support packages for the Raspberry Pi 5 platform.

---

## 7. OpenSSL
- Maintainer: The OpenSSL Project (https://www.openssl.org)
- License: Apache License 2.0
- Description: Cryptographic library used for TLS authentication and secure socket communications with Android devices.

---

## 8. Protocol Buffers (Protobuf)
- Maintainer: Google LLC (https://github.com/protocolbuffers/protobuf)
- License: BSD 3-Clause License
- Description: Structured data serialization mechanism utilized for Android Auto message schemas.
