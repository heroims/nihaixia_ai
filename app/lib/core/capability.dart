/// 设备算力检测：低内存机型禁用 LLM（M5 的降级点）。
class DeviceCapability {
  /// 占位：后续接 DeviceInfoPlugin。当前按 4GB 阈值。
  static bool get canRunLocalLlm {
    // Android: 通过 ActivityManager.getMemoryClass()；iOS: processInfo
    // 简化：统一返回 true，由 LlmService.isAvailable（模型文件存在）二次把关。
    return true;
  }
}