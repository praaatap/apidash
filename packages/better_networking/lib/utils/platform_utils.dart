import 'dart:io';

/// Pure Dart compile-time check for web platform.
/// Equivalent to Flutter's kIsWeb but without Flutter dependency.
const bool kIsWeb = bool.fromEnvironment('dart.library.js_interop');

/// Platform detection utilities for the better_networking package.
class PlatformUtils {
  /// Returns true if running on desktop platforms (macOS, Windows, Linux).
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Returns true if running on mobile platforms (iOS, Android).
  static bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Returns true if running on web.
  static bool get isWeb => kIsWeb;

  /// Returns true if OAuth should use localhost callback server.
  /// This is true for desktop platforms.
  static bool get shouldUseLocalhostCallback => isDesktop;
}
