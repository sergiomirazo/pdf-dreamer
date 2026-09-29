import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class FileAssociationService {
  static const _appName = 'pdf_dreamer';
  static const _extensions = [
    '.pdf',
    '.md',
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  ];
  static const _hkeyCurrentUser = -2147483647;
  static const _keyWrite = 0x20006;
  static const _regSz = 1;

  static Future<void> registerFileAssociations() async {
    if (!Platform.isWindows) {
      return;
    }

    final advapi32 = DynamicLibrary.open('advapi32.dll');

    final regCreateKey = advapi32.lookupFunction<
        _RegCreateKeyExNative, _RegCreateKeyExDart>('RegCreateKeyExW');
    final regSetValue = advapi32.lookupFunction<
        _RegSetValueExNative, _RegSetValueExDart>('RegSetValueExW');
    final regCloseKey = advapi32.lookupFunction<
        _RegCloseKeyNative, _RegCloseKeyDart>('RegCloseKey');

    final exePath = Platform.resolvedExecutable;
    final appKeyPath =
        'Software\\Classes\\Applications\\$_appName.exe';
    final commandKeyPath = '$appKeyPath\\shell\\open\\command';

    _setRegistryValue(
      regCreateKey, regSetValue, regCloseKey,
      null, commandKeyPath, '', '"$exePath" "%1"',
    );

    final supportedTypesPath = '$appKeyPath\\SupportedTypes';
    for (final ext in _extensions) {
      _setRegistryValue(
        regCreateKey, regSetValue, regCloseKey,
        null, supportedTypesPath, ext, '',
      );
    }
  }

  static void _setRegistryValue(
    _RegCreateKeyExDart regCreateKey,
    _RegSetValueExDart regSetValue,
    _RegCloseKeyDart regCloseKey,
    String? rootPath,
    String subPath,
    String valueName,
    String value,
  ) {
    final fullPath = rootPath != null ? '$rootPath\\$subPath' : subPath;
    final subKeyPtr = fullPath.toNativeUtf16();
    final phkResult = calloc<IntPtr>();

    try {
      final createResult = regCreateKey(
        _hkeyCurrentUser,
        subKeyPtr,
        0,
        nullptr,
        0,
        _keyWrite,
        nullptr,
        phkResult,
        nullptr,
      );

      if (createResult == 0 && phkResult.value != 0) {
        final valueNamePtr = valueName.toNativeUtf16();
        final valuePtr = value.toNativeUtf16();
        final valueBytes = (value.length + 1) * 2;

        try {
          regSetValue(
            phkResult.value,
            valueName.isEmpty ? nullptr : valueNamePtr,
            0,
            _regSz,
            valuePtr.cast<Void>(),
            valueBytes,
          );
        } finally {
          calloc.free(valueNamePtr);
          calloc.free(valuePtr);
        }

        regCloseKey(phkResult.value);
      }
    } finally {
      calloc.free(subKeyPtr);
      calloc.free(phkResult);
    }
  }
}

typedef _RegCreateKeyExNative = Int32 Function(
  IntPtr hKey,
  Pointer<Utf16> lpSubKey,
  Uint32 reserved,
  Pointer<Utf16> lpClass,
  Uint32 dwOptions,
  Uint32 samDesired,
  Pointer<Void> lpSecurityAttributes,
  Pointer<IntPtr> phkResult,
  Pointer<Uint32> lpdwDisposition,
);
typedef _RegCreateKeyExDart = int Function(
  int hKey,
  Pointer<Utf16> lpSubKey,
  int reserved,
  Pointer<Utf16> lpClass,
  int dwOptions,
  int samDesired,
  Pointer<Void> lpSecurityAttributes,
  Pointer<IntPtr> phkResult,
  Pointer<Uint32> lpdwDisposition,
);

typedef _RegSetValueExNative = Int32 Function(
  IntPtr hKey,
  Pointer<Utf16> lpValueName,
  Uint32 reserved,
  Uint32 dwType,
  Pointer<Void> lpData,
  Uint32 cbData,
);
typedef _RegSetValueExDart = int Function(
  int hKey,
  Pointer<Utf16> lpValueName,
  int reserved,
  int dwType,
  Pointer<Void> lpData,
  int cbData,
);

typedef _RegCloseKeyNative = Int32 Function(IntPtr hKey);
typedef _RegCloseKeyDart = int Function(int hKey);
