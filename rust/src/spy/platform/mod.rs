use std::collections::HashSet;
use std::sync::Mutex;

use once_cell::sync::Lazy;
#[cfg(target_os = "windows")]
mod window_capture;
#[cfg(target_os = "windows")]
mod windows;

#[cfg(target_os = "windows")]
pub use window_capture::*;
#[cfg(target_os = "windows")]
#[allow(unused_imports)]
pub use windows::*;

#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "macos")]
pub use macos::*;

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "linux")]
pub use linux::*;

pub static SCREENSHOT_APPS_ON: Lazy<Mutex<HashSet<String>>> =
    Lazy::new(|| Mutex::new(HashSet::new()));

pub fn init_screenshot_apps(v: Vec<String>) {
    let mut apps = SCREENSHOT_APPS_ON.lock().unwrap();
    for i in v {
        apps.insert(i);
    }
}

pub fn insert_screenshot_app(v: String) {
    let mut apps = SCREENSHOT_APPS_ON.lock().unwrap();
    apps.insert(v);
}

pub fn remove_screenshot_app(v: String) {
    let mut apps = SCREENSHOT_APPS_ON.lock().unwrap();
    apps.remove(&v);
}

pub fn is_screenshot_app(v: String) -> bool {
    let apps = SCREENSHOT_APPS_ON.lock().unwrap();
    apps.contains(&v)
}
