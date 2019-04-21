////
#include "pe.hpp"
#include <system_error>
#include <Dbghelp.h>

#pragma comment(lib, "DbgHelp.lib")

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

#ifndef IMAGE_FILE_MACHINE_RISCV32
#define IMAGE_FILE_MACHINE_RISCV32 0x5032
#endif
#ifndef IMAGE_FILE_MACHINE_RISCV64
#define IMAGE_FILE_MACHINE_RISCV64 0x5064
#endif
#ifndef IMAGE_FILE_MACHINE_RISCV128
#define IMAGE_FILE_MACHINE_RISCV128 0x5128
#endif

#ifndef IMAGE_FILE_MACHINE_CHPE_X86
#define IMAGE_FILE_MACHINE_CHPE_X86 0x3A64 /// defined in ntimage.h
#endif

#ifndef IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG
#define IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG 17 // XBOX Code Catalog
#endif

typedef enum ReplacesGeneralNumericDefines {
// Directory entry macro for CLR data.
#ifndef IMAGE_DIRECTORY_ENTRY_COMHEADER
  IMAGE_DIRECTORY_ENTRY_COMHEADER = 14,
#endif // IMAGE_DIRECTORY_ENTRY_COMHEADER
} ReplacesGeneralNumericDefines;
#define STORAGE_MAGIC_SIG 0x424A5342 // BSJB

#pragma pack(1)
struct STORAGESIGNATURE {
  ULONG Signature;     // Magic signature for physical metadata : 0x424A5342.
  USHORT MajorVersion; // Major version, 1 (ignore on read)
  USHORT MinorVersion; // Minor version, 0 (ignore on read)
  ULONG ExtraData;     // offset to next structure of information
  ULONG Length;        // Length of version string in bytes
};
#pragma pack()

namespace pecoff {
struct key_value_t {
  uint32_t index;
  const wchar_t *value;
};

std::wstring Machine(uint32_t index) {
  // https://docs.microsoft.com/en-us/windows/desktop/Debug/pe-format#machine-types
  const key_value_t machines[] = {
      {IMAGE_FILE_MACHINE_UNKNOWN, L"UNKNOWN"},
      {IMAGE_FILE_MACHINE_TARGET_HOST, L"WoW Gest"},
      {IMAGE_FILE_MACHINE_I386, L"Intel 386"},
      {IMAGE_FILE_MACHINE_R3000, L"MIPS little-endian, 0x160 big-endian"},
      {IMAGE_FILE_MACHINE_R4000, L"MIPS little-endian"},
      {IMAGE_FILE_MACHINE_R10000, L"MIPS little-endian"},
      {IMAGE_FILE_MACHINE_WCEMIPSV2, L"MIPS little-endian WCE v2"},
      {IMAGE_FILE_MACHINE_ALPHA, L"Alpha_AXP"},
      {IMAGE_FILE_MACHINE_SH3, L"Hitachi SH3 "},
      {IMAGE_FILE_MACHINE_SH3DSP, L"Hitachi SH3 DSP"},
      {IMAGE_FILE_MACHINE_SH3E, L"Hitachi SH3E"},
      {IMAGE_FILE_MACHINE_SH4, L"Hitachi SH4"},
      {IMAGE_FILE_MACHINE_SH5, L"Hitachi SH5"},
      {IMAGE_FILE_MACHINE_ARM, L"ARM Little-Endian"},
      {IMAGE_FILE_MACHINE_THUMB, L"ARM Thumb/Thumb-2 Little-Endian"},
      {IMAGE_FILE_MACHINE_ARMNT, L"ARM Thumb-2 Little-Endian"},
      {IMAGE_FILE_MACHINE_AM33, L"Matsushita AM33 "},
      {IMAGE_FILE_MACHINE_POWERPC, L"Power PC little endian"},
      {IMAGE_FILE_MACHINE_POWERPCFP, L"Power PC with floating point support "},
      {IMAGE_FILE_MACHINE_IA64, L"Intel Itanium"},
      {IMAGE_FILE_MACHINE_MIPS16, L"MIPS"},
      {IMAGE_FILE_MACHINE_ALPHA64, L"ALPHA64"},
      {IMAGE_FILE_MACHINE_MIPSFPU, L"MIPS with FPU"},
      {IMAGE_FILE_MACHINE_MIPSFPU16, L"MIPS16 with FPU"},
      {IMAGE_FILE_MACHINE_TRICORE, L"Infineon"},
      {IMAGE_FILE_MACHINE_CEF, L"IMAGE_FILE_MACHINE_CEF"},
      {IMAGE_FILE_MACHINE_EBC, L"EFI Byte Code"},
      {IMAGE_FILE_MACHINE_AMD64, L"AMD64 (K8)"},
      {IMAGE_FILE_MACHINE_M32R, L"Mitsubishi M32R little endian "},
      {IMAGE_FILE_MACHINE_ARM64, L"ARM64 Little-Endian"},
      {IMAGE_FILE_MACHINE_CEE, L"IMAGE_FILE_MACHINE_CEE"},
      {IMAGE_FILE_MACHINE_CHPE_X86, L"Hybrid PE"},
      {IMAGE_FILE_MACHINE_RISCV32, L"RISC-V 32-bit"},
      {IMAGE_FILE_MACHINE_RISCV64, L"RISC-V 64-bit"},
      {IMAGE_FILE_MACHINE_RISCV128, L"RISC-V 128-bit"}
      //
  };
  for (const auto &kv : machines) {
    if (kv.index == index) {
      return kv.value;
    }
  }
  return L"UNKNOWN";
}
// https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_image_file_header
std::vector<std::wstring> Characteristics(uint32_t index,
                                          uint32_t dllindex = 0) {
  std::vector<std::wstring> csv;
  const key_value_t cs[] = {
      {IMAGE_FILE_RELOCS_STRIPPED, L"Relocation info stripped"},
      // Relocation info stripped from file.
      {IMAGE_FILE_EXECUTABLE_IMAGE, L"Executable"},
      // File is executable  (i.e. no unresolved external references).
      {IMAGE_FILE_LINE_NUMS_STRIPPED, L"PE line numbers stripped"},
      // Line nunbers stripped from file.
      {IMAGE_FILE_LOCAL_SYMS_STRIPPED, L"Symbol stripped"},
      // Local symbols stripped from file.
      {IMAGE_FILE_AGGRESIVE_WS_TRIM, L"Aggressively trim the working set"},
      // Aggressively trim working set
      {IMAGE_FILE_LARGE_ADDRESS_AWARE, L"Large address aware"},
      // App can handle >2gb addresses
      {IMAGE_FILE_BYTES_REVERSED_LO, L"obsolete"},
      // Bytes of machine word are reversed.
      {IMAGE_FILE_32BIT_MACHINE, L"Support 32-bit words"},
      // 32 bit word machine.
      {IMAGE_FILE_DEBUG_STRIPPED, L"Debug info stripped"},
      // Debugging info stripped from file in .DBG file
      {IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP, L"Removable run from swap"},
      // If Image is on removable media, copy and run from the swap file.
      {IMAGE_FILE_NET_RUN_FROM_SWAP, L"Net run from swap"},
      // If Image is on Net, copy and run from the swap file.
      {IMAGE_FILE_SYSTEM, L"System"},
      // System File.
      {IMAGE_FILE_DLL, L"Dynamic Link Library"},
      // File is a DLL.
      {IMAGE_FILE_UP_SYSTEM_ONLY, L"Uni-processor only"},
      // File should only be run on a UP machine
      {IMAGE_FILE_BYTES_REVERSED_HI, L"obsolete"}
      // Bytes of machine word are reversed.
  };
  // USHORT  DllCharacteristics;
  const key_value_t dcs[] = {
      {IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA, L"High entropy VA"},
      {IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE, L"Dynamic base"},
      {IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY, L"Force integrity check"},
      {IMAGE_DLLCHARACTERISTICS_NX_COMPAT, L"NX compatible"},
      {IMAGE_DLLCHARACTERISTICS_NO_ISOLATION, L"No isolation"},
      {IMAGE_DLLCHARACTERISTICS_NO_SEH, L"No SEH"},
      {IMAGE_DLLCHARACTERISTICS_NO_BIND, L"Do not bind"},
      {IMAGE_DLLCHARACTERISTICS_APPCONTAINER, L"AppContainer"},
      {IMAGE_DLLCHARACTERISTICS_WDM_DRIVER, L"WDM driver"},
      {IMAGE_DLLCHARACTERISTICS_GUARD_CF, L"Control Flow Guard"},
      {IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE, L"Terminal server aware"}
      //
  };
  for (const auto &kv : cs) {
    if ((kv.index & index) != 0) {
      csv.push_back(kv.value);
    }
  }
  for (const auto &kv : dcs) {
    if ((kv.index & dllindex) != 0) {
      csv.push_back(kv.value);
    }
  }
  return csv;
}

std::wstring Subsystem(uint32_t index) {
  const key_value_t subs[] = {
      {IMAGE_SUBSYSTEM_UNKNOWN, L"UNKNOWN"},
      {IMAGE_SUBSYSTEM_NATIVE, L"Device drivers and native Windows processes "},
      {IMAGE_SUBSYSTEM_WINDOWS_GUI, L"Windows GUI"},
      {IMAGE_SUBSYSTEM_WINDOWS_CUI, L"Windows CUI"},
      {IMAGE_SUBSYSTEM_OS2_CUI, L"OS/2  character subsytem"},
      {IMAGE_SUBSYSTEM_POSIX_CUI, L"Posix character subsystem"},
      {IMAGE_SUBSYSTEM_NATIVE_WINDOWS, L"Native Win9x driver"},
      {IMAGE_SUBSYSTEM_WINDOWS_CE_GUI, L"Windows CE"},
      {IMAGE_SUBSYSTEM_EFI_APPLICATION, L"EFI Application"},
      {IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER, L"EFI Boot Service Driver"},
      {IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER, L"EFI Runtime Driver"},
      {IMAGE_SUBSYSTEM_EFI_ROM, L"EFI ROM image"},
      {IMAGE_SUBSYSTEM_XBOX, L"Xbox system"},
      {IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION, L"Windows Boot Application"},
      {IMAGE_SUBSYSTEM_XBOX_CODE_CATALOG, L"XBOX Code Catalog"}
      //
  };
  for (const auto &kv : subs) {
    if (kv.index == index) {
      return kv.value;
    }
  }
  return L"UNKNOWN";
}

std::wstring fromutf8(std::string_view sv) {
  auto sz =
      MultiByteToWideChar(CP_UTF8, 0, sv.data(), (int)sv.size(), nullptr, 0);
  std::wstring output;
  output.resize(sz);
  // C++17 string::data() has non const function
  MultiByteToWideChar(CP_UTF8, 0, sv.data(), (int)sv.size(), output.data(), sz);
  return output;
}

std::wstring fromascii(std::string_view sv) {
  auto sz =
      MultiByteToWideChar(CP_ACP, 0, sv.data(), (int)sv.size(), nullptr, 0);
  std::wstring output;
  output.resize(sz);
  MultiByteToWideChar(CP_ACP, 0, sv.data(), (int)sv.size(), output.data(), sz);
  return output;
}

inline std::wstring DllName(memview mv, LPVOID nh, ULONG nva) {
  auto va =
      ImageRvaToVa((PIMAGE_NT_HEADERS)nh, (LPVOID)mv.data(), nva, nullptr);
  if (va == nullptr) {
    return L"";
  }
  std::string name;
  name.reserve(256);
  auto dn = reinterpret_cast<char *>(va);
  auto end = mv.data() + mv.size();
  for (auto it = dn; it < end && *it != 0; it++) {
    name.push_back(*it);
  }
  return fromascii(name);
}

inline std::wstring ClrMessage(memview mv, LPVOID nh, ULONG clrva) {
  auto va =
      ImageRvaToVa((PIMAGE_NT_HEADERS)nh, (LPVOID)mv.data(), clrva, nullptr);
  auto end = mv.data() + mv.size();
  if (va == nullptr || (char *)va + sizeof(IMAGE_COR20_HEADER) > end) {
    return L"";
  }
  auto clrh = reinterpret_cast<PIMAGE_COR20_HEADER>(va);
  auto va2 = ImageRvaToVa((PIMAGE_NT_HEADERS)nh, (LPVOID)mv.data(),
                          clrh->MetaData.VirtualAddress, nullptr);
  if (va2 == nullptr || (const char *)va2 + sizeof(STORAGESIGNATURE) > end) {
    return L"";
  }
  auto clrmsg = reinterpret_cast<const STORAGESIGNATURE *>(va2);
  if ((const char *)clrmsg + clrmsg->Length > end) {
    return L"";
  }
  return fromutf8(std::string_view(
      (const char *)clrmsg + sizeof(STORAGESIGNATURE), clrmsg->Length));
}

template <typename NtHeaderT>
std::optional<pe_minutiae_t> pecoff_dump(memview mv, NtHeaderT *nh,
                                         base::error_code &ec) {
  pe_minutiae_t pm;
  pm.machine = Machine(nh->FileHeader.Machine);
  pm.characteristics = Characteristics(nh->FileHeader.Characteristics,
                                       nh->OptionalHeader.DllCharacteristics);
  pm.osver = {nh->OptionalHeader.MajorOperatingSystemVersion,
              nh->OptionalHeader.MinorOperatingSystemVersion};
  pm.subsystem = Subsystem(nh->OptionalHeader.Subsystem);
  pm.linkver = {nh->OptionalHeader.MajorLinkerVersion,
                nh->OptionalHeader.MinorLinkerVersion};
  pm.imagever = {nh->OptionalHeader.MajorImageVersion,
                 nh->OptionalHeader.MinorImageVersion};
  pm.isdll = ((nh->FileHeader.Characteristics & IMAGE_FILE_DLL) != 0);

  // https://docs.microsoft.com/zh-cn/windows/desktop/api/winnt/ns-winnt-_image_data_directory
  auto clre =
      &(nh->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_COMHEADER]);
  auto end = mv.data() + mv.size();
  if (clre->Size == sizeof(IMAGE_COR20_HEADER)) {
    // Exists IMAGE_COR20_HEADER
    pm.clrmsg = ClrMessage(mv, (PVOID)nh, clre->VirtualAddress);
  }
  // Import
  auto import_ =
      &(nh->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT]);
  if (import_->Size != 0) {
    auto va = ImageRvaToVa((PIMAGE_NT_HEADERS)nh, (PVOID)mv.data(),
                           import_->VirtualAddress, nullptr);
    if (va == nullptr || (const char *)va + import_->Size >= end) {
      return std::make_optional<>(pm);
    }
    auto imdes = reinterpret_cast<PIMAGE_IMPORT_DESCRIPTOR>(va);
    while (imdes->Name != 0) {
      //
      // ASCIIZ
      auto dnw = DllName(mv, (LPVOID)nh, imdes->Name);
      if (!dnw.empty()) {
        pm.depends.push_back(dnw);
      }
      imdes++;
    }
  }
  auto delay_ =
      &(nh->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT]);
  if (delay_->Size != 0) {
    auto va = ImageRvaToVa((PIMAGE_NT_HEADERS)nh, (PVOID)mv.data(),
                           delay_->VirtualAddress, nullptr);
    if (va == nullptr || (const char *)va + delay_->Size >= end) {
      return std::make_optional<>(pm);
    }
    auto imdes = reinterpret_cast<PIMAGE_DELAYLOAD_DESCRIPTOR>(va);
    while (imdes->DllNameRVA != 0) {
      //
      // ASCIIZ
      auto dnw = DllName(mv, (LPVOID)nh, imdes->DllNameRVA);
      if (!dnw.empty()) {
        pm.depends.push_back(dnw);
      }
      imdes++;
    }
  }

  return std::make_optional<pe_minutiae_t>(std::move(pm));
}

std::optional<pe_minutiae_t> inquisitive_pecoff(std::wstring_view sv,
                                                base::error_code &ec) {

  mapview mv;
  ec = mv.mapfile(sv, sizeof(IMAGE_DOS_HEADER) + sizeof(IMAGE_NT_HEADERS32));
  if (ec) {
    return std::nullopt;
  }
  auto h = mv.cast<IMAGE_DOS_HEADER>(0);
  if (h == nullptr) {
    ec = base::make_error_code(L"file size too small, cast error");
    return std::nullopt;
  }
  // PE/PE+ lIMAGE_NT_HEADERS32 ayout
  auto nh = mv.cast<IMAGE_NT_HEADERS32>(h->e_lfanew);
  if (nh == nullptr) {
    ec = base::make_error_code(L"file size too small, cast NT header error");
    return std::nullopt;
  }
  switch (nh->OptionalHeader.Magic) {
  case IMAGE_NT_OPTIONAL_HDR64_MAGIC:
    return pecoff_dump(mv.subview(0), (PIMAGE_NT_HEADERS64)nh, ec);
  case IMAGE_NT_OPTIONAL_HDR32_MAGIC:
    return pecoff_dump(mv.subview(0), (PIMAGE_NT_HEADERS32)nh, ec);
  case IMAGE_ROM_OPTIONAL_HDR_MAGIC: {
    // ROM
  } break;
  default:
    break;
  }
  return std::nullopt;
}
} // namespace pecoff