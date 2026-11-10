# ghostd_pacdb

TAC//PAC's database extension for the Arma 3 **server** (addons/pac). Rust,
since 2026-11-01: a port of DIVINER `tools/pacdb/extension/Extension.cs`
with the same verbs, answers and callbacks, so the mod's scripts did not
change. The C# build (NativeAOT, the .NET MongoDB driver, 28 MB) was
flagged by ClamAV and Gridinsoft; this one is the Rust MongoDB driver over
rustls, about 11 MB.

| Mod root | Built | For |
|---|---|---|
| `ghostd_pacdb_x64.dll` | Windows | a Windows server or host (in the release since 2026-11-01) |
| `ghostd_pacdb_x64.so` | Linux, in Docker | the Linux server (in the release) |

No client ever loads it.

## What it does

The mod hands it one address (`configure`, from the CBA server setting
'Database'):

- `mongodb+srv://` / `mongodb://`: MongoDB directly. The database named in the
  string, else `ghostd`; collection `pac`; one document per key, `_id` the
  key, the JSON's fields as real BSON fields, `updatedAt` the write time.
- `http://` / `https://`: the pacdb service, with the key as `X-Api-Key`.

Before `configure`, the address comes from the server's machine:
`GHOSTD_PACDB_URL` / `GHOSTD_PACDB_KEY`, else a `pacdb.json`
(`{"url": ..., "apiKey": ...}`) beside the server's exe, in its working
directory, or (Windows) beside the DLL.

| Verb | Args | Returns | Callback |
|---|---|---|---|
| `configure` | url, key | `ok` | |
| `get` | key | `queued` | `get.begin` n, `get.chunk` "i\|text" (7000 characters each), `get.end` ok / empty; or `get.error` |
| `list` | prefix | `queued` | `list` (a JSON array of keys); or `list.error` |
| `put.begin` | key, n | `queued` | |
| `put.chunk` | i, text | `queued` | |
| `put.end` | | `queued` | `put.end` ok; or `put.error` |
| `ping` | | `queued` | `ping` "ok VERSION -> address (from where)", the password masked |

A bad call returns `error: ...` with code 1. The work runs on its own
threads: a server frame never waits on the network.

**One difference from the C# build:** the JSON a `get` returns is compact
(`{"a":1}`), where .NET wrote `{ "a" : 1 }`. PAC's parser takes either.

## Build

**Windows:** Rust (rustup) and the Visual Studio 2022 Build Tools (C++).

```
cargo build --release
copy target\release\ghostd_pacdb.dll ..\..\ghostd_pacdb_x64.dll
```

**Linux**, in Docker (WSL Ubuntu); bullseye's older glibc (the .so needs
2.30) runs on Debian 11 and Ubuntu 20.04 onward:

```
docker run --rm -v /mnt/d/Git/jmsb-custom-mod/extensions/ghostd_pacdb:/src:ro -v /tmp/pdout:/out -w /src \
  -e CARGO_TARGET_DIR=/tmp/t rust:1-bullseye \
  sh -c "cargo build --release --locked && cp /tmp/t/release/libghostd_pacdb.so /out/ghostd_pacdb_x64.so"
cp /tmp/pdout/ghostd_pacdb_x64.so /mnt/d/Git/jmsb-custom-mod/
```

Each new Windows build is a new hash: update `tools/dlls.sha256`.

## Pinned (2026-11-02)

Arma unloads the DLL as the game closes, before the process ends, while the
runtime's threads still run; on a hosted game that crashed on quit (Windows:
BEX64 in `ghostd_pacdb_x64.dll_unloaded`, c0000005). The first command that
starts the runtime pins the DLL (`GetModuleHandleExW`, PIN), so the unload
does nothing - as `jmsb_voice` does. Checked outside Arma: after `ping`, five
FreeLibrary calls leave it loaded; without a command, one unloads it.

## Tested (2026-11-01)

Against MongoDB 7 in WSL Docker, called the way Arma calls it (quoted
arguments, the registered callback), Windows DLL and Linux .so:

- `configure`, `ping`, a 9,000-character `put` in three chunks, `get` (two
  chunks back), `get` of a missing key (`empty`), `list`, and the bad calls'
  errors.
- Against the C# build: each read what the other wrote, with the same field
  order and the same BSON number types.

**Not tested:** `mongodb+srv://` (Atlas: DNS and TLS), the HTTP service
backend, in game.
