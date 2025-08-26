use std::sync::Mutex;

use flutter_rust_bridge::frb;
use once_cell::sync::Lazy;

use crate::{
    frb_generated::StreamSink,
    spy::{api::EVENT_SINK, model::Application},
};

pub static SCREENSHOT_SAVE_FOLDER: Lazy<Mutex<String>> = Lazy::new(|| Mutex::new(String::new()));

#[frb(sync)]
pub fn application_info_stream(s: StreamSink<Application>) -> anyhow::Result<()> {
    let mut stream = EVENT_SINK.write().unwrap();
    *stream = Some(s);
    anyhow::Ok(())
}

#[frb(sync)]
pub fn start_spy() {
    crate::spy::api::start_spy();
}

#[frb(sync)]
pub fn get_spy_status() -> bool {
    crate::spy::api::SPY_ON.read().unwrap().clone()
}

#[frb(sync)]
pub fn init_save_path(path: String) {
    let mut s = SCREENSHOT_SAVE_FOLDER.lock().unwrap();
    *s = path;
    println!("[rust] init save path: {}", s);
}

#[frb(sync)]
pub fn init_screenshot_apps(v: Vec<String>) {
    println!("[rust] init_screenshot_apps: {:?}", v);
    crate::spy::platform::init_screenshot_apps(v);
}

#[frb(sync)]
pub fn insert_screenshot_apps(v: String) {
    println!("[rust] insert_screenshot_apps: {}", v);
    crate::spy::platform::insert_screenshot_app(v);
}

#[frb(sync)]
pub fn remove_screenshot_apps(v: String) {
    println!("[rust] remove_screenshot_apps: {}", v);
    crate::spy::platform::remove_screenshot_app(v);
}
