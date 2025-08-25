use std::ffi::OsString;
use std::fs::File;
use std::io::Write;
use std::os::windows::ffi::OsStringExt;
use std::time::{SystemTime, UNIX_EPOCH};

use windows::Win32::Foundation::{HWND, RECT};
use windows::Win32::Graphics::Gdi::{
    BitBlt, CreateCompatibleBitmap, CreateCompatibleDC, CreateSolidBrush, DeleteDC, DeleteObject,
    FillRect, GetBitmapBits, GetDC, GetObjectW, GetWindowDC, ReleaseDC, SelectObject, BITMAP,
    BITMAPFILEHEADER, BITMAPINFOHEADER, BI_RGB, HBITMAP, SRCCOPY,
};
use windows::Win32::UI::WindowsAndMessaging::{GetWindowRect, GetWindowTextW};

/// Windows窗口截图工具
pub struct WindowCapture;

impl WindowCapture {
    /// 对指定窗口进行截图并保存到指定文件夹
    ///
    /// # 参数
    /// - `hwnd`: 要截图的窗口句柄
    /// - `folder_path`: 保存截图的文件夹路径
    ///
    /// # 返回值
    /// - `Ok(String)`: 成功时返回保存的文件完整路径
    /// - `Err(String)`: 失败时返回错误信息
    pub fn capture_window(hwnd: HWND, folder_path: &str) -> Result<String, String> {
        unsafe {
            // 检查窗口句柄是否有效
            if hwnd.0 == std::ptr::null_mut() {
                return Err("窗口句柄无效".to_string());
            }

            // 获取窗口标题用于文件命名
            let title = Self::get_window_title(hwnd)?;

            // 清理文件名中的非法字符
            let safe_title = Self::sanitize_filename(&title);

            // 获取窗口矩形
            let mut rect = RECT::default();
            if GetWindowRect(hwnd, &mut rect).is_err() {
                return Err("无法获取窗口矩形".to_string());
            }

            let width = rect.right - rect.left;
            let height = rect.bottom - rect.top;

            if width <= 0 || height <= 0 {
                return Err("窗口尺寸无效".to_string());
            }

            // 创建位图并进行截图
            let hbitmap = Self::create_window_bitmap(hwnd, &rect, width, height)?;

            // 确保文件夹存在
            if let Err(e) = std::fs::create_dir_all(folder_path) {
                return Err(format!("无法创建文件夹: {}", e));
            }

            // 生成文件名（带时间戳避免重复）
            let filename = Self::generate_filename(&safe_title);
            let file_path = std::path::Path::new(folder_path).join(&filename);
            let full_path = file_path.to_string_lossy().to_string();

            // 保存为BMP
            Self::save_bitmap_to_file(hbitmap, width, height, &full_path)?;

            Ok(full_path)
        }
    }

    /// 获取窗口标题
    unsafe fn get_window_title(hwnd: HWND) -> Result<String, String> {
        let mut title_buf = [0u16; 512];
        let title_len = GetWindowTextW(hwnd, &mut title_buf);

        if title_len > 0 {
            Ok(OsString::from_wide(&title_buf[..title_len as usize])
                .to_string_lossy()
                .into_owned())
        } else {
            Ok("Unknown_Window".to_string())
        }
    }

    /// 清理文件名中的非法字符
    fn sanitize_filename(filename: &str) -> String {
        filename
            .replace(['<', '>', ':', '"', '/', '\\', '|', '?', '*'], "_")
            .trim()
            .to_string()
    }

    /// 生成带时间戳的文件名
    fn generate_filename(safe_title: &str) -> String {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        format!("{}_{}.bmp", safe_title, timestamp)
    }

    /// 创建窗口的位图
    unsafe fn create_window_bitmap(
        hwnd: HWND,
        rect: &RECT,
        width: i32,
        height: i32,
    ) -> Result<HBITMAP, String> {
        // 创建设备上下文
        let hdc_window = GetWindowDC(Some(hwnd));
        let hdc_mem = CreateCompatibleDC(Some(hdc_window));
        let hbitmap = CreateCompatibleBitmap(hdc_window, width, height);
        let old_bitmap = SelectObject(hdc_mem, hbitmap.into());

        // 先填充白色背景，避免黑色
        let white_brush = CreateSolidBrush(windows::Win32::Foundation::COLORREF(0x00FFFFFF));
        let rect_fill = RECT {
            left: 0,
            top: 0,
            right: width,
            bottom: height,
        };
        FillRect(hdc_mem, &rect_fill, white_brush);
        let _ = DeleteObject(white_brush.into());

        // 使用屏幕DC进行截图
        let hdc_screen = GetDC(None);
        let screen_x = rect.left;
        let screen_y = rect.top;

        let blt_result = BitBlt(
            hdc_mem,
            0,
            0,
            width,
            height,
            Some(hdc_screen),
            screen_x,
            screen_y,
            SRCCOPY,
        );

        ReleaseDC(None, hdc_screen);

        // 清理资源
        SelectObject(hdc_mem, old_bitmap);
        ReleaseDC(Some(hwnd), hdc_window);
        let _ = DeleteDC(hdc_mem);

        if blt_result.is_err() {
            let _ = DeleteObject(hbitmap.into());
            Err("BitBlt操作失败".to_string())
        } else {
            Ok(hbitmap)
        }
    }

    /// 将位图保存为BMP文件
    unsafe fn save_bitmap_to_file(
        hbitmap: HBITMAP,
        _width: i32,
        _height: i32,
        path: &str,
    ) -> Result<(), String> {
        use std::ffi::c_void;

        let mut bmp: BITMAP = std::mem::zeroed();
        if GetObjectW(
            hbitmap.into(),
            std::mem::size_of::<BITMAP>() as i32,
            Some(&mut bmp as *mut _ as *mut c_void),
        ) == 0
        {
            return Err("获取位图对象信息失败".to_string());
        }

        let header_size = std::mem::size_of::<BITMAPFILEHEADER>() as u32
            + std::mem::size_of::<BITMAPINFOHEADER>() as u32;
        let image_size = (bmp.bmWidthBytes * bmp.bmHeight) as u32;

        let file_header = BITMAPFILEHEADER {
            bfType: 0x4D42, // 'BM'
            bfSize: header_size + image_size,
            bfReserved1: 0,
            bfReserved2: 0,
            bfOffBits: header_size,
        };

        let info_header = BITMAPINFOHEADER {
            biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
            biWidth: bmp.bmWidth,
            biHeight: -bmp.bmHeight, // top-down bitmap
            biPlanes: 1,
            biBitCount: 32,
            biCompression: BI_RGB.0,
            biSizeImage: image_size,
            biXPelsPerMeter: 0,
            biYPelsPerMeter: 0,
            biClrUsed: 0,
            biClrImportant: 0,
        };

        let mut buffer = vec![0u8; image_size as usize];
        if GetBitmapBits(
            hbitmap,
            image_size as i32,
            buffer.as_mut_ptr() as *mut c_void,
        ) == 0
        {
            return Err("获取位图数据失败".to_string());
        }

        let mut file = File::create(path).map_err(|e| format!("创建文件失败: {}", e))?;

        // 转换为字节数组
        let file_header_bytes = unsafe {
            std::slice::from_raw_parts(
                &file_header as *const _ as *const u8,
                std::mem::size_of::<BITMAPFILEHEADER>(),
            )
        };
        let info_header_bytes = unsafe {
            std::slice::from_raw_parts(
                &info_header as *const _ as *const u8,
                std::mem::size_of::<BITMAPINFOHEADER>(),
            )
        };

        file.write_all(file_header_bytes)
            .map_err(|e| format!("写入文件头失败: {}", e))?;
        file.write_all(info_header_bytes)
            .map_err(|e| format!("写入信息头失败: {}", e))?;
        file.write_all(&buffer)
            .map_err(|e| format!("写入位图数据失败: {}", e))?;

        // 清理位图资源
        let _ = DeleteObject(hbitmap.into());

        Ok(())
    }
}
