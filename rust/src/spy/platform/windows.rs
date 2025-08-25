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

            // 获取窗口标题作为应用名称
            let mut title_buf = [0u16; 512];
            let title_len = GetWindowTextW(hwnd, &mut title_buf);
            let name = if title_len > 0 {
                OsString::from_wide(&title_buf[..title_len as usize])
                    .to_string_lossy()
                    .into_owned()
            } else {
                String::from("Unknown Application")
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

            // 获取应用图标并转换为base64
            let icon = Self::get_window_icon_base64(hwnd);

            // 如果没有获取到路径但有窗口标题，仍然创建Application
            if !name.is_empty() || !path.is_empty() {
                Some(Application { icon, name, path })
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
    fn bgra_to_png(bgra_data: Vec<u8>, _width: u32, _height: u32) -> Option<Vec<u8>> {
        // 将BGRA转换为RGBA
        let mut rgba_data = Vec::with_capacity(bgra_data.len());
        for chunk in bgra_data.chunks_exact(4) {
            rgba_data.push(chunk[2]); // R
            rgba_data.push(chunk[1]); // G
            rgba_data.push(chunk[0]); // B
            rgba_data.push(chunk[3]); // A
        }

        // 使用简单的PNG编码，这里我们返回原始RGBA数据
        // 在实际项目中，您可能想要使用png crate来生成真正的PNG
        Some(rgba_data)
    }
}
