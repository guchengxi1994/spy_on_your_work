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
