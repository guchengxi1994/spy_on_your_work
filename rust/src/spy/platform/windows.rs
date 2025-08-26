use std::ffi::OsString;
use std::os::windows::ffi::OsStringExt;
use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
use windows::Win32::Graphics::Gdi::{
    CreateCompatibleDC, CreateDIBSection, DeleteDC, DeleteObject, GetDC, ReleaseDC, SelectObject,
    BITMAPINFO, BITMAPINFOHEADER, BI_RGB, DIB_RGB_COLORS,
};
use windows::Win32::System::ProcessStatus::K32GetModuleFileNameExW;
use windows::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_INFORMATION, PROCESS_VM_READ};
use windows::Win32::UI::WindowsAndMessaging::{
    DrawIconEx, GetClassLongPtrW, GetIconInfo, GetWindowTextW, GetWindowThreadProcessId,
    SendMessageW, DI_NORMAL, GCLP_HICON, HICON, ICONINFO, ICON_BIG, WM_GETICON,
};

use crate::spy::model::Application;
use crate::spy::model::ApplicationProvider;
use crate::spy::platform::WindowCapture;

impl ApplicationProvider for Application {
    fn from_process(hwnd: HWND) -> Option<Application> {
        Self::from_hwnd(hwnd)
    }
}

impl Application {
    /// 从 HWND 创建 Application 实例
    pub fn from_hwnd(hwnd: HWND) -> Option<Application> {
        unsafe {
            // 检查窗口句柄是否有效
            if hwnd.0 == std::ptr::null_mut() {
                return None;
            }

            // 获取窗口标题（动态变化）
            let mut title_buf = [0u16; 512];
            let title_len = GetWindowTextW(hwnd, &mut title_buf);
            let title = if title_len > 0 {
                OsString::from_wide(&title_buf[..title_len as usize])
                    .to_string_lossy()
                    .into_owned()
            } else {
                String::from("Unknown Window")
            };

            // 获取进程ID
            let mut pid = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut pid));

            // 获取进程的可执行文件路径
            let path = if let Ok(proc_handle) =
                OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, pid)
            {
                let mut path_buf = [0u16; 260];
                let path_len = K32GetModuleFileNameExW(Some(proc_handle), None, &mut path_buf);
                if path_len > 0 {
                    OsString::from_wide(&path_buf[..path_len as usize])
                        .to_string_lossy()
                        .into_owned()
                } else {
                    String::new()
                }
            } else {
                String::new()
            };

            // 从路径提取稳定的应用名称（不包含扩展名）
            let name = if !path.is_empty() {
                if let Some(file_stem) = std::path::Path::new(&path).file_stem() {
                    file_stem.to_string_lossy().into_owned()
                } else {
                    // 如果从路径提取失败，使用窗口标题作为备选
                    Self::extract_app_name_from_title(&title)
                }
            } else {
                // 没有路径时，尝试从窗口标题提取应用名
                Self::extract_app_name_from_title(&title)
            };

            // 获取应用图标并转换为base64
            let icon = Self::get_window_icon_base64(hwnd);

            // 只要有标题或路径中的任意一个，就创建Application
            if !title.is_empty() || !path.is_empty() {
                let mut screen_shot_path = None;
                {
                    if super::is_screenshot_app(name.clone()) {
                        // save screenshot
                        let save_folder;
                        {
                            save_folder = crate::api::spy_api::SCREENSHOT_SAVE_FOLDER
                                .lock()
                                .unwrap()
                                .clone();
                        }
                        let e = WindowCapture::capture_window(hwnd, &save_folder);
                        match e {
                            Ok(p) => {
                                screen_shot_path = Some(p);
                            }
                            Err(_e) => {
                                println!("Save screenshot file error: {}", _e);
                            }
                        }
                    }
                }

                Some(Application {
                    icon,
                    name,
                    title,
                    path,
                    screen_shot_path,
                })
            } else {
                None
            }
        }
    }

    #[allow(deprecated)]
    /// 获取窗口图标并转换为base64字符串
    unsafe fn get_window_icon_base64(hwnd: HWND) -> Option<String> {
        // 尝试获取窗口图标
        let hicon = Self::get_window_icon(hwnd)?;

        // 将图标转换为位图数据
        let bitmap_data = Self::icon_to_bitmap_data(hicon)?;

        // 转换为base64
        Some(base64::encode(bitmap_data))
    }

    /// 获取窗口图标句柄
    unsafe fn get_window_icon(hwnd: HWND) -> Option<HICON> {
        // 方法1: 尝试通过 WM_GETICON 消息获取大图标
        let result = SendMessageW(
            hwnd,
            WM_GETICON,
            Some(WPARAM(ICON_BIG as usize)),
            Some(LPARAM(0)),
        );

        if result.0 != 0 {
            return Some(HICON(result.0 as *mut _));
        }

        // 方法2: 尝试从窗口类获取图标
        let class_icon = GetClassLongPtrW(hwnd, GCLP_HICON);
        if class_icon != 0 {
            return Some(HICON(class_icon as *mut _));
        }

        // 没有找到图标
        None
    }

    /// 将图标转换为位图数据
    unsafe fn icon_to_bitmap_data(hicon: HICON) -> Option<Vec<u8>> {
        // 获取图标信息
        let mut icon_info = ICONINFO::default();
        if GetIconInfo(hicon, &mut icon_info).is_err() {
            return None;
        }

        // 创建设备上下文
        let hdc_screen = GetDC(None);
        let hdc_mem = CreateCompatibleDC(Some(hdc_screen));

        // 设置位图信息
        let icon_size = 32; // 标准图标大小
        let bmp_info = BITMAPINFO {
            bmiHeader: BITMAPINFOHEADER {
                biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
                biWidth: icon_size,
                biHeight: -icon_size, // 负值表示从上到下
                biPlanes: 1,
                biBitCount: 32, // 32位RGBA
                biCompression: BI_RGB.0,
                biSizeImage: 0,
                biXPelsPerMeter: 0,
                biYPelsPerMeter: 0,
                biClrUsed: 0,
                biClrImportant: 0,
            },
            bmiColors: [windows::Win32::Graphics::Gdi::RGBQUAD::default(); 1],
        };

        let mut bits_ptr: *mut std::ffi::c_void = std::ptr::null_mut();
        let hbitmap = CreateDIBSection(
            Some(hdc_mem),
            &bmp_info,
            DIB_RGB_COLORS,
            &mut bits_ptr,
            None,
            0,
        );

        if let Ok(bitmap) = hbitmap {
            if bits_ptr.is_null() {
                ReleaseDC(None, hdc_screen);
                let _ = DeleteDC(hdc_mem);
                let _ = DeleteObject(icon_info.hbmColor.into());
                let _ = DeleteObject(icon_info.hbmMask.into());
                return None;
            }

            let old_bitmap = SelectObject(hdc_mem, bitmap.into());

            // 绘制图标到位图
            if DrawIconEx(
                hdc_mem, 0, 0, hicon, icon_size, icon_size, 0, None, DI_NORMAL,
            )
            .is_err()
            {
                SelectObject(hdc_mem, old_bitmap);
                ReleaseDC(None, hdc_screen);
                let _ = DeleteDC(hdc_mem);
                let _ = DeleteObject(bitmap.into());
                let _ = DeleteObject(icon_info.hbmColor.into());
                let _ = DeleteObject(icon_info.hbmMask.into());
                return None;
            }

            // 复制位图数据
            let data_size = (icon_size * icon_size * 4) as usize; // 32位RGBA
            let mut bitmap_data = vec![0u8; data_size];
            std::ptr::copy_nonoverlapping(
                bits_ptr as *const u8,
                bitmap_data.as_mut_ptr(),
                data_size,
            );

            // 清理资源
            SelectObject(hdc_mem, old_bitmap);
            ReleaseDC(None, hdc_screen);
            let _ = DeleteDC(hdc_mem);
            let _ = DeleteObject(bitmap.into());
            let _ = DeleteObject(icon_info.hbmColor.into());
            let _ = DeleteObject(icon_info.hbmMask.into());

            // 将BGRA转换为PNG格式的字节数组
            Self::bgra_to_png(bitmap_data, icon_size as u32, icon_size as u32)
        } else {
            ReleaseDC(None, hdc_screen);
            let _ = DeleteDC(hdc_mem);
            let _ = DeleteObject(icon_info.hbmColor.into());
            let _ = DeleteObject(icon_info.hbmMask.into());
            None
        }
    }

    /// 将BGRA像素数据转换为PNG字节数组
    fn bgra_to_png(bgra: Vec<u8>, width: u32, height: u32) -> Option<Vec<u8>> {
        use image::{ImageBuffer, Rgba};
        use std::io::Cursor;

        // BGRA 转 RGBA
        let mut rgba = Vec::with_capacity(bgra.len());
        for chunk in bgra.chunks(4) {
            rgba.push(chunk[2]); // R
            rgba.push(chunk[1]); // G
            rgba.push(chunk[0]); // B
            rgba.push(chunk[3]); // A
        }

        // 创建 ImageBuffer
        let img: ImageBuffer<Rgba<u8>, _> = ImageBuffer::from_raw(width, height, rgba)?;

        // 写入 PNG 到内存
        let mut buf = Cursor::new(Vec::new());
        if img.write_to(&mut buf, image::ImageFormat::Png).is_ok() {
            Some(buf.into_inner())
        } else {
            None
        }
    }

    /// 从窗口标题提取应用名称的辅助方法
    /// 尝试从窗口标题中提取有意义的应用名称
    fn extract_app_name_from_title(title: &str) -> String {
        if title.is_empty() {
            return String::from("Unknown Application");
        }

        // 常见的应用名称提取模式
        let title_lower = title.to_lowercase();

        // 对于一些常见的应用，直接识别
        if title_lower.contains("visual studio code") || title_lower.contains("vscode") {
            return String::from("Visual Studio Code");
        } else if title_lower.contains("google chrome") || title_lower.contains("chrome") {
            return String::from("Google Chrome");
        } else if title_lower.contains("firefox") {
            return String::from("Firefox");
        } else if title_lower.contains("microsoft edge") || title_lower.contains("edge") {
            return String::from("Microsoft Edge");
        } else if title_lower.contains("notepad++") {
            return String::from("Notepad++");
        } else if title_lower.contains("notepad") && !title_lower.contains("notepad++") {
            return String::from("Notepad");
        } else if title_lower.contains("explorer") {
            return String::from("File Explorer");
        } else if title_lower.contains("cmd") || title_lower.contains("command prompt") {
            return String::from("Command Prompt");
        } else if title_lower.contains("powershell") {
            return String::from("PowerShell");
        } else if title_lower.contains("terminal") {
            return String::from("Windows Terminal");
        } else if title_lower.contains("word") {
            return String::from("Microsoft Word");
        } else if title_lower.contains("excel") {
            return String::from("Microsoft Excel");
        } else if title_lower.contains("powerpoint") {
            return String::from("Microsoft PowerPoint");
        } else if title_lower.contains("outlook") {
            return String::from("Microsoft Outlook");
        }

        // 如果没有匹配到知名应用，尝试从标题中提取第一部分
        // 对于形如 "Document1 - Microsoft Word" 的标题
        if let Some(dash_pos) = title.rfind(" - ") {
            let app_part = title[dash_pos + 3..].trim();
            if !app_part.is_empty() {
                return app_part.to_string();
            }
        }

        // 对于形如 "Document1 — Microsoft Word" 的标题（使用em dash）
        if let Some(em_dash_pos) = title.rfind(" — ") {
            let app_part = title[em_dash_pos + 3..].trim();
            if !app_part.is_empty() {
                return app_part.to_string();
            }
        }

        // 对于形如 "filename.txt • Notepad++" 的标题
        if let Some(bullet_pos) = title.rfind(" • ") {
            let app_part = title[bullet_pos + 3..].trim();
            if !app_part.is_empty() {
                return app_part.to_string();
            }
        }

        // 如果都没有，直接使用原始标题（截取前50个字符避免过长）
        if title.len() > 50 {
            format!("{}...", &title[..47])
        } else {
            title.to_string()
        }
    }
}
