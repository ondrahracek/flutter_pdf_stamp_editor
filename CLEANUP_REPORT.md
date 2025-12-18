# Repository Cleanup Report

This report identifies files and directories that should be:
1. Added to `.gitignore`
2. Added to `.pubignore` (for pub.dev publishing)
3. Deleted from the repository

## Files to Add to `.gitignore`

### User-Specific Configuration Files
- `android/local.properties` - Contains user-specific Android SDK paths
- `example/android/local.properties` - Contains user-specific paths for example app

### IDE Files
- `*.iml` files (IntelliJ IDEA project files):
  - `pdf_stamp_editor.iml`
  - `example/pdf_stamp_editor_example.iml`
  - `example/android/pdf_stamp_editor_example_android.iml`

### Test/Temporary Files
- `viewer.pdf` - Test PDF file, shouldn't be in repository

### Note
The root `.gitignore` already covers:
- `build/` directories
- `pubspec.lock` (for libraries)
- `.dart_tool/`
- Most other standard Flutter ignores

## Files to Add to `.pubignore` (for pub.dev publishing)

Create a `.pubignore` file to exclude these from the published package:

```
# Example app (not part of the package)
example/

# Tests (not published to pub.dev)
test/

# Example-specific Android code
android/app/

# Deprecated/unused source files (if not deleted)
lib/src/engine/stamper_ffi.dart
lib/src/engine/pdfium_loader.dart
lib/src/pdfium_native_save.dart

# Build artifacts
build/
**/build/

# IDE files
*.iml
.idea/
.vscode/

# Local configuration
**/local.properties

# Test files
viewer.pdf

# Generated files
**/GeneratedPluginRegistrant.java
```

## Files to DELETE

### Deprecated Source Files (No Longer Used)
These files are from the old FFI-based implementation and are no longer imported or used:

1. **`lib/src/engine/stamper_ffi.dart`**
   - Reason: Replaced by `stamper_platform.dart` (MethodChannel-based)
   - Status: Not imported anywhere in active code

2. **`lib/src/engine/pdfium_loader.dart`**
   - Reason: No longer needed with MethodChannel architecture
   - Status: Only imported by deprecated `stamper_ffi.dart`

3. **`lib/src/pdfium_native_save.dart`**
   - Reason: No longer needed with MethodChannel architecture
   - Status: Only imported by deprecated `stamper_ffi.dart`

### Generated Files (Should Not Be in Repository)
4. **`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`**
   - Reason: This is a generated file from the example app, not plugin code
   - Location: Should only exist in example app, not plugin root
   - Note: This entire `android/app/` directory structure shouldn't exist in the plugin

### Test/Temporary Files
5. **`viewer.pdf`**
   - Reason: Test file, shouldn't be in repository
   - Size: Large binary file (37,001 lines)

### Empty Directories
6. **`android/src/main/cpp/`**
   - Reason: Empty directory (native C++ code was removed)
   
7. **`android/src/main/java/com/ondrahracek/pdf_stamp_editor/`**
   - Reason: Empty directory (Java plugin was replaced by Kotlin)

## Summary

### Immediate Actions Required:

1. **Update `.gitignore`** to include:
   - `**/local.properties`
   - `*.iml`
   - `viewer.pdf`

2. **Create `.pubignore`** with the contents listed above

3. **Delete deprecated files:**
   - `lib/src/engine/stamper_ffi.dart`
   - `lib/src/engine/pdfium_loader.dart`
   - `lib/src/pdfium_native_save.dart`
   - `viewer.pdf`
   - `android/app/` (entire directory - this is example app code, not plugin)

4. **Remove empty directories:**
   - `android/src/main/cpp/`
   - `android/src/main/java/com/ondrahracek/pdf_stamp_editor/`

### Files to Keep (But Exclude from pub.dev):

- `example/` - Keep in repo, exclude from pub.dev
- `test/` - Keep in repo, exclude from pub.dev
- `CHANGELOG.md` - Keep and publish
- `LICENSE` - Keep and publish
- `README.md` - Keep and publish

### Verification:

After cleanup, verify:
- ✅ No deprecated FFI code remains
- ✅ No example app code in plugin root
- ✅ No user-specific configuration files tracked
- ✅ No IDE files tracked
- ✅ No test/temporary files tracked
- ✅ Package structure is clean and publishable

