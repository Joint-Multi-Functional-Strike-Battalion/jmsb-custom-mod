//! jmsb_voice: the JMSB mod's Arma 3 extension for radio voice over LiveKit
//! (docs/DESIGN_VOICE_LIVEKIT.md). SQF decides who hears whom and how well;
//! this carries the audio.
//!
//! Commands (`"jmsb_voice" callExtension [command, [args]]`):
//!   version                        the extension's version
//!   token   [key, secret, room, identity, name] SERVER: a join token; an
//!                                  empty key or secret is read from the
//!                                  server's JMSB_LIVEKIT_KEY / _SECRET
//!   connect [url, token]           CLIENT: join; events arrive as callbacks
//!   talk    [on]                   open / close the microphone
//!   subscribe [identity, on]       receive that speaker or not (auto-subscribe
//!                                  is off: nobody is received until asked)
//!   speaker [identity, gain, pan]  one speaker's loudness 0..1 and ear -1..1
//!                                  (a speaker not set yet is silent)
//!   disconnect                     leave
//!   devices                        [[microphones], [speakers]] by name
//!   device  [input, output]        use these (part of the name; "" = the
//!                                  Windows default), now (off Arma's thread)
//!                                  and at every connect
//!
//! Callbacks (ExtensionCallback, name "jmsb_voice"): connected, disconnected
//! [reason], joined [identity], left [identity], speaking [identities], nomic
//! [text] (listening only), error [text].
//!
//! Built without the "client" feature (the Linux server's .so) it has only
//! version and token.

#[cfg(feature = "client")]
pub mod audio;
#[cfg(feature = "client")]
pub mod session;
pub mod token;

use arma_rs::{arma, Extension};

/// THE EXTENSION'S OWN LOG: %LOCALAPPDATA%\Arma 3\jmsb_voice.log, started
/// afresh each game start - which devices opened, each connect and close,
/// and the last thing done before the game ended (the crash on exit,
/// 2026-10-31, left no dump and no RPT line to go on).
mod logfile {
    use std::fs::{File, OpenOptions};
    use std::io::Write;
    use std::sync::Mutex;

    struct FileLog(Mutex<File>);

    impl log::Log for FileLog {
        fn enabled(&self, m: &log::Metadata) -> bool {
            m.level() <= log::Level::Info
        }
        fn log(&self, r: &log::Record) {
            if !self.enabled(r.metadata()) {
                return;
            }
            if let Ok(mut f) = self.0.lock() {
                let _ = writeln!(f, "{} {:<5} {}: {}", stamp(), r.level(), r.target(), r.args());
                let _ = f.flush();
            }
        }
        fn flush(&self) {}
    }

    fn stamp() -> String {
        let s = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
        format!("{:02}:{:02}:{:02}", (s / 3600) % 24, (s / 60) % 60, s % 60)
    }

    pub fn start() {
        let Ok(base) = std::env::var("LOCALAPPDATA") else { return };
        let path = std::path::Path::new(&base).join("Arma 3").join("jmsb_voice.log");
        let Ok(file) = OpenOptions::new().create(true).write(true).truncate(true).open(&path) else { return };
        if log::set_boxed_logger(Box::new(FileLog(Mutex::new(file)))).is_ok() {
            log::set_max_level(log::LevelFilter::Info);
            log::info!("jmsb_voice {} (times are UTC)", env!("CARGO_PKG_VERSION"));
        }
    }
}

#[arma]
fn init() -> Extension {
    logfile::start();
    let ext = Extension::build()
        .version(env!("CARGO_PKG_VERSION").to_string())
        .command("version", version)
        .command("token", token);
    #[cfg(feature = "client")]
    let ext = client::commands(ext);
    ext.finish()
}

fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

/// The server's own environment: where the API key and secret belong. CBA
/// copies every server setting to every client, so a secret set there is in
/// every player's game (review S9, R4).
const ENV_KEY: &str = "JMSB_LIVEKIT_KEY";
const ENV_SECRET: &str = "JMSB_LIVEKIT_SECRET";

/// The key and secret as SQF passes them (adapter_livekit's CBA settings);
/// each one passed empty is read from the server's environment
/// (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET, the Pelican egg's variables), per
/// call. Still empty: an error, no token.
fn token(key: String, secret: String, room: String, identity: String, name: String) -> Result<String, String> {
    let from_env = |given: String, var: &str| {
        if given.trim().is_empty() {
            std::env::var(var).unwrap_or_default().trim().to_owned()
        } else {
            given
        }
    };
    let (key, secret) = (from_env(key, ENV_KEY), from_env(secret, ENV_SECRET));
    if key.is_empty() || secret.is_empty() {
        return Err(format!("API key or secret not set (CBA setting or {ENV_KEY} / {ENV_SECRET})"));
    }
    token::mint(&key, &secret, &room, &identity, &name)
}

/// The player's side: one session in one room.
///
/// Arma calls these on its own thread. Each runs inside the extension's
/// runtime (LiveKit starts tasks when the microphone mutes or unmutes), and a
/// panic is caught here: one escaping an extension call aborts the game.
#[cfg(feature = "client")]
mod client {
    use std::panic::{catch_unwind, AssertUnwindSafe};
    use std::sync::atomic::Ordering;
    use std::sync::{Mutex, OnceLock};

    use arma_rs::{Context, ExtensionBuilder};
    use tokio::runtime::Runtime;
    use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};

    use crate::audio::Devices;
    use crate::session::{Event, Options, Session};

    const CALLBACK: &str = "jmsb_voice";

    /// THE ONE SESSION, and what belongs to it, under one lock so a connect
    /// finishing and a `disconnect` arriving cannot cross:
    /// - `generation` goes up with every `connect` and every `disconnect`. A
    ///   connect that finds it moved on when it is done was overtaken: it
    ///   closes what it made and reports nothing.
    /// - `callbacks` is the task that hands the session's events to Arma.
    ///   Stopped before a session is closed, so nothing calls back into the
    ///   engine after `disconnect` - the mission's end disconnects, and a
    ///   callback into an engine that is shutting down crashed the game on
    ///   exit (2026-10-31).
    struct Slot {
        generation: u64,
        session: Option<Session>,
        callbacks: Option<tokio::task::JoinHandle<()>>,
    }

    static RUNTIME: OnceLock<Runtime> = OnceLock::new();
    static SLOT: Mutex<Slot> = Mutex::new(Slot { generation: 0, session: None, callbacks: None });
    /// ONE CONNECT AT A TIME: a second waits for the first to finish (or be
    /// overtaken) before it closes the old session and joins, so two sessions
    /// under one identity never run together - the server would kick one, and
    /// the rejoin kick the other.
    static CONNECTING: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());
    /// The microphone and speakers SQF named (`device`), used by every connect.
    static DEVICE_CHOICE: Mutex<(String, String)> = Mutex::new((String::new(), String::new()));
    /// Goes up with every `device`: a reopen overtaken by a newer one drops
    /// what it opened.
    static REOPEN: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    /// Whether a room was ever joined this process: then libwebrtc's and the
    /// runtime's threads exist, and the process's end must not unwind them.
    pub static EVER_CONNECTED: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

    /// Every callback goes through this one task, which owns the context.
    fn spawn_callbacks(ctx: Context, mut rx: UnboundedReceiver<Event>) -> tokio::task::JoinHandle<()> {
        tokio::spawn(async move {
            while let Some(event) = rx.recv().await {
                let sent = match event {
                    Event::Connected => ctx.callback_null(CALLBACK, "connected"),
                    Event::Disconnected(why) => ctx.callback_data(CALLBACK, "disconnected", Some(why)),
                    Event::Joined(id) => ctx.callback_data(CALLBACK, "joined", Some(id)),
                    Event::Left(id) => ctx.callback_data(CALLBACK, "left", Some(id)),
                    Event::Speaking(ids) => ctx.callback_data(CALLBACK, "speaking", Some(ids)),
                    Event::NoMic(e) => ctx.callback_data(CALLBACK, "nomic", Some(e)),
                    Event::Error(e) => ctx.callback_data(CALLBACK, "error", Some(e)),
                };
                if let Err(e) = sent {
                    log::warn!("callback: {e:?}");
                }
            }
        })
    }

    fn runtime() -> &'static Runtime {
        RUNTIME.get_or_init(|| {
            tokio::runtime::Builder::new_multi_thread()
                .worker_threads(2)
                .enable_all()
                .build()
                .expect("tokio runtime")
        })
    }

    /// Runs a command inside the runtime; a panic becomes `fallback`.
    fn guarded<R>(fallback: R, f: impl FnOnce() -> R) -> R {
        let _inside = runtime().enter();
        catch_unwind(AssertUnwindSafe(f)).unwrap_or_else(|_| {
            log::error!("command panicked");
            fallback
        })
    }

    pub fn commands(ext: ExtensionBuilder) -> ExtensionBuilder {
        ext.command("connect", connect)
            .command("talk", talk)
            .command("subscribe", subscribe)
            .command("speaker", speaker)
            .command("disconnect", disconnect)
            .command("devices", devices)
            .command("device", device)
    }

    fn connect(ctx: Context, url: String, token: String) -> &'static str {
        guarded("error", || connect_spawn(ctx, url, token))
    }

    fn connect_spawn(ctx: Context, url: String, token: String) -> &'static str {
        let generation = {
            let mut slot = SLOT.lock().unwrap();
            slot.generation += 1;
            if let Some(task) = slot.callbacks.take() {
                task.abort();
            }
            slot.generation
        };
        EVER_CONNECTED.store(true, Ordering::Relaxed);
        log::info!("connect {url}");
        runtime().spawn(async move {
            let _one = CONNECTING.lock().await;
            let current = |slot: &Slot| slot.generation == generation;
            // The old session goes first, unless a newer connect or a
            // disconnect has already taken over.
            let old = {
                let mut slot = SLOT.lock().unwrap();
                if !current(&slot) {
                    return;
                }
                slot.session.take()
            };
            if let Some(old) = old {
                old.close().await;
            }
            let (tx, rx) = unbounded_channel::<Event>();
            let (input, output) = DEVICE_CHOICE.lock().unwrap().clone();
            let opts = Options { input, output, ..Options::default() };
            let result = Session::connect(&url, &token, tx.clone(), opts).await;
            // Kept only if still the one wanted; its events wait in the
            // channel until the callback task starts, so none are lost.
            let overtaken = {
                let mut slot = SLOT.lock().unwrap();
                if current(&slot) {
                    slot.callbacks = Some(spawn_callbacks(ctx, rx));
                    match result {
                        Ok(session) => slot.session = Some(session),
                        Err(e) => {
                            let _ = tx.send(Event::Error(e));
                        }
                    }
                    None
                } else {
                    result.ok()
                }
            };
            if let Some(session) = overtaken {
                log::info!("a connect was overtaken: its session closed unused");
                session.close().await;
            }
        });
        "ok"
    }

    /// Runs `f` on the live session; false when there is none.
    fn with_session(f: impl FnOnce(&Session)) -> bool {
        guarded(false, || match SLOT.lock().unwrap().session.as_ref() {
            Some(s) => {
                f(s);
                true
            }
            None => false,
        })
    }

    fn talk(on: bool) -> bool {
        with_session(|s| s.set_talking(on))
    }

    fn subscribe(identity: String, on: bool) -> bool {
        with_session(|s| s.subscribe(&identity, on))
    }

    fn speaker(identity: String, gain: f32, pan: f32) -> bool {
        with_session(|s| s.set_speaker(&identity, gain, pan))
    }

    fn disconnect() -> &'static str {
        guarded("error", || {
            log::info!("disconnect");
            let (old, callbacks) = {
                let mut slot = SLOT.lock().unwrap();
                slot.generation += 1;
                (slot.session.take(), slot.callbacks.take())
            };
            if let Some(task) = callbacks {
                task.abort();
            }
            if let Some(old) = old {
                runtime().spawn(old.close());
            }
            "ok"
        })
    }

    /// [[microphones], [speakers]] as Windows names them.
    fn devices() -> (Vec<String>, Vec<String>) {
        guarded((Vec::new(), Vec::new()), crate::audio::list)
    }

    /// The devices to use, by part of their names ("" = the default): kept
    /// for every connect to come, and when a session is live opened now OFF
    /// ARMA'S THREAD (opening a device can take a second): "reopening", and a
    /// failure comes back as an `error` callback, no microphone as `nomic`.
    fn device(input: String, output: String) -> Result<&'static str, String> {
        guarded(Err("error".to_string()), || {
            *DEVICE_CHOICE.lock().unwrap() = (input.clone(), output.clone());
            let parts = {
                let slot = SLOT.lock().unwrap();
                slot.session.as_ref().map(|s| (slot.generation, s.device_parts()))
            };
            let Some((generation, (mixer, mic_tx, events))) = parts else {
                return Ok("kept");
            };
            let reopen = REOPEN.fetch_add(1, Ordering::Relaxed) + 1;
            runtime().spawn_blocking(move || match Devices::open(mixer, mic_tx, &input, &output) {
                Ok((devices, mic_error)) => {
                    let old = {
                        let mut slot = SLOT.lock().unwrap();
                        let wanted = slot.generation == generation && REOPEN.load(Ordering::Relaxed) == reopen;
                        match slot.session.as_mut() {
                            Some(s) if wanted => Some(s.swap_devices(devices)),
                            _ => None,
                        }
                    };
                    // the old streams' thread is joined here, not under the lock
                    drop(old);
                    if let Some(e) = mic_error {
                        let _ = events.send(Event::NoMic(e));
                    }
                }
                Err(e) => {
                    log::warn!("device: {e}");
                    let _ = events.send(Event::Error(format!("speakers: {e}")));
                }
            });
            Ok("reopening")
        })
    }
}

/// THE PROCESS'S END. Once a room was joined, libwebrtc's threads, the
/// runtime's and the audio thread exist, and C++ statics in libwebrtc have
/// destructors the CRT runs when the DLL is detached at exit - after Windows
/// has already killed those threads. That unwinding is where the game
/// crashed on exit (2026-10-31, twice: no dump, the RPT ending in the
/// engine's own shutdown lines). At that point the engine has finished its
/// work - the profile is saved, the RPT written - so the process is ended
/// here and nothing of ours is unwound. Done only when a room was joined;
/// a game that never used the voice detaches as it always did.
///
/// Nothing else runs here - no log line: this is under the loader lock,
/// after Windows killed every other thread (the logger's mutex may be held
/// by one of them, which would hang the exit). It also skips the other
/// DLLs' detach. A stopgap: the clean way is to shut the runtime and
/// libwebrtc down at the mission's end, while their threads still live
/// (extensions/jmsb_voice README, "The process's end").
#[cfg(all(windows, feature = "client"))]
mod exit {
    use std::sync::atomic::Ordering;

    #[link(name = "kernel32")]
    unsafe extern "system" {
        fn GetCurrentProcess() -> isize;
        fn TerminateProcess(process: isize, code: u32) -> i32;
    }

    const DLL_PROCESS_DETACH: u32 = 0;

    #[unsafe(no_mangle)]
    #[allow(non_snake_case)]
    pub extern "system" fn DllMain(_module: *mut core::ffi::c_void, reason: u32, reserved: *mut core::ffi::c_void) -> i32 {
        if reason == DLL_PROCESS_DETACH && !reserved.is_null() && crate::client::EVER_CONNECTED.load(Ordering::Relaxed) {
            unsafe {
                TerminateProcess(GetCurrentProcess(), 0);
            }
        }
        1
    }
}
