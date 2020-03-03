#ifndef BAULK_RCWRITER_HPP
#define BAULK_RCWRITER_HPP
#include <string>
#include <string_view>
#include <bela/strcat.hpp>

/*****
//Microsoft Visual C++ generated resource script.
//
#include "windows.h"
/////////////////////////////////////////////////////////////////////////////

//@MANIFEST

VS_VERSION_INFO VERSIONINFO
FILEVERSION @FileMajorPart, @FileMinorPart, @FileBuildPart, @FilePrivatePart
PRODUCTVERSION @FileMajorPart, @FileMinorPart, @FileBuildPart, @FilePrivatePart
FILEFLAGSMASK 0x3fL
#ifdef _DEBUG
FILEFLAGS 0x1L
#else
FILEFLAGS 0x0L
#endif
FILEOS 0x40004L
FILETYPE 0x1L
FILESUBTYPE 0x0L
BEGIN
BLOCK "StringFileInfo"
BEGIN
BLOCK "000904b0"
BEGIN
VALUE "CompanyName", L"@CompanyName"
VALUE "FileDescription", L"@FileDescription"
VALUE "FileVersion", L"@FileVersion"
VALUE "InternalName", L"@InternalName"
VALUE "LegalCopyright", L"@LegalCopyright"
VALUE "OriginalFilename", L"@OriginalFilename"
VALUE "ProductName", L"@ProductName"
VALUE "ProductVersion", L"@ProductVersion"
END
END
BLOCK "VarFileInfo"
BEGIN
VALUE "Translation", 0x9, 1200
END
END

#ifndef APSTUDIO_INVOKED
/////////////////////////////////////////////////////////////////////////////
//
// Generated from the TEXTINCLUDE 3 resource.
//

/////////////////////////////////////////////////////////////////////////////
#endif    // not APSTUDIO_INVOKED

****/

namespace baulk::rc {
class Writer {
public:
  Writer() { buffer.reserve(4096); }
  Writer(const Writer &) = delete;
  Writer &operator=(const Writer &) = delete;
  Writer &Prefix() {
    constexpr std::wstring_view hd =
        L"//Baulk generated resource script.\n#include "
        L"\"windows.h\"\n\nVS_VERSION_INFO VERSIONINFO\n";
    buffer.assign(hd);
    return *this;
  }
  Writer &FileVersion(int MajorPart, int MinorPart, int BuildPart,
                      int PrivatePart) {
    bela::StrAppend(&buffer, L"FILEVERSION ", MajorPart, L", ", MinorPart,
                    L", ", BuildPart, L", ", PrivatePart);
    return *this;
  }
  Writer &ProductVersion(int MajorPart, int MinorPart, int BuildPart,
                         int PrivatePart) {
    bela::StrAppend(&buffer, L"FILEVERSION ", MajorPart, L", ", MinorPart,
                    L", ", BuildPart, L", ", PrivatePart);
    return *this;
  }
  Writer &PreVersion() {
    buffer.append(
        L"FILEFLAGSMASK 0x3fL\nFILEFLAGS 0x0L\nFILEOS 0x40004L\nFILETYPE "
        L"0x1L\nFILESUBTYPE 0x0L\nBEGIN\nBLOCK "
        L"\"StringFileInfo\"\nBEGIN\nBLOCK \"000904b0\"\nBEGIN\n");
    return *this;
  }
  Writer &Version(std::wstring_view name, std::wstring_view value) {
    bela::StrAppend(&buffer, L"VALUE \"", name, L"\" L\"", value, L"\"\n");
    return *this;
  }
  Writer &AfterVersion() {
    buffer.append(L"END\nEND\nBLOCK \"VarFileInfo\"\nBEGIN\nVALUE "
                  L"\"Translation\", 0x9, 1200\nEND\nEND\n\n");
    return *this;
  }
  bool FlushFile(std::wstring_view file) const {
    (void)file;
    return true;
  }

private:
  std::wstring buffer;
};
} // namespace baulk::rc

#endif
