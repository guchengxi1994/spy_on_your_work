use std::sync::RwLock;

use crate::frb_generated::StreamSink;
use crate::spy::model::Application;

const SLEEP_SECS: u64 = 60;

pub static EVENT_SINK: RwLock<Option<StreamSink<Application>>> = RwLock::new(None);

pub fn send_application_message(message: Application) {
    if let Some(sink) = &*EVENT_SINK.read().unwrap() {
        let _ = sink.add(message);
    }
}

#[cfg(target_os = "windows")]
pub fn start_spy() {
    std::thread::spawn(move || loop {
        unsafe {
            use crate::spy::model::ApplicationProvider;

            let hwnd = windows::Win32::UI::WindowsAndMessaging::GetForegroundWindow();
            if hwnd.0 == std::ptr::null_mut() {
                println!("没有前台窗口");
                continue;
            }
            let app = Application::from_process(hwnd);
            if app.is_none() {
                println!("没有找到应用");
                continue;
            }
            send_application_message(app.unwrap());
        }

        std::thread::sleep(std::time::Duration::from_secs(SLEEP_SECS));
    });
}

#[cfg(target_os = "linux")]
pub fn start_spy() {}

#[cfg(target_os = "macos")]
pub fn start_spy() {}
