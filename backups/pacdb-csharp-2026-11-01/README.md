# Database extension backup: the C# build, 2026-11-01

`ghostd_pacdb_x64.dll` as it was before the Rust port (extensions/ghostd_pacdb):
DIVINER tools/pacdb/extension, version 0.6.0, NativeAOT with the .NET MongoDB
driver. SHA-256 f4a12a9cb404baede872ace213ca7a9dc7b014964b8d477b065c5c0c0f760be6.
Flagged by ClamAV and Gridinsoft on VirusTotal.

The C# Linux build is in git history (the mod root's `ghostd_pacdb_x64.so`
before 2026-11-01). To restore: copy the DLL back to the mod root and put its
hash back in tools/dlls.sha256.
