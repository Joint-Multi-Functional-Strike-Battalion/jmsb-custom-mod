# Voice backup: LiveKit, 2026-11-01

The working voice system before any change away from WebRTC.

- `addons/`: voice, adapter_livekit, adapter_von
- `extensions/jmsb_voice`: the Rust extension source (no `target/`)
- `bin/`: the built libraries and `dlls.sha256`
  - `jmsb_voice_x64.dll` 1a1bc4b4632f18a40051d1661fb871d125652f293e550d3595362874d9ad9825 (BattlEye-whitelisted build; the same file as the mod root's in git history)
  - `jmsb_voice_x64.so` c82a5040437417471d0f4226a8bf5f32f8de3e062a343d43559c4843692b8207
- `docs/`: the voice design docs
- `.github/workflows/jmsb_voice.yml`: the build and signing workflow
- `pelican-eggs/livekit-voice`: the LiveKit server egg

To restore: copy each folder back to the same path, and the two libraries to the mod root.
