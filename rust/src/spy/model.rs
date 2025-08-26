#[derive(Debug, Clone)]
pub struct Application {
    pub icon: Option<String>,
    pub name: String,  // 应用程序名称（从可执行文件路径提取，稳定不变）
    pub title: String, // 窗口标题（动态变化）
    pub path: String,  // 可执行文件完整路径
    pub screen_shot_path: Option<String>, // 截图保存路径,默认为空
}

#[cfg(target_os = "windows")]
pub trait ApplicationProvider {
    fn from_process(hwnd: windows::Win32::Foundation::HWND) -> Option<Application>;
}

#[cfg(not(target_os = "windows"))]
pub trait ApplicationProvider {
    fn from_process<T>(p: T) -> Option<Application>;
}
