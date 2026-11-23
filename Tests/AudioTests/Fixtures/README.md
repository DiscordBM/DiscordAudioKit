# Audio Test Fixtures

Synthetic, minimal test files generated for unit and integration testing.

## Generation commands

All files contain a 200 ms 440 Hz pure sine wave tone generated using standard FFmpeg:

```bash
# 48 kHz stereo WAV (38 KB)
ffmpeg -y -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=0.2" -ac 2 sine440_stereo.wav

# 48 kHz stereo MP3 (4 KB)
ffmpeg -y -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=0.2" -ac 2 sine440.mp3

# 48 kHz stereo FLAC (11 KB)
ffmpeg -y -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=0.2" -ac 2 sine440.flac

# 44.1 kHz stereo WAV (resample test, 35 KB)
ffmpeg -y -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=0.2" -ac 2 sine440_44100.wav

# 48 kHz mono WAV (channel upmix test, 19 KB)
ffmpeg -y -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=0.2" -ac 1 sine440_mono.wav
```
