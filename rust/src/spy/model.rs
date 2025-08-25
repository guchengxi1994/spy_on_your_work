#[derive(Debug, Clone)]
pub struct Application {
    pub icon: Option<String>,
    pub name: String,
    pub path: String,
}

#[cfg(target_os = "windows")]
pub trait ApplicationProvider {
    fn from_process(hwnd: windows::Win32::Foundation::HWND) -> Option<Application>;
}

#[cfg(not(target_os = "windows"))]
pub trait ApplicationProvider {
    fn from_process<T>(p: T) -> Option<Application>;
}
