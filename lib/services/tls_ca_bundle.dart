/// Linux port: 系统 libmpv（OpenSSL / GnuTLS）自动读 /etc/ssl/certs，
/// 不需要 App 注入一份静态、会过期的 Mozilla 根证书库。
/// 保留原有 public API，避免调用点与测试断裂。
class TlsCaBundle {
  /// 仅为兼容可能的测试断言保留；Linux 上不再读取该 asset。
  static const String assetPath = 'assets/certs/cacert.pem';
  static const String fileName = 'cacert.pem';

  /// 恒返回 null：buildMpvTuning 会跳过 `tls-ca-file`。
  static Future<String?> ensurePath() async => null;

  static void resetForTest() {}
}
