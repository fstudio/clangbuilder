////
#include "blast.hpp"
#include <Dbghelp.h>
#include <map>

#ifndef PROCESSOR_ARCHITECTURE_ARM64
#define PROCESSOR_ARCHITECTURE_ARM64 12
#endif
#ifndef PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64
#define PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64 13
#endif
#ifndef PROCESSOR_ARCHITECTURE_IA32_ON_ARM64
#define PROCESSOR_ARCHITECTURE_IA32_ON_ARM64 14
#endif

#ifndef IMAGE_FILE_MACHINE_TARGET_HOST
#define IMAGE_FILE_MACHINE_TARGET_HOST                                         \
  0x0001 // Useful for indicating we want to interact with the host and not a
         // WoW guest.
#endif

/// #define PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64   13
#ifndef IMAGE_FILE_MACHINE_ARM64
//// IMAGE_FILE_MACHINE_ARM64 is Windows
#define IMAGE_FILE_MACHINE_ARM64 0xAA64 // ARM64 Little-Endian
#endif
#ifndef IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG
#define IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG 17 // XBOX Code Catalog
#endif

using PEView = std::map<std::wstring, std::wstring>;

class Memview {
public:
  Memview() = default;
  Memview(const Memview &) = delete;
  Memview &operator=(const Memview &) = delete;
  ~Memview() {
    if (ismaped) {
      UnmapViewOfFile(hMap);
    }
    if (hMap != INVALID_HANDLE_VALUE) {
      CloseHandle(hMap);
    }
    if (hFile != INVALID_HANDLE_VALUE) {
      CloseHandle(hFile);
    }
  }
  bool Fileview(const std::wstring &path) {
    hFile = CreateFileW(path.data(), GENERIC_READ, FILE_SHARE_READ, NULL,
                        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
      return false;
    }
    LARGE_INTEGER li;
    if (GetFileSizeEx(hFile, &li)) {
      filesize = li.QuadPart;
    }
    hMap = CreateFileMappingW(hFile, nullptr, PAGE_READONLY, 0, 0, nullptr);
    if (hMap == INVALID_HANDLE_VALUE) {
      return false;
    }
    baseAddress = ::MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    if (baseAddress == nullptr) {
      return false;
    }
    ismaped = true;
    return true;
  }
  int64_t FileSize() const { return filesize; }
  char *BaseAddress() { return reinterpret_cast<char *>(baseAddress); }

private:
  HANDLE hFile{INVALID_HANDLE_VALUE};
  HANDLE hMap{INVALID_HANDLE_VALUE};
  LPVOID baseAddress{nullptr};
  int64_t filesize{0};
  bool ismaped{false};
};

HMODULE KrModule() {
  static HMODULE hModule = GetModuleHandleW(L"kernel32.dll");
  if (hModule == nullptr) {
    OutputDebugStringW(L"GetModuleHandleA failed");
  }
  return hModule;
}

#ifndef _M_X64
class FsRedirection {
public:
  typedef BOOL WINAPI fntype_Wow64DisableWow64FsRedirection(PVOID *OldValue);
  typedef BOOL WINAPI fntype_Wow64RevertWow64FsRedirection(PVOID *OldValue);
  FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64DisableWow64FsRedirection =
        (fntype_Wow64DisableWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64DisableWow64FsRedirection");
    if (pfnWow64DisableWow64FsRedirection) {
      pfnWow64DisableWow64FsRedirection(&OldValue);
    }
  }
  ~FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64RevertWow64FsRedirection =
        (fntype_Wow64RevertWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64RevertWow64FsRedirection");
    if (pfnWow64RevertWow64FsRedirection) {
      pfnWow64RevertWow64FsRedirection(&OldValue);
    }
  }

private:
  PVOID OldValue = NULL;
};
#endif

struct VALUE_STRING {
  int index;
  const wchar_t *str;
};

const VALUE_STRING archList[] = {
    {PROCESSOR_ARCHITECTURE_INTEL, L"Win32"},
    {PROCESSOR_ARCHITECTURE_MIPS, L"MIPS"},
    {PROCESSOR_ARCHITECTURE_ALPHA, L"Alpha"},
    {PROCESSOR_ARCHITECTURE_PPC, L"PPC"},
    {PROCESSOR_ARCHITECTURE_SHX, L"SHX"},
    {PROCESSOR_ARCHITECTURE_ARM, L"ARM"},
    {PROCESSOR_ARCHITECTURE_IA64, L"IA64"},
    {PROCESSOR_ARCHITECTURE_ALPHA64, L"Alpha64"},
    {PROCESSOR_ARCHITECTURE_MSIL, L"MSIL"},
    {PROCESSOR_ARCHITECTURE_AMD64, L"Win64"},
    {PROCESSOR_ARCHITECTURE_IA32_ON_WIN64, L"Wow64"},
    {PROCESSOR_ARCHITECTURE_NEUTRAL, L"Neutral"},
    {PROCESSOR_ARCHITECTURE_ARM64, L"ARM64"},
    {PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64, L"ARM32-Win64"},
    {PROCESSOR_ARCHITECTURE_IA32_ON_ARM64, L"IA32-ARM64"},
};

const wchar_t *ArchitectureName(int id) {
  for (auto &x : archList) {
    if (x.index == id)
      return x.str;
  }
  return L"Unknown";
}

const VALUE_STRING machineTable[] = {
    {IMAGE_FILE_MACHINE_UNKNOWN, L"Unknown Machine"},
    {IMAGE_FILE_MACHINE_TARGET_HOST, L"WoW Gest"},
    {IMAGE_FILE_MACHINE_I386, L"Intel 386"},
    {IMAGE_FILE_MACHINE_R3000, L"MIPS little-endian, 0x160 big-endian"},
    {IMAGE_FILE_MACHINE_R4000, L"MIPS little-endian"},
    {IMAGE_FILE_MACHINE_R10000, L"MIPS little-endian"},
    {IMAGE_FILE_MACHINE_WCEMIPSV2, L"MIPS little-endian WCE v2"},
    {IMAGE_FILE_MACHINE_ALPHA, L"Alpha_AXP"},
    {IMAGE_FILE_MACHINE_SH3, L"SH3 little-endian"},
    {IMAGE_FILE_MACHINE_SH3DSP, L"SH3 DSP"},
    {IMAGE_FILE_MACHINE_SH3E, L"SH3E little-endian"},
    {IMAGE_FILE_MACHINE_SH4, L"SH4 little-endian"},
    {IMAGE_FILE_MACHINE_SH5, L"SH5"},
    {IMAGE_FILE_MACHINE_ARM, L"ARM Little-Endian"},
    {IMAGE_FILE_MACHINE_THUMB, L"ARM Thumb/Thumb-2 Little-Endian"},
    {IMAGE_FILE_MACHINE_ARMNT, L"ARM Thumb-2 Little-Endian"},
    {IMAGE_FILE_MACHINE_AM33, L"Matsushita AM33"},
    {IMAGE_FILE_MACHINE_POWERPC, L"IBM PowerPC Little-Endian"},
    {IMAGE_FILE_MACHINE_POWERPCFP, L"IBM PowerPC  (FP support)"},
    {IMAGE_FILE_MACHINE_IA64, L"Intel IA64"},
    {IMAGE_FILE_MACHINE_MIPS16, L"MIPS"},
    {IMAGE_FILE_MACHINE_ALPHA64, L"ALPHA64"},
    {IMAGE_FILE_MACHINE_MIPSFPU, L"MIPS"},
    {IMAGE_FILE_MACHINE_MIPSFPU16, L"MIPS"},
    {IMAGE_FILE_MACHINE_TRICORE, L"Infineon"},
    {IMAGE_FILE_MACHINE_CEF, L"IMAGE_FILE_MACHINE_CEF"},
    {IMAGE_FILE_MACHINE_EBC, L"EFI Byte Code"},
    {IMAGE_FILE_MACHINE_AMD64, L"AMD64 (K8)"},
    {IMAGE_FILE_MACHINE_M32R, L"M32R little-endian"},
    {IMAGE_FILE_MACHINE_ARM64, L"ARM64 Little-Endian"},
    {IMAGE_FILE_MACHINE_CEE, L"IMAGE_FILE_MACHINE_CEE"}};

const VALUE_STRING subsystemTable[] = {
    {IMAGE_SUBSYSTEM_UNKNOWN, L"Unknown subsystem"},
    {IMAGE_SUBSYSTEM_NATIVE, L"Native"}, // not require subsystem
    {IMAGE_SUBSYSTEM_WINDOWS_GUI, L"Windows GUI"},
    {IMAGE_SUBSYSTEM_WINDOWS_CUI, L"Windows CUI"},
    {IMAGE_SUBSYSTEM_OS2_CUI, L"OS/2  CUI"},
    {IMAGE_SUBSYSTEM_POSIX_CUI, L"Posix character subsystem"},
    {IMAGE_SUBSYSTEM_NATIVE_WINDOWS, L"Native Win9x driver"},
    {IMAGE_SUBSYSTEM_WINDOWS_CE_GUI, L"Windows CE subsystem"},
    {IMAGE_SUBSYSTEM_EFI_APPLICATION, L"EFI Application"},
    {IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER, L"EFI Boot Service Driver"},
    {IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER, L"EFI Runtime Driver"},
    {IMAGE_SUBSYSTEM_EFI_ROM, L"EFI ROM"},
    {IMAGE_SUBSYSTEM_XBOX, L"Xbox system"},
    {IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION, L"Windows Boot Application"},
    {IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG, L"XBOX Code Catalog"}};

class PortableExecutableFile {
public:
  PortableExecutableFile() = default;
  PortableExecutableFile(const PortableExecutableFile &) = delete;
  PortableExecutableFile &operator=(const PortableExecutableFile &) = delete;
  const PEView &View() const {
    //
    return peview;
  }
  bool Analyze(const std::wstring &file) {
#ifndef _M_X64
    FsRedirection fsr;
#endif
    constexpr const int64_t minsize =
        sizeof(IMAGE_DOS_HEADER) + sizeof(IMAGE_NT_HEADERS);
    if (!mv.Fileview(file)) {
      return false;
    }
    if (mv.FileSize() < minsize) {
      return false;
    }
    auto dh = reinterpret_cast<IMAGE_DOS_HEADER *>(mv.BaseAddress());
    if (minsize + dh->e_lfanew >= mv.FileSize()) {
      return false;
    }
    auto nh =
        reinterpret_cast<IMAGE_NT_HEADERS *>(mv.BaseAddress() + dh->e_lfanew);
    auto var = nh->FileHeader.Characteristics;
    if ((nh->FileHeader.Characteristics & IMAGE_FILE_DLL) == IMAGE_FILE_DLL) {
      Append(L"Characteristics", L"DLL");
    } else if ((nh->FileHeader.Characteristics & IMAGE_FILE_SYSTEM) ==
               IMAGE_FILE_SYSTEM) {
      Append(L"Characteristics", L"System");
    } else if ((nh->FileHeader.Characteristics & IMAGE_FILE_EXECUTABLE_IMAGE) ==
               IMAGE_FILE_EXECUTABLE_IMAGE) {
      Append(L"Characteristics", L"Exe");
    } else {
      Append(L"Characteristics",
             std::wstring(L"Characteristics value: ") +
                 std::to_wstring(nh->FileHeader.Characteristics));
    }
    for (auto &sub : subsystemTable) {
      if (sub.index == nh->OptionalHeader.Subsystem) {
        Append(L"Subsystem", sub.str);
      }
    }
    for (auto &subm : machineTable) {
      if (subm.index == nh->FileHeader.Machine) {
        Append(L"Machine", subm.str);
      }
    }
    return true;
  }

private:
  void Append(const std::wstring &key, const std::wstring &value) {
    //
    peview.insert(std::pair<std::wstring, std::wstring>(key, value));
  }
  Memview mv;
  PEView peview;
};

void displaype(const PEView &pe) {
  std::wstring buffer;
  buffer.assign(L"{ ");
  for (const auto &field : pe) {
    buffer.append(L"\r\n\t\"")
        .append(field.first)
        .append(L"\" : \"")
        .append(field.second)
        .append(L"\",");
  }
  buffer.pop_back();
  buffer.append(L"\r\n}");
  wprintf(L"%s", buffer.data());
}

int dumpbin(const std::wstring &path) {
  //
  PortableExecutableFile pefile;
  if (!pefile.Analyze(path)) {
    return 1;
  }
  displaype(pefile.View());
  return 0;
}