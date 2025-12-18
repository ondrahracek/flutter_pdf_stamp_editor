# Files to Delete

This file lists all files and directories that should be deleted to clean up the repository.

## Deprecated Source Files (No Longer Used)

These files are from the old FFI-based implementation and are replaced by the MethodChannel architecture:

1. `lib/src/engine/stamper_ffi.dart` - Replaced by `stamper_platform.dart`
2. `lib/src/engine/pdfium_loader.dart` - No longer needed
3. `lib/src/pdfium_native_save.dart` - No longer needed

## Example App Code in Plugin Root

4. `android/app/` - Entire directory (this is example app code, not plugin code)
   - Contains: `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`

## Test/Temporary Files

5. `viewer.pdf` - Test PDF file (large binary, shouldn't be in repository)

## Empty Directories

6. `android/src/main/cpp/` - Empty directory (native C++ code was removed)
7. `android/src/main/java/com/ondrahracek/pdf_stamp_editor/` - Empty directory (Java plugin replaced by Kotlin)

## Verification Commands

After deletion, verify with:

```bash
# Check for any remaining references to deleted files
grep -r "stamper_ffi" lib/
grep -r "pdfium_loader" lib/
grep -r "pdfium_native_save" lib/

# Verify empty directories are gone
ls -la android/src/main/cpp/
ls -la android/src/main/java/com/ondrahracek/pdf_stamp_editor/

# Check that viewer.pdf is gone
ls viewer.pdf
```

## Summary

- **3 deprecated source files** to delete
- **1 example app directory** to delete (`android/app/`)
- **1 test file** to delete (`viewer.pdf`)
- **2 empty directories** to remove

Total: 7 items to delete/remove

