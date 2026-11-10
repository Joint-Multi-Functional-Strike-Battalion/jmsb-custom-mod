//! Phase 1 test (docs/DESIGN_VOICE_LIVEKIT.md "Phases"): two machines join a
//! room and hear each other, with no Arma. The same session and audio code
//! the extension uses.
//!
//!   voicetest --url ws://HOST:7880 --key KEY --secret SECRET [--room R] [--name N]
//!   voicetest --url mumble://HOST:64738 [--password P] [--echo] [--room R] [--name N]
//!             [--open] [--tone] [--quiet] [--stats]
//!
//! Enter toggles the microphone (push-to-talk as a toggle); --open starts it
//! open. "q" and Enter quits. Every speaker who joins is subscribed and plays
//! centred at full volume (the extension itself starts them unsubscribed and
//! silent);
//! "pan NAME -1..1" and "gain NAME 0..1" move one, to hear the mixer work.
//! --tone sends a 440 Hz tone instead of the microphone (not opened);
//! --quiet plays nothing; --stats prints what each speaker has sent every
//! 2 s - together, a check that audio flows with nobody talking.

use std::io::BufRead;

use jmsb_voice::session::{Event, Options, Session};
use jmsb_voice::token;

fn arg(args: &[String], name: &str) -> Option<String> {
    args.iter().position(|a| a == name).and_then(|i| args.get(i + 1)).cloned()
}

/// --log: the extension's own log lines (what the DLL writes to its log
/// file in game) on stderr, from this crate only.
struct StderrLog;

impl log::Log for StderrLog {
    fn enabled(&self, m: &log::Metadata) -> bool {
        m.level() <= log::Level::Info && m.target().starts_with("jmsb_voice")
    }
    fn log(&self, r: &log::Record) {
        if self.enabled(r.metadata()) {
            eprintln!("  log {} {}: {}", r.level(), r.target(), r.args());
        }
    }
    fn flush(&self) {}
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--log") && log::set_boxed_logger(Box::new(StderrLog)).is_ok() {
        log::set_max_level(log::LevelFilter::Info);
    }
    let usage = || {
        eprintln!("usage: voicetest --url ws://HOST:7880 --key KEY --secret SECRET [--room R] [--name N] [--open]");
        eprintln!("       voicetest --url mumble://HOST:64738 [--password P] [--echo] [--room R] [--name N] [--open]");
        std::process::exit(2);
    };
    let Some(url) = arg(&args, "--url") else { usage() };
    let room = arg(&args, "--room").unwrap_or_else(|| "jmsb-test".to_owned());
    let name = arg(&args, "--name")
        .or_else(|| std::env::var("COMPUTERNAME").ok())
        .unwrap_or_else(|| "tester".to_owned());
    // Mumble: the name and room go in the address, the token is the
    // server's password; --echo uses the server's loopback.
    let (url, jwt) = if let Some(server) = url.strip_prefix("mumble://") {
        let echo = if args.iter().any(|a| a == "--echo") { "?echo" } else { "" };
        (format!("mumble://{name}@{server}/{room}{echo}"), arg(&args, "--password").unwrap_or_default())
    } else {
        let (Some(key), Some(secret)) = (arg(&args, "--key"), arg(&args, "--secret")) else { usage() };
        match token::mint(&key, &secret, &room, &name, &name) {
            Ok(t) => (url, t),
            Err(e) => {
                eprintln!("token: {e}");
                std::process::exit(1);
            }
        }
    };

    // Speakers start silent and unsubscribed (Arma's SQF decides who hears
    // whom); here everyone who joins is received at full volume.
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<Event>();
    let (joined_tx, mut joined_rx) = tokio::sync::mpsc::unbounded_channel::<String>();
    tokio::spawn(async move {
        while let Some(event) = rx.recv().await {
            println!("< {event:?}");
            if let Event::Joined(id) = event {
                let _ = joined_tx.send(id);
            }
        }
    });

    let flag = |f: &str| args.iter().any(|a| a == f);
    let opts = Options { tone: flag("--tone"), ..Default::default() };
    let session = match Session::connect(&url, &jwt, tx, opts).await {
        Ok(s) => s,
        Err(e) => {
            eprintln!("connect: {e}");
            std::process::exit(1);
        }
    };
    let mut open = flag("--open");
    session.set_talking(open);
    if flag("--quiet") {
        session.set_master(0.0);
    }
    let mut stats = tokio::time::interval(std::time::Duration::from_secs(2));
    let show_stats = flag("--stats");
    println!("in room {room} as {name}. Microphone {}. Enter toggles, q quits.", if open { "OPEN" } else { "closed" });

    let (line_tx, mut line_rx) = tokio::sync::mpsc::unbounded_channel::<String>();
    std::thread::spawn(move || {
        for line in std::io::stdin().lock().lines().map_while(Result::ok) {
            if line_tx.send(line).is_err() {
                break;
            }
        }
    });
    loop {
        let line = tokio::select! {
            line = line_rx.recv() => match line {
                Some(line) => line,
                None => break,
            },
            Some(id) = joined_rx.recv() => {
                session.subscribe(&id, true);
                session.set_speaker(&id, 1.0, 0.0);
                continue;
            }
            _ = stats.tick() => {
                if show_stats {
                    println!("received {:?}", session.received());
                }
                continue;
            }
        };
        let words: Vec<&str> = line.split_whitespace().collect();
        match words.as_slice() {
            ["q"] => break,
            ["pan", id, v] => session.set_speaker(id, 1.0, v.parse().unwrap_or(0.0)),
            ["gain", id, v] => session.set_speaker(id, v.parse().unwrap_or(1.0), 0.0),
            _ => {
                open = !open;
                session.set_talking(open);
                println!("microphone {}", if open { "OPEN" } else { "closed" });
            }
        }
    }
    session.close().await;
}
