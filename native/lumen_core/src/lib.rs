//! Lumen Rise launch-fork gate, native side (dart:ffi, C ABI).
//!
//! Dart composes the attribution body and hands the compact JSON here. This
//! crate owns everything the Dart AOT image must not carry in the clear:
//!   * the relay endpoint URL and veil secret (obfuscated, decoded per call),
//!   * the schema-4 envelope codec (`leaf/salt/body/mac`, HMAC-SHA256 keystream
//!     with the `lr-ks-v1` / `lr-mac-v1` domain tags, little-endian counter,
//!     standard base64, 12-byte tag),
//!   * the HTTPS POST to the relay.
//! It returns the config's answer JSON verbatim; Dart maps it to a Verdict.

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::time::Duration;

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

// ── Obfuscated wire constants: byte ^ SALT[i%24] ^ ((i*0x1F)&0xFF) ──────────
const OBF: [u8; 24] = [
    0xA3, 0x8C, 0xD4, 0xFF, 0x08, 0x11, 0x46, 0xE8, 0x38, 0xEC, 0x21, 0x0E, 0xFB, 0x1F, 0xF1, 0x6A,
    0xAA, 0x4D, 0xE9, 0xEB, 0xA8, 0x37, 0xFB, 0x22,
];
const EP_OBF: &[u8] = &[
    0xCB, 0xE7, 0x9E, 0xD2, 0x07, 0xB0, 0xD3, 0x1E, 0xAC, 0x8E, 0x7A, 0x3E, 0xE1, 0xFE, 0x2A, 0xC8,
    0x3F, 0x6C, 0xAB, 0xCF, 0xAA, 0xD7, 0x7E, 0x8E, 0x2F, 0xEC, 0x97, 0x95, 0x1F, 0xEB, 0x8A, 0x4A,
];
const SEC_OBF: &[u8] = &[
    0xC6, 0xFA, 0x9A, 0xE5, 0x20, 0xDA, 0x9E, 0x43, 0xF9, 0x8C, 0x25, 0x6D, 0xDD, 0xBF, 0x30, 0xF7,
    0x38, 0x11, 0x92, 0xCE, 0x8A, 0x89, 0x1F, 0xAF, 0x03, 0xF8, 0x91, 0xEF, 0x2F, 0xF7, 0xD2, 0x19,
    0xEA, 0x77, 0x71, 0x52, 0xF1, 0x31, 0x03, 0x95, 0x1C, 0xD2, 0xCF,
];

const KS_PREFIX: &[u8] = b"lr-ks-v1";
const MAC_PREFIX: &[u8] = b"lr-mac-v1";
const SCHEMA_REV: u64 = 4;
const NONCE_LEN: usize = 12;
const TAG_LEN: usize = 12;

fn deob(src: &[u8]) -> Vec<u8> {
    src.iter()
        .enumerate()
        .map(|(i, b)| b ^ OBF[i % OBF.len()] ^ ((i.wrapping_mul(0x1F) & 0xFF) as u8))
        .collect()
}

fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{:02x}", b));
    }
    s
}

fn keystream(secret: &[u8], nonce: &[u8], len: usize) -> Vec<u8> {
    let mut out = Vec::with_capacity(len + 32);
    let mut counter: u32 = 0;
    while out.len() < len {
        let mut mac = <HmacSha256 as Mac>::new_from_slice(secret).expect("hmac key");
        mac.update(KS_PREFIX);
        mac.update(nonce);
        mac.update(&counter.to_le_bytes());
        out.extend_from_slice(&mac.finalize().into_bytes());
        counter += 1;
    }
    out.truncate(len);
    out
}

fn seal(body_json: &str, secret: &[u8]) -> Option<String> {
    let raw = body_json.as_bytes();
    let mut nonce = [0u8; NONCE_LEN];
    getrandom::getrandom(&mut nonce).ok()?;

    let ks = keystream(secret, &nonce, raw.len());
    let enc: Vec<u8> = raw.iter().zip(ks.iter()).map(|(a, b)| a ^ b).collect();

    let mut mac = <HmacSha256 as Mac>::new_from_slice(secret).ok()?;
    mac.update(MAC_PREFIX);
    mac.update(&nonce);
    mac.update(&enc);
    let tag = hex(&mac.finalize().into_bytes()[..TAG_LEN]);

    let envelope = serde_json::json!({
        "leaf": SCHEMA_REV,
        "salt": STANDARD.encode(nonce),
        "body": STANDARD.encode(&enc),
        "mac": tag,
    });
    Some(envelope.to_string())
}

fn post(endpoint: &str, envelope: &str, ua: &str) -> String {
    let agent = ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(8))
        .timeout(Duration::from_secs(20))
        .build();
    let ua = if ua.is_empty() {
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36"
    } else {
        ua
    };
    let req = agent
        .post(endpoint)
        .set("Accept", "application/json")
        .set("Content-Type", "application/json")
        .set("User-Agent", ua);
    match req.send_string(envelope) {
        Ok(resp) if resp.status() == 200 => resp.into_string().unwrap_or_default(),
        _ => String::new(),
    }
}

fn route_internal(body_json: &str, ua: &str) -> String {
    let secret = deob(SEC_OBF);
    let envelope = match seal(body_json, &secret) {
        Some(e) => e,
        None => return String::new(),
    };
    let endpoint = match String::from_utf8(deob(EP_OBF)) {
        Ok(e) => e,
        Err(_) => return String::new(),
    };
    post(&endpoint, &envelope, ua)
}

fn cstr(ptr: *const c_char) -> String {
    if ptr.is_null() {
        return String::new();
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .unwrap_or("")
        .to_owned()
}

/// Seal + POST the composed body to the relay; returns the config answer JSON
/// (or empty string on any failure). Free the result with [`lr_free`].
#[no_mangle]
pub extern "C" fn lr_route(body: *const c_char, ua: *const c_char) -> *mut c_char {
    let out = route_internal(&cstr(body), &cstr(ua));
    CString::new(out)
        .unwrap_or_else(|_| CString::new("").unwrap())
        .into_raw()
}

/// Free a string returned by [`lr_route`].
#[no_mangle]
pub extern "C" fn lr_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}
