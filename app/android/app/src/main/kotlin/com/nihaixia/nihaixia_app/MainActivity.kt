package com.nihaixia.nihaixia_app

import android.content.res.AssetManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "model_installer")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copyAssetToFile" -> {
                        val asset = call.argument<String>("asset")
                        val dest = call.argument<String>("dest")
                        if (asset == null || dest == null) {
                            result.error("invalid_args", "asset/dest required", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                copyAssetToFile(asset, dest)
                                runOnUiThread { result.success(true) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("copy_failed", e.message, null) }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// 把 APK 内的 Flutter 资产流式复制到应用私有目录。
    ///
    /// 大文件（1.1GB 模型）不能走 rootBundle.load：Dart 单块 TypedData 上限
    /// 2^30-1 字节，超限直接抛错。这里在原生侧分块拷贝，内存占用恒定 256KB。
    private fun copyAssetToFile(assetPath: String, destPath: String) {
        val full = "flutter_assets/$assetPath"
        val dest = File(destPath)
        val tmp = File("$destPath.tmp")
        dest.parentFile?.mkdirs()
        assets.open(full, AssetManager.ACCESS_STREAMING).use { ins ->
            tmp.outputStream().use { outs ->
                val buf = ByteArray(256 * 1024)
                while (true) {
                    val n = ins.read(buf)
                    if (n <= 0) break
                    outs.write(buf, 0, n)
                }
                outs.fd.sync()
            }
        }
        if (!tmp.renameTo(dest)) {
            tmp.delete()
            throw IllegalStateException("rename $tmp -> $dest failed")
        }
    }
}
