#[allow(unused_imports)]
#[allow(dead_code)]
#[allow(unused_variables)]
mod tests {
    use std::ffi::c_void;
    use std::ffi::OsString;
    use std::fs::File;
    use std::os::windows::ffi::OsStringExt;
    use std::{env, mem, ptr};
    use windows::Globalization::Language;
    use windows::Graphics::Imaging::{BitmapDecoder, SoftwareBitmap};
    use windows::Media::Ocr::OcrEngine;
    use windows::Storage::FileAccessMode;
    use windows::Storage::StorageFile;
    use windows::Win32::Foundation::RECT;
    use windows::{
        core::{HSTRING, PCWSTR},
        Win32::{
            Foundation::HWND,
            Graphics::Gdi::*,
            System::{ProcessStatus::K32GetModuleFileNameExW, Threading::*},
            UI::WindowsAndMessaging::*,
        },
    };

    #[test]
    #[allow(unused_assignments)]
    fn test_get_frontend_window_info() {
        unsafe {
            // 1. 获取前台窗口
            let hwnd: HWND = GetForegroundWindow();
            if hwnd.0 == std::ptr::null_mut() {
                println!("没有前台窗口");
                return;
            }

            // 2. 获取窗口标题
            let mut buf = [0u16; 512];
            let len = GetWindowTextW(hwnd, &mut buf);
            let title = OsString::from_wide(&buf[..len as usize])
                .to_string_lossy()
                .into_owned();
            println!("窗口标题: {}", title);

            // 3. 获取进程 ID
            let mut pid = 0;
            GetWindowThreadProcessId(hwnd, Some(&mut pid));
            println!("进程 ID: {}", pid);

            // 4. 打开进程，获取 exe 路径
            let hproc = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, pid);
            if let Ok(proc_handle) = hproc {
                let mut buf = [0u16; 260];
                let len = K32GetModuleFileNameExW(Some(proc_handle), None, &mut buf);
                let exe_path = OsString::from_wide(&buf[..len as usize])
                    .to_string_lossy()
                    .into_owned();
                println!("进程路径: {}", exe_path);
            }

            // 5. 获取应用图标
            let mut hicon: HICON = HICON::default();
            let result = SendMessageW(
                hwnd,
                WM_GETICON,
                Some(windows::Win32::Foundation::WPARAM(ICON_BIG as usize)),
                Some(windows::Win32::Foundation::LPARAM(0)),
            );
            hicon = HICON(result.0 as *mut _);
            if hicon.0 == std::ptr::null_mut() {
                let ptr = GetClassLongPtrW(hwnd, GCLP_HICON);
                hicon = HICON(ptr as *mut _);
            }
            if hicon.0 != std::ptr::null_mut() {
                println!("获取到窗口图标 (HICON = {:?})", hicon);
                // 可以用 DrawIconEx / 保存为文件
            } else {
                println!("未能获取窗口图标");
            }
        }
    }

    unsafe fn save_bitmap(hbitmap: HBITMAP, width: i32, height: i32, path: &str) {
        let mut bmp: BITMAP = std::mem::zeroed();
        GetObjectW(
            hbitmap.into(),
            std::mem::size_of::<BITMAP>() as i32,
            Some(&mut bmp as *mut _ as *mut c_void),
        );

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
        GetBitmapBits(
            hbitmap,
            image_size as i32,
            buffer.as_mut_ptr() as *mut c_void,
        );

        let mut file = File::create(path).unwrap();
        use std::io::Write;
        use std::slice;

        // 转换为字节数组而不使用bytemuck
        let file_header_bytes = unsafe {
            slice::from_raw_parts(
                &file_header as *const _ as *const u8,
                std::mem::size_of::<BITMAPFILEHEADER>(),
            )
        };
        let info_header_bytes = unsafe {
            slice::from_raw_parts(
                &info_header as *const _ as *const u8,
                std::mem::size_of::<BITMAPINFOHEADER>(),
            )
        };

        file.write_all(file_header_bytes).unwrap();
        file.write_all(info_header_bytes).unwrap();
        file.write_all(&buffer).unwrap();
    }

    #[test]
    fn test_save_frontend_window_screenshot() {
        unsafe {
            let hwnd: HWND = GetForegroundWindow();
            if hwnd.0 == std::ptr::null_mut() {
                println!("未找到前台窗口");
                return;
            }

            // 获取窗口标题用于调试
            let mut title_buf = [0u16; 512];
            let title_len = GetWindowTextW(hwnd, &mut title_buf);
            let title = OsString::from_wide(&title_buf[..title_len as usize])
                .to_string_lossy()
                .into_owned();
            println!("正在截图窗口: {}", title);

            let mut rect = RECT::default();
            if GetWindowRect(hwnd, &mut rect).is_err() {
                println!("无法获取窗口矩形");
                return;
            }

            let width = rect.right - rect.left;
            let height = rect.bottom - rect.top;
            println!("窗口尺寸: {}x{}", width, height);

            if width <= 0 || height <= 0 {
                println!("窗口尺寸无效");
                return;
            }

            // 方法1：尝试使用PrintWindow（推荐方法）
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

            // 使用屏幕DC进行截图（更可靠的方法）
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

            if blt_result.is_err() {
                println!("BitBlt失败");
            } else {
                println!("截图成功");
            }

            // 保存为 BMP
            save_bitmap(hbitmap, width, height, "screenshot.bmp");
            println!("截图已保存为 screenshot.bmp");

            // 清理资源
            SelectObject(hdc_mem, old_bitmap);
            ReleaseDC(Some(hwnd), hdc_window);
            let _ = DeleteDC(hdc_mem);
            let _ = DeleteObject(hbitmap.into());
        }
    }

    #[test]
    fn test_windows_ocr() -> anyhow::Result<()> {
        println!("OCR测试开始");

        // 创建 OCR 引擎
        let language_tag = HSTRING::from("en-US");
        let engine = OcrEngine::TryCreateFromLanguage(&Language::CreateLanguage(&language_tag)?)
            .map_err(|e| anyhow::anyhow!("OCR引擎创建失败: {:?}", e))?;
        println!("OCR引擎创建成功");

        // 获取当前工作目录的绝对路径
        let current_dir = env::current_dir()?;
        let screenshot_path = current_dir.join("screenshot.bmp");
        let absolute_path = screenshot_path.to_string_lossy().to_string();

        println!("尝试加载图像文件: {}", absolute_path);

        // 检查文件是否存在
        if !screenshot_path.exists() {
            println!("截图文件不存在，请先运行 test_save_frontend_window_screenshot 测试");
            anyhow::bail!("截图文件不存在");
        }

        // 加载文件
        let file_path = HSTRING::from(absolute_path);
        let file_async = StorageFile::GetFileFromPathAsync(&file_path)
            .map_err(|e| anyhow::anyhow!("StorageFile 创建失败: {:?}", e))?;
        let file = file_async
            .get()
            .map_err(|e| anyhow::anyhow!("文件获取失败: {:?}", e))?;
        println!("文件加载成功，开始OCR处理");

        // 打开文件流
        let stream_async = file
            .OpenAsync(FileAccessMode::Read)
            .map_err(|e| anyhow::anyhow!("创建文件流任务失败: {:?}", e))?;
        let stream = stream_async
            .get()
            .map_err(|e| anyhow::anyhow!("获取文件流失败: {:?}", e))?;
        println!("文件流打开成功");

        // 创建位图解码器
        let decoder_async = BitmapDecoder::CreateAsync(&stream)
            .map_err(|e| anyhow::anyhow!("创建解码器任务失败: {:?}", e))?;
        let decoder = decoder_async
            .get()
            .map_err(|e| anyhow::anyhow!("获取解码器失败: {:?}", e))?;
        println!("位图解码器创建成功");

        // 获取软件位图
        let bitmap_async = decoder
            .GetSoftwareBitmapAsync()
            .map_err(|e| anyhow::anyhow!("创建位图任务失败: {:?}", e))?;
        let bitmap = bitmap_async
            .get()
            .map_err(|e| anyhow::anyhow!("获取位图失败: {:?}", e))?;
        println!("位图获取成功，开始OCR识别");

        // 执行 OCR 识别
        let result_async = engine
            .RecognizeAsync(&bitmap)
            .map_err(|e| anyhow::anyhow!("创建OCR识别任务失败: {:?}", e))?;
        let result = result_async
            .get()
            .map_err(|e| anyhow::anyhow!("OCR识别失败: {:?}", e))?;

        println!("\n=== OCR识别完成 ===");

        // 获取识别角度
        if let Ok(angle) = result.TextAngle() {
            println!("文本角度: {:?}度", angle);
        } else {
            println!("无法获取文本角度");
        }

        // 获取所有文本
        if let Ok(full_text) = result.Text() {
            println!("完整文本: {}", full_text);
        } else {
            println!("无法获取完整文本");
        }

        // 按行解析结果
        let lines = result
            .Lines()
            .map_err(|e| anyhow::anyhow!("无法获取行列表: {:?}", e))?;

        println!("\n=== 按行解析结果 ===");
        let line_count = lines.Size().unwrap_or(0);
        println!("共检测到 {} 行文本", line_count);

        for i in 0..line_count {
            if let Ok(line) = lines.GetAt(i) {
                println!("\n--- 第 {} 行 ---", i + 1);

                // 获取行文本
                if let Ok(line_text) = line.Text() {
                    println!("  文本内容: '{}'", line_text);
                } else {
                    println!("  无法获取行文本");
                }

                // 获取行的单词
                if let Ok(words) = line.Words() {
                    let word_count = words.Size().unwrap_or(0);
                    println!("  包含 {} 个单词:", word_count);

                    for j in 0..word_count {
                        if let Ok(word) = words.GetAt(j) {
                            if let Ok(word_text) = word.Text() {
                                print!("    单词 {}: '{}'", j + 1, word_text);

                                // 获取单词的边界框
                                if let Ok(rect) = word.BoundingRect() {
                                    println!(
                                        " (位置: x={:.1}, y={:.1}, w={:.1}, h={:.1})",
                                        rect.X, rect.Y, rect.Width, rect.Height
                                    );
                                } else {
                                    println!("");
                                }
                            } else {
                                println!("    无法获取单词 {} 的文本", j + 1);
                            }
                        }
                    }
                } else {
                    println!("  无法获取单词列表");
                }
            }
        }

        println!("\n=== OCR解析完成 ===");
        Ok(())
    }

    #[test]
    fn print_supported_languages() -> anyhow::Result<()> {
        let r = OcrEngine::AvailableRecognizerLanguages()?;
        for i in r {
            println!("{:?}", i.DisplayName());
        }

        anyhow::Ok(())
    }
}
