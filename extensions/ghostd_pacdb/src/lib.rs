//! ghostd_pacdb - the Arma 3 server's side of TAC//PAC's database, in Rust
//! (2026-11-01). A port of DIVINER tools/pacdb/extension/Extension.cs, with
//! the same verbs, answers and callbacks, so addons/pac is unchanged. The C#
//! build (NativeAOT, the .NET MongoDB driver, 28 MB) was flagged by ClamAV and
//! Gridinsoft; this is the Rust MongoDB driver over rustls, nothing packed in.
//!
//! TWO BACKENDS, ONE VOCABULARY. The mod hands over one address
//! (`configure`, from its CBA server setting 'Database'):
//!
//!   mongodb+srv://... / mongodb://...   MongoDB directly (Atlas or any), the
//!                                       database named in the string, else
//!                                       "ghostd"; collection "pac", one
//!                                       document per key, _id = the key.
//!   http://... / https://...            the pacdb service (X-Api-Key).
//!
//! Verbs (RVExtensionArgs): `configure url [key]` -> "ok"; `get key`,
//! `list prefix`, `put.begin key n`, `put.chunk i text`, `put.end`, `ping`
//! -> "queued", the answer then coming through the callback on a worker
//! thread, so a server frame never waits on the network:
//!   get.begin n, get.chunk "i|text" (CHUNK chars each), get.end ok|empty,
//!   get.error why; list [json array]; list.error why; put.end ok;
//!   put.error why; ping "ok VERSION -> address (from where)".
//! A bad call answers "error: ..." with return code 1.
//!
//! SERVER ONLY: no client ever loads it. Before `configure`, the address comes
//! from the server's machine: GHOSTD_PACDB_URL / GHOSTD_PACDB_KEY, else a
//! pacdb.json ({"url", "apiKey"}) in the server's root or beside the DLL.
//!
//! THE NAME IS LOWER CASE: a Linux server looks the file up by the exact name
//! the script gives, and Linux mod folders are often lower-cased in transit.

use std::ffi::{c_char, c_int, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::{Mutex, OnceLock};
use std::time::Duration;

use futures_util::TryStreamExt;
use mongodb::bson::{doc, Bson, DateTime, Document};
use mongodb::options::ClientOptions;
use mongodb::{Client, Collection};
use tokio::runtime::Runtime;

const NAME: &str = "ghostd_pacdb";
const VERSION: &str = env!("CARGO_PKG_VERSION");
/// One get.chunk carries this many characters: well inside Arma's callback.
const CHUNK: usize = 7000;
/// Connect, server selection and HTTP requests give up after this (s).
const TIMEOUT_S: u64 = 15;
/// A connection string with no database names the original one.
const DEFAULT_DB: &str = "ghostd";
const COLLECTION: &str = "pac";
/// The file the server's machine may hold the address in.
const CONFIG_FILE: &str = "pacdb.json";
const ENV_URL: &str = "GHOSTD_PACDB_URL";
const ENV_KEY: &str = "GHOSTD_PACDB_KEY";
const API_KEY_HEADER: &str = "X-Api-Key";
const HTTP_NOT_FOUND: u16 = 404;
/// Return codes of RVExtensionArgs.
const RC_OK: c_int = 0;
const RC_ERROR: c_int = 1;
/// The longest module path asked of Windows (UTF-16 units).
#[cfg(windows)]
const MAX_MODULE_PATH: usize = 1024;

const NOT_CONFIGURED: &str = "not configured: set the CBA server setting 'Database' (Addon Options > Ghosts of Battle PAC > Service) to a mongodb+srv:// connection string (or a pacdb service URL), or GHOSTD_PACDB_URL in the server's environment, or pacdb.json in the server's root";

type Callback = unsafe extern "system" fn(*const c_char, *const c_char, *const c_char) -> c_int;

/// Where the database is, and where that came from.
struct Config {
    url: String,
    key: String,
    configured: bool,
    source: String,
}

static CONFIG: Mutex<Config> = Mutex::new(Config { url: String::new(), key: String::new(), configured: false, source: String::new() });
static CALLBACK: Mutex<Option<Callback>> = Mutex::new(None);
/// The put being assembled: one at a time, which is all the mod ever does.
static PUT: Mutex<Option<(String, Vec<String>)>> = Mutex::new(None);
/// The MongoDB collection, made on first use, for the address it was made for.
static MONGO: tokio::sync::Mutex<Option<(String, Collection<Document>)>> = tokio::sync::Mutex::const_new(None);
static RUNTIME: OnceLock<Runtime> = OnceLock::new();
static HTTP: OnceLock<reqwest::Client> = OnceLock::new();

fn runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        // before the first thread of ours exists (pin)
        #[cfg(windows)]
        pin();
        tokio::runtime::Builder::new_multi_thread().enable_all().build().expect("tokio runtime")
    })
}

/// PINNED (2026-11-02): Arma unloads the DLL (FreeLibrary) as the game
/// closes, before the process ends, while the runtime's threads still run -
/// they then ran into the unmapped code ("BEX64 ... ghostd_pacdb_x64.dll_unloaded
/// ... c0000005" on quit from a hosted game). Pinning keeps the DLL mapped
/// until the process ends, so FreeLibrary is a no-op - as jmsb_voice does.
#[cfg(windows)]
fn pin() {
    #[link(name = "kernel32")]
    unsafe extern "system" {
        fn GetModuleHandleExW(flags: u32, name: *const u16, module: *mut *mut core::ffi::c_void) -> i32;
    }
    const GET_MODULE_HANDLE_EX_FLAG_PIN: u32 = 0x1;
    const GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS: u32 = 0x4;
    let mut module = core::ptr::null_mut();
    let here = pin as *const () as *const u16;
    // SAFETY: an address inside this module and an out pointer of the right type.
    let _ = unsafe { GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_PIN | GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, here, &mut module) };
}

fn http() -> &'static reqwest::Client {
    HTTP.get_or_init(|| {
        reqwest::Client::builder()
            .timeout(Duration::from_secs(TIMEOUT_S))
            .build()
            .expect("http client")
    })
}

// ------------------------------------------------------------------ exports --

/// # Safety
/// Arma passes a writable buffer of `size` bytes.
#[no_mangle]
pub unsafe extern "system" fn RVExtensionVersion(output: *mut c_char, size: c_int) {
    write(output, size, VERSION);
}

/// # Safety
/// Arma passes its callback, valid for the process's life.
#[no_mangle]
pub unsafe extern "system" fn RVExtensionRegisterCallback(callback: Callback) {
    if let Ok(mut cb) = CALLBACK.lock() {
        *cb = Some(callback);
    }
}

/// # Safety
/// Arma passes a writable buffer of `size` bytes and a C string.
#[no_mangle]
pub unsafe extern "system" fn RVExtension(output: *mut c_char, size: c_int, function: *const c_char) {
    let answer = if c_str(function) == "version" { VERSION } else { "use RVExtensionArgs" };
    write(output, size, answer);
}

/// # Safety
/// Arma passes a writable buffer of `size` bytes, a C string, and `argc`
/// C strings.
#[no_mangle]
pub unsafe extern "system" fn RVExtensionArgs(
    output: *mut c_char,
    size: c_int,
    function: *const c_char,
    argv: *const *const c_char,
    argc: c_int,
) -> c_int {
    let function = c_str(function);
    let args: Vec<String> = (0..usize::try_from(argc).unwrap_or(0))
        .map(|i| unquote(&c_str(*argv.add(i))))
        .collect();
    // a panic escaping an extension call would take the server down
    let (text, code) = catch_unwind(AssertUnwindSafe(|| call(&function, args))).unwrap_or_else(|_| ("error: panic".to_owned(), RC_ERROR));
    write(output, size, &text);
    code
}

// --------------------------------------------------------------------- calls --

fn call(function: &str, args: Vec<String>) -> (String, c_int) {
    configure_from_machine();
    let fail = |why: &str| (format!("error: {why}"), RC_ERROR);
    match function {
        "ping" => {
            runtime().spawn(async { send("ping", &ping_text()) });
        }
        // THE MOD HANDS THE ADDRESS OVER from its CBA server setting, which a
        // rented game server can take where it cannot take a file or an
        // environment variable. Wins over what the machine had.
        "configure" => {
            let Some(url) = args.first().filter(|u| !u.is_empty()) else {
                return fail("configure needs url [key]");
            };
            let mut c = CONFIG.lock().unwrap();
            c.url = url.trim_end_matches('/').to_owned();
            c.key = args.get(1).cloned().unwrap_or_default();
            c.configured = true;
            c.source = "the mod's CBA setting".to_owned();
            return ("ok".to_owned(), RC_OK);
        }
        "get" => {
            let Some(key) = args.first().cloned() else { return fail("get needs a key") };
            runtime().spawn(get(key));
        }
        "list" => {
            let prefix = args.first().cloned().unwrap_or_default();
            runtime().spawn(list(prefix));
        }
        "put.begin" => {
            let (Some(key), Some(Ok(n))) = (args.first(), args.get(1).map(|n| n.parse::<usize>())) else {
                return fail("put.begin needs key, n");
            };
            *PUT.lock().unwrap() = Some((key.clone(), vec![String::new(); n]));
        }
        "put.chunk" => {
            let (Some(Ok(i)), Some(text)) = (args.first().map(|i| i.parse::<usize>()), args.get(1)) else {
                return fail("put.chunk needs i, text");
            };
            let mut put = PUT.lock().unwrap();
            match put.as_mut().and_then(|(_, chunks)| chunks.get_mut(i)) {
                Some(slot) => *slot = text.clone(),
                None => return fail("put.chunk out of order"),
            }
        }
        "put.end" => {
            let Some((key, chunks)) = PUT.lock().unwrap().take() else {
                return fail("put.end without put.begin");
            };
            runtime().spawn(put(key, chunks.concat()));
        }
        other => return fail(&format!("unknown function {other}")),
    }
    ("queued".to_owned(), RC_OK)
}

/// The address as it stands, without the password, and where it came from.
fn ping_text() -> String {
    let c = CONFIG.lock().unwrap();
    if c.configured {
        format!("ok {VERSION} -> {} (from {})", describe(&c.url), c.source)
    } else {
        format!("ok {VERSION} (NOT CONFIGURED: set the CBA setting 'Database' to a mongodb+srv:// connection string, or a pacdb service URL)")
    }
}

fn is_mongo(url: &str) -> bool {
    let lower = url.to_ascii_lowercase();
    lower.starts_with("mongodb://") || lower.starts_with("mongodb+srv://")
}

/// The address without its password, for the log.
fn describe(url: &str) -> String {
    if !is_mongo(url) {
        return url.to_owned();
    }
    let scheme = url.find("://").map(|i| i + 3).unwrap_or(0);
    match url.find('@') {
        Some(at) if at > scheme => format!("{}...{} (direct)", &url[..scheme], &url[at..]),
        _ => format!("{url} (direct)"),
    }
}

/// The address and key, or None when nothing configured one.
fn target() -> Option<(String, String)> {
    let c = CONFIG.lock().unwrap();
    c.configured.then(|| (c.url.clone(), c.key.clone()))
}

/// The "pac" collection for this address, made once per address.
async fn mongo(url: &str) -> Result<Collection<Document>, String> {
    let mut slot = MONGO.lock().await;
    if let Some((made_for, collection)) = slot.as_ref() {
        if made_for == url {
            return Ok(collection.clone());
        }
    }
    let mut options = ClientOptions::parse(url).await.map_err(|e| e.to_string())?;
    options.connect_timeout = Some(Duration::from_secs(TIMEOUT_S));
    options.server_selection_timeout = Some(Duration::from_secs(TIMEOUT_S));
    // THE DATABASE IS THE CONNECTION STRING'S (2026-10-08): a second unit on the
    // same cluster keeps its own. None named is the original single-unit setup.
    let db = options.default_database.clone().filter(|d| !d.is_empty()).unwrap_or_else(|| DEFAULT_DB.to_owned());
    let client = Client::with_options(options).map_err(|e| e.to_string())?;
    let collection = client.database(&db).collection::<Document>(COLLECTION);
    *slot = Some((url.to_owned(), collection.clone()));
    Ok(collection)
}

async fn get(key: String) {
    match get_text(&key).await {
        Ok(None) => send("get.end", "empty"),
        Ok(Some(text)) => {
            let chars: Vec<char> = text.chars().collect();
            let chunks: Vec<String> = chars.chunks(CHUNK).map(|c| c.iter().collect()).collect();
            send("get.begin", &chunks.len().to_string());
            for (i, chunk) in chunks.iter().enumerate() {
                send("get.chunk", &format!("{i}|{chunk}"));
            }
            send("get.end", "ok");
        }
        Err(e) => send("get.error", &e),
    }
}

async fn get_text(key: &str) -> Result<Option<String>, String> {
    let (url, api_key) = target().ok_or(NOT_CONFIGURED)?;
    if is_mongo(&url) {
        let Some(mut doc) = mongo(&url).await?.find_one(doc! { "_id": key }).await.map_err(|e| e.to_string())? else {
            return Ok(None);
        };
        // documents written before fields held their JSON as one string
        if let Ok(legacy) = doc.get_str("json") {
            return Ok(Some(legacy.to_owned()));
        }
        doc.remove("_id");
        doc.remove("updatedAt");
        return Ok(Some(Bson::Document(doc).into_relaxed_extjson().to_string()));
    }
    let res = http()
        .get(format!("{url}/pac/{}", escape_data(key)))
        .header(API_KEY_HEADER, api_key)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if res.status().as_u16() == HTTP_NOT_FOUND {
        return Ok(None);
    }
    if !res.status().is_success() {
        return Err(format!("HTTP {}", res.status().as_u16()));
    }
    res.text().await.map(Some).map_err(|e| e.to_string())
}

/// The keys under a prefix, as a JSON array in one callback (a unit's role
/// and order lists are a few dozen short strings at most).
async fn list(prefix: String) {
    match list_text(&prefix).await {
        Ok(json) => send("list", &json),
        Err(e) => send("list.error", &e),
    }
}

async fn list_text(prefix: &str) -> Result<String, String> {
    let (url, api_key) = target().ok_or(NOT_CONFIGURED)?;
    if is_mongo(&url) {
        let filter = doc! { "_id": { "$regex": format!("^{}", escape_regex(prefix)) } };
        let mut cursor = mongo(&url)
            .await?
            .find(filter)
            .projection(doc! { "_id": 1 })
            .await
            .map_err(|e| e.to_string())?;
        let mut keys = Vec::new();
        while let Some(d) = cursor.try_next().await.map_err(|e| e.to_string())? {
            if let Ok(id) = d.get_str("_id") {
                keys.push(id.to_owned());
            }
        }
        keys.sort();
        return serde_json::to_string(&keys).map_err(|e| e.to_string());
    }
    let res = http()
        .get(format!("{url}/pac?prefix={}", escape_data(prefix)))
        .header(API_KEY_HEADER, api_key)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        return Err(format!("HTTP {}", res.status().as_u16()));
    }
    res.text().await.map_err(|e| e.to_string())
}

async fn put(key: String, json: String) {
    match put_doc(&key, json).await {
        Ok(()) => send("put.end", "ok"),
        Err(e) => send("put.error", &e),
    }
}

async fn put_doc(key: &str, json: String) -> Result<(), String> {
    let (url, api_key) = target().ok_or(NOT_CONFIGURED)?;
    if is_mongo(&url) {
        // REAL FIELDS, the way the service stores them: the JSON as BSON, _id
        // the key first, updatedAt the write - the site edits it as a document.
        let value: serde_json::Value = serde_json::from_str(&json).map_err(|e| e.to_string())?;
        let Bson::Document(mut fields) = Bson::try_from(value).map_err(|e| e.to_string())? else {
            return Err("the document is not a JSON object".to_owned());
        };
        fields.remove("_id");
        fields.remove("updatedAt");
        let mut doc = doc! { "_id": key };
        doc.extend(fields);
        doc.insert("updatedAt", DateTime::now());
        mongo(&url)
            .await?
            .replace_one(doc! { "_id": key }, doc)
            .upsert(true)
            .await
            .map_err(|e| e.to_string())?;
        return Ok(());
    }
    let res = http()
        .put(format!("{url}/pac/{}", escape_data(key)))
        .header(API_KEY_HEADER, api_key)
        .header(reqwest::header::CONTENT_TYPE, "application/json; charset=utf-8")
        .body(json)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    if res.status().is_success() {
        Ok(())
    } else {
        Err(format!("HTTP {}", res.status().as_u16()))
    }
}

// ------------------------------------------------------------------ plumbing --

/// NOTHING ABOUT THE SERVER IS IN THE MOD. Before the mod's `configure`, the
/// address comes from the server's machine: the environment first, then a
/// pacdb.json beside the server's exe, in its working directory, or beside
/// this library.
fn configure_from_machine() {
    let mut c = CONFIG.lock().unwrap();
    if c.configured {
        return;
    }
    let env = |name: &str| std::env::var(name).unwrap_or_default();
    let url = env(ENV_URL);
    if !url.is_empty() {
        c.url = url.trim_end_matches('/').to_owned();
        c.key = env(ENV_KEY);
        c.configured = true;
        c.source = "the environment".to_owned();
        return;
    }
    let dirs = [
        std::env::current_exe().ok().and_then(|p| p.parent().map(|d| d.to_path_buf())),
        std::env::current_dir().ok(),
        own_directory(),
    ];
    let Some(path) = dirs.into_iter().flatten().map(|d| d.join(CONFIG_FILE)).find(|p| p.is_file()) else {
        return;
    };
    let Ok(file) = std::fs::read_to_string(&path) else { return };
    let Ok(json) = serde_json::from_str::<serde_json::Value>(&file) else { return };
    let text = |field: &str| json.get(field).and_then(|v| v.as_str()).unwrap_or_default().to_owned();
    c.url = text("url").trim_end_matches('/').to_owned();
    c.key = text("apiKey");
    // a key from the environment still wins over one in the file
    let env_key = env(ENV_KEY);
    if !env_key.is_empty() {
        c.key = env_key;
    }
    c.configured = !c.url.is_empty();
    if c.configured {
        c.source = format!("{CONFIG_FILE} at {}", path.display());
    }
}

/// Where this library is - the mod folder, where Arma loads extensions from.
/// Windows only: on Linux the server's root is the place for pacdb.json.
#[cfg(windows)]
fn own_directory() -> Option<std::path::PathBuf> {
    #[link(name = "kernel32")]
    unsafe extern "system" {
        fn GetModuleHandleW(name: *const u16) -> *mut core::ffi::c_void;
        fn GetModuleFileNameW(module: *mut core::ffi::c_void, buffer: *mut u16, size: u32) -> u32;
    }
    for name in ["ghostd_pacdb_x64.dll", "ghostd_pacdb.dll"] {
        let wide: Vec<u16> = name.encode_utf16().chain(std::iter::once(0)).collect();
        let mut buffer = vec![0u16; MAX_MODULE_PATH];
        // SAFETY: a NUL-terminated name, and a buffer of the size given.
        let n = unsafe {
            let module = GetModuleHandleW(wide.as_ptr());
            if module.is_null() {
                continue;
            }
            GetModuleFileNameW(module, buffer.as_mut_ptr(), MAX_MODULE_PATH as u32)
        };
        if n > 0 {
            let path = std::path::PathBuf::from(String::from_utf16_lossy(&buffer[..n as usize]));
            return path.parent().map(|d| d.to_path_buf());
        }
    }
    None
}

#[cfg(not(windows))]
fn own_directory() -> Option<std::path::PathBuf> {
    None
}

/// One answer to Arma, through the callback it registered.
fn send(function: &str, data: &str) {
    let Some(callback) = *CALLBACK.lock().unwrap() else { return };
    let (Ok(name), Ok(function), Ok(data)) = (CString::new(NAME), CString::new(function), CString::new(data.replace('\0', ""))) else {
        return;
    };
    // SAFETY: Arma's own callback, with three NUL-terminated strings that
    // live until it returns.
    unsafe {
        callback(name.as_ptr(), function.as_ptr(), data.as_ptr());
    }
}

/// # Safety
/// `s` is null or a NUL-terminated string.
unsafe fn c_str(s: *const c_char) -> String {
    if s.is_null() {
        return String::new();
    }
    CStr::from_ptr(s).to_string_lossy().into_owned()
}

/// Arma hands string args wrapped in quotes with inner quotes doubled.
fn unquote(s: &str) -> String {
    if s.len() >= 2 && s.starts_with('"') && s.ends_with('"') {
        s[1..s.len() - 1].replace("\"\"", "\"")
    } else {
        s.to_owned()
    }
}

/// # Safety
/// `output` is a writable buffer of `size` bytes.
unsafe fn write(output: *mut c_char, size: c_int, text: &str) {
    let Ok(size) = usize::try_from(size) else { return };
    if output.is_null() || size == 0 {
        return;
    }
    let bytes = text.as_bytes();
    let n = bytes.len().min(size - 1);
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.cast::<u8>(), n);
    *output.add(n) = 0;
}

/// A key as one URL path or query part: every byte but the unreserved ones
/// %-encoded, as .NET's Uri.EscapeDataString does.
fn escape_data(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => (b as char).to_string(),
            _ => format!("%{b:02X}"),
        })
        .collect()
}

/// A prefix as a literal inside a regular expression.
fn escape_regex(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for ch in s.chars() {
        if "\\^$.|?*+()[]{}-#".contains(ch) {
            out.push('\\');
        }
        out.push(ch);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unquoting() {
        assert_eq!(unquote("\"a\"\"b\""), "a\"b");
        assert_eq!(unquote("5"), "5");
    }

    #[test]
    fn describing() {
        assert_eq!(describe("mongodb+srv://u:pw@host/db"), "mongodb+srv://...@host/db (direct)");
        assert_eq!(describe("http://svc:8080"), "http://svc:8080");
    }

    #[test]
    fn escaping() {
        assert_eq!(escape_data("frame work/a b"), "frame%20work%2Fa%20b");
        assert_eq!(escape_regex("a.b[c]"), "a\\.b\\[c\\]");
    }

    #[test]
    fn calls_answer_like_the_csharp_one() {
        assert_eq!(call("put.begin", vec!["k".into(), "2".into()]), ("queued".to_owned(), RC_OK));
        assert_eq!(call("put.chunk", vec!["5".into(), "x".into()]).1, RC_ERROR);
        assert_eq!(call("nope", vec![]).1, RC_ERROR);
        assert_eq!(call("configure", vec![]).1, RC_ERROR);
    }
}
