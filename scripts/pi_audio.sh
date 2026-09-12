#!/usr/bin/env bash
# ==============================================================================
# Raspberry Pi to macOS Ultra-Low Latency Audio Streamer
# Streams Pi system and application audio (PipeWire) live to Mac speakers.
# Developer: Sk Rehan Ahamed
# ==============================================================================

PI_HOST="${1:-rehan@192.168.1.217}"

# Kill any existing stale streamer
pkill -f "pw-record.*ffplay" >/dev/null 2>&1 || true
sleep 0.2

exec ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$PI_HOST" \
    "pw-record --rate 48000 --channels 2 --format s16 --latency 20ms - | /usr/bin/ffmpeg -loglevel quiet -f s16le -ar 48000 -ac 2 -i - -c:a libopus -application lowdelay -frame_duration 10 -b:a 160k -flush_packets 1 -f ogg -" | \
    /opt/homebrew/bin/ffplay \
        -nodisp \
        -fflags nobuffer \
        -flags low_delay \
        -probesize 32 \
        -analyzeduration 0 \
        -sync ext \
        -loglevel quiet \
        -
