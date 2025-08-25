#[allow(unused_imports)]
#[allow(dead_code)]
#[allow(unused_variables)]
#[cfg(target_os = "windows")]
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

                // 从路径中提取程序名称（包含扩展名）
                if let Some(program_name_with_ext) = std::path::Path::new(&exe_path).file_name() {
                    let program_name_with_ext = program_name_with_ext.to_string_lossy();
                    println!("程序名称（含扩展名）: {}", program_name_with_ext);

                    // 提取不含扩展名的程序名称
                    if let Some(program_name) = std::path::Path::new(&exe_path).file_stem() {
                        let program_name = program_name.to_string_lossy();
                        println!("程序名称（不含扩展名）: {}", program_name);
                    }
                }
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
        use crate::spy::platform::WindowCapture;

        unsafe {
            let hwnd: HWND = GetForegroundWindow();
            if hwnd.0 == std::ptr::null_mut() {
                println!("未找到前台窗口");
                return;
            }

            // 使用专门的WindowCapture进行截图
            match WindowCapture::capture_window(hwnd, "./screenshots") {
                Ok(file_path) => {
                    println!("截图测试成功！文件保存在: {}", file_path);
                }
                Err(error) => {
                    println!("截图测试失败: {}", error);
                }
            }
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

    #[test]
    fn test_application_provider() {
        use crate::spy::model::{Application, ApplicationProvider};

        unsafe {
            // 获取前台窗口
            let hwnd = GetForegroundWindow();
            if hwnd.0 != std::ptr::null_mut() {
                // 使用ApplicationProvider创建Application实例
                if let Some(app) = Application::from_process(hwnd) {
                    println!("=== ApplicationProvider 测试结果 ===");
                    println!("应用名称（稳定标识符）: {}", app.name);
                    println!("窗口标题（动态变化）: {}", app.title);
                    println!("应用路径: {}", app.path);

                    // 显示name和title的区别
                    println!("\n=== Name vs Title 对比 ===");
                    println!("name字段（从路径提取，稳定不变）: '{}'", app.name);
                    println!("title字段（窗口标题，动态变化）: '{}'", app.title);

                    if app.name != app.title {
                        println!("✓ name和title不同，说明成功区分了应用标识符和窗口标题");
                    } else {
                        println!("⚠ name和title相同，可能是从title提取的fallback结果");
                    }

                    // 测试图标获取
                    match &app.icon {
                        Some(icon_base64) => {
                            println!("\n=== 图标信息 ===");
                            println!("图标获取成功！");
                            println!("图标base64长度: {} 字节", icon_base64.len());
                            if icon_base64.len() > 100 {
                                println!("图标base64前100字符: {}...", &icon_base64[..100]);
                            } else {
                                println!("图标base64: {}", icon_base64);
                            }
                            println!("可以将此base64字符串保存到数据库中。");
                        }
                        None => println!("\n未获取到图标（这是正常情况，某些应用可能没有图标）"),
                    }

                    // 验证从路径提取的程序名
                    if !app.path.is_empty() {
                        if let Some(program_name) = std::path::Path::new(&app.path).file_stem() {
                            let extracted_name = program_name.to_string_lossy();
                            println!("\n=== 路径验证 ===");
                            println!("从路径提取的程序名: {}", extracted_name);
                            if app.name == extracted_name {
                                println!("✓ name字段与路径提取结果一致");
                            } else {
                                println!("⚠ name字段与路径提取结果不一致，可能使用了fallback逻辑");
                            }
                        }
                    } else {
                        println!("\n=== 路径验证 ===");
                        println!("⚠ 未获取到应用路径，name字段使用了从title提取的fallback值");
                    }
                } else {
                    println!("无法从前台窗口创建Application实例");
                }
            } else {
                println!("没有找到前台窗口");
            }
        }
    }

    use sysinfo::System;
    #[test]
    fn test_start_time() {
        // 方法1：使用Windows API获取准确的开机时间
        let (uptime_ms, uptime_seconds) = unsafe {
            use windows::Win32::System::SystemInformation::GetTickCount64;

            // GetTickCount64 返回系统启动以来的毫秒数
            let uptime_ms = GetTickCount64();
            let uptime_seconds = uptime_ms / 1000;

            (uptime_ms, uptime_seconds)
        };

        println!("系统已运行 {} 秒 ({} 毫秒)", uptime_seconds, uptime_ms);

        // 计算开机时间
        let boot_time = chrono::Utc::now() - chrono::Duration::milliseconds(uptime_ms as i64);
        let boot_time_local = boot_time.with_timezone(&chrono::Local);

        println!("开机时间 (UTC): {}", boot_time.format("%Y-%m-%d %H:%M:%S"));
        println!(
            "开机时间 (本地): {}",
            boot_time_local.format("%Y-%m-%d %H:%M:%S")
        );

        // 方法2：使用sysinfo作为对比
        let mut sys = sysinfo::System::new_all();
        sys.refresh_all();

        let sysinfo_uptime = sysinfo::System::uptime();
        println!("\n=== sysinfo库结果（对比用）===");
        println!("sysinfo显示运行时间: {} 秒", sysinfo_uptime);

        let sysinfo_boot_time =
            chrono::Utc::now() - chrono::Duration::seconds(sysinfo_uptime as i64);
        let sysinfo_boot_time_local = sysinfo_boot_time.with_timezone(&chrono::Local);

        println!(
            "sysinfo推算开机时间 (UTC): {}",
            sysinfo_boot_time.format("%Y-%m-%d %H:%M:%S")
        );
        println!(
            "sysinfo推算开机时间 (本地): {}",
            sysinfo_boot_time_local.format("%Y-%m-%d %H:%M:%S")
        );

        // 显示两种方法的差异
        let difference = (sysinfo_uptime as i64) - (uptime_ms / 1000) as i64;
        println!("\n两种方法的时间差异: {} 秒", difference);

        // 方法3：使用更精确的Windows性能计数器方法
        unsafe {
            use windows::Win32::System::Performance::{
                QueryPerformanceCounter, QueryPerformanceFrequency,
            };

            let mut frequency = 0i64;
            let mut counter = 0i64;

            if QueryPerformanceFrequency(&mut frequency).is_ok()
                && QueryPerformanceCounter(&mut counter).is_ok()
            {
                println!("\n=== 高精度计数器信息 ===");
                println!("计数器频率: {} Hz", frequency);
                println!("当前计数器值: {}", counter);

                // 注意：QueryPerformanceCounter不能直接用于获取开机时间
                // 它只能用于高精度时间测量，这里仅作为参考
            }
        }

        println!("\n=== 结论 ===");
        println!("建议使用Windows API (GetTickCount64)方法获取准确的系统运行时间。");
        println!("如果sysinfo结果差异较大，可能是库的实现问题。");
    }
}
