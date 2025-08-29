#[allow(deprecated)] // 抑制 cocoa 库的废弃警告
use cocoa::base::{id, nil};
use cocoa::foundation::NSString;
use objc::{class, msg_send, sel, sel_impl};
use std::ffi::CStr;

use crate::spy::model::Application;
use crate::spy::model::ApplicationProvider;

/// macOS 平台的 ApplicationProvider 实现
impl ApplicationProvider for Application {
    fn from_process<T>(_p: T) -> Option<Application> {
        // macOS 实现获取前台应用
        unsafe { Self::get_frontmost_application() }
    }
}

impl Application {
    /// 获取当前前台应用的信息
    pub unsafe fn get_frontmost_application() -> Option<Application> {
        // 获取 NSWorkspace
        let workspace: id = msg_send![class!(NSWorkspace), sharedWorkspace];
        if workspace == nil {
            return None;
        }

        // 获取前台应用
        let app: id = msg_send![workspace, frontmostApplication];
        if app == nil {
            return None;
        }

        Self::create_application_from_nsrunning_app(app)
    }

    /// 从 NSRunningApplication 对象创建 Application 实例
    unsafe fn create_application_from_nsrunning_app(app: id) -> Option<Application> {
        if app == nil {
            return None;
        }

        // 获取应用名称（用作稳定标识符）
        let localized_name: id = msg_send![app, localizedName];
        let app_name = if localized_name != nil {
            nsstring_to_rust(localized_name)
        } else {
            String::from("Unknown Application")
        };

        // 获取 Bundle Identifier（更稳定的标识符）
        let bundle_id: id = msg_send![app, bundleIdentifier];
        let bundle_id_str = if bundle_id != nil {
            nsstring_to_rust(bundle_id)
        } else {
            String::new()
        };

        // 优先使用 Bundle ID 的最后一部分作为 name，否则使用 localizedName
        let name = if !bundle_id_str.is_empty() {
            Self::extract_app_name_from_bundle_id(&bundle_id_str, &app_name)
        } else {
            app_name.clone()
        };

        // 获取应用路径
        let mut path = String::new();
        let bundle_url: id = msg_send![app, bundleURL];
        if bundle_url != nil {
            let path_nsstring: id = msg_send![bundle_url, path];
            if path_nsstring != nil {
                path = nsstring_to_rust(path_nsstring);
            }
        }

        // 获取应用图标
        let icon = if bundle_url != nil {
            let path_nsstring: id = msg_send![bundle_url, path];
            if path_nsstring != nil {
                Self::get_app_icon_base64(path_nsstring)
            } else {
                None
            }
        } else {
            None
        };

        // 使用 app_name 作为 title（动态标题）
        let title = app_name;

        // 检查截图功能
        let mut screen_shot_path = None;
        {
            if super::is_screenshot_app(name.clone()) {
                // macOS 上的截图实现可以后续添加
                // 暂时留空，因为需要额外的权限和实现
                println!("macOS 截图功能待实现");
            }
        }

        Some(Application {
            icon,
            name,
            title,
            path,
            screen_shot_path,
        })
    }

    /// 从 Bundle ID 提取应用名称
    fn extract_app_name_from_bundle_id(bundle_id: &str, fallback_name: &str) -> String {
        if bundle_id.is_empty() {
            return fallback_name.to_string();
        }

        // 从 com.apple.Safari 格式提取最后一部分
        if let Some(last_part) = bundle_id.split('.').last() {
            if !last_part.is_empty() {
                return last_part.to_string();
            }
        }

        fallback_name.to_string()
    }

    /// 获取应用图标并转换为 Base64
    unsafe fn get_app_icon_base64(path_nsstring: id) -> Option<String> {
        if path_nsstring == nil {
            return None;
        }

        // 获取 NSWorkspace
        let workspace: id = msg_send![class!(NSWorkspace), sharedWorkspace];
        if workspace == nil {
            return None;
        }

        // 通过路径获取图标
        let icon: id = msg_send![workspace, iconForFile: path_nsstring];
        if icon == nil {
            return None;
        }

        // 转换 NSImage 为 Base64
        Self::nsimage_to_base64(icon)
    }

    /// 将 NSImage 转换为 Base64 字符串
    unsafe fn nsimage_to_base64(image: id) -> Option<String> {
        if image == nil {
            return None;
        }

        // 创建 CGImage
        let rect = cocoa::foundation::NSRect::new(
            cocoa::foundation::NSPoint::new(0.0, 0.0),
            msg_send![image, size],
        );

        let cg_image: id = msg_send![image, CGImageForProposedRect: &rect context: nil hints: nil];
        if cg_image == nil {
            return None;
        }

        // 创建 NSBitmapImageRep
        let bitmap: id = msg_send![class!(NSBitmapImageRep), alloc];
        let bitmap: id = msg_send![bitmap, initWithCGImage: cg_image];

        if bitmap == nil {
            return None;
        }

        // 转换为 PNG 数据
        let png_data: id = msg_send![bitmap, representationUsingType: 4 properties: nil]; // NSPNGFileType = 4

        if png_data == nil {
            return None;
        }

        // 获取数据长度和指针
        let length: usize = msg_send![png_data, length];
        let bytes: *const u8 = msg_send![png_data, bytes];

        if bytes.is_null() || length == 0 {
            return None;
        }

        // 转换为 Vec<u8>
        let data = std::slice::from_raw_parts(bytes, length).to_vec();

        // 转换为 Base64
        use base64::{engine::general_purpose, Engine as _};
        Some(general_purpose::STANDARD.encode(data))
    }

    /// 获取运行中的所有应用（用于调试和扩展功能）
    #[allow(dead_code)]
    pub unsafe fn get_running_applications() -> Vec<Application> {
        let mut apps = Vec::new();

        let workspace: id = msg_send![class!(NSWorkspace), sharedWorkspace];
        if workspace == nil {
            return apps;
        }

        let running_apps: id = msg_send![workspace, runningApplications];
        if running_apps == nil {
            return apps;
        }

        let count: usize = msg_send![running_apps, count];
        for i in 0..count {
            let app: id = msg_send![running_apps, objectAtIndex: i];
            if let Some(application) = Self::create_application_from_nsrunning_app(app) {
                apps.push(application);
            }
        }

        apps
    }
}

/// 工具函数: NSString -> Rust String
unsafe fn nsstring_to_rust(ns_string: id) -> String {
    if ns_string == nil {
        return String::new();
    }

    let utf8: *const std::os::raw::c_char = msg_send![ns_string, UTF8String];
    if utf8.is_null() {
        return String::new();
    }

    CStr::from_ptr(utf8).to_string_lossy().into_owned()
}
