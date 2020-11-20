//
#include "internal.hpp"

// https://en.wikipedia.org/wiki/Portable_Executable

namespace bela::pe {

inline void swaple(FileHeader &fh) {
  if constexpr (bela::IsBigEndian()) {
    fh.Characteristics = bela::swaple(fh.Characteristics);
    fh.Machine = bela::swaple(fh.Machine);
    fh.NumberOfSections = bela::swaple(fh.NumberOfSections);
    fh.NumberOfSymbols = bela::swaple(fh.NumberOfSymbols);
    fh.PointerToSymbolTable = bela::swaple(fh.PointerToSymbolTable);
    fh.TimeDateStamp = bela::swaple(fh.TimeDateStamp);
    fh.SizeOfOptionalHeader = bela::swaple(fh.SizeOfOptionalHeader);
  }
}

inline void swaple(OptionalHeader64 *oh) {
  if constexpr (bela::IsBigEndian()) {
    oh->Magic = bela::swaple(oh->Magic);
    oh->SizeOfCode = bela::swaple(oh->SizeOfCode);
    oh->SizeOfInitializedData = bela::swaple(oh->SizeOfInitializedData);
    oh->SizeOfUninitializedData = bela::swaple(oh->SizeOfUninitializedData);
    oh->AddressOfEntryPoint = bela::swaple(oh->AddressOfEntryPoint);
    oh->BaseOfCode = bela::swaple(oh->BaseOfCode);
    oh->ImageBase = bela::swaple(oh->ImageBase);
    oh->SectionAlignment = bela::swaple(oh->SectionAlignment);
    oh->FileAlignment = bela::swaple(oh->FileAlignment);
    oh->MajorOperatingSystemVersion = bela::swaple(oh->MajorOperatingSystemVersion);
    oh->MinorOperatingSystemVersion = bela::swaple(oh->MinorOperatingSystemVersion);
    oh->MajorImageVersion = bela::swaple(oh->MajorImageVersion);
    oh->MinorImageVersion = bela::swaple(oh->MinorImageVersion);
    oh->MajorSubsystemVersion = bela::swaple(oh->MajorSubsystemVersion);
    oh->MinorSubsystemVersion = bela::swaple(oh->MinorSubsystemVersion);
    oh->Win32VersionValue = bela::swaple(oh->Win32VersionValue);
    oh->SizeOfImage = bela::swaple(oh->SizeOfImage);
    oh->SizeOfHeaders = bela::swaple(oh->SizeOfHeaders);
    oh->CheckSum = bela::swaple(oh->CheckSum);
    oh->Subsystem = bela::swaple(oh->Subsystem);
    oh->DllCharacteristics = bela::swaple(oh->DllCharacteristics);
    oh->SizeOfStackReserve = bela::swaple(oh->SizeOfStackReserve);
    oh->SizeOfStackCommit = bela::swaple(oh->SizeOfStackCommit);
    oh->SizeOfHeapReserve = bela::swaple(oh->SizeOfHeapReserve);
    oh->SizeOfHeapCommit = bela::swaple(oh->SizeOfHeapCommit);
    oh->LoaderFlags = bela::swaple(oh->LoaderFlags);
    oh->NumberOfRvaAndSizes = bela::swaple(oh->NumberOfRvaAndSizes);
    for (auto &d : oh->DataDirectory) {
      d.Size = bela::swaple(d.Size);
      d.VirtualAddress = bela::swaple(d.VirtualAddress);
    }
  }
}

inline void swaple(OptionalHeader32 *oh) {
  if constexpr (bela::IsBigEndian()) {
    oh->Magic = bela::swaple(oh->Magic);
    oh->SizeOfCode = bela::swaple(oh->SizeOfCode);
    oh->SizeOfInitializedData = bela::swaple(oh->SizeOfInitializedData);
    oh->SizeOfUninitializedData = bela::swaple(oh->SizeOfUninitializedData);
    oh->AddressOfEntryPoint = bela::swaple(oh->AddressOfEntryPoint);
    oh->BaseOfCode = bela::swaple(oh->BaseOfCode);
    oh->BaseOfData = bela::swaple(oh->BaseOfData);
    oh->ImageBase = bela::swaple(oh->ImageBase);
    oh->SectionAlignment = bela::swaple(oh->SectionAlignment);
    oh->FileAlignment = bela::swaple(oh->FileAlignment);
    oh->MajorOperatingSystemVersion = bela::swaple(oh->MajorOperatingSystemVersion);
    oh->MinorOperatingSystemVersion = bela::swaple(oh->MinorOperatingSystemVersion);
    oh->MajorImageVersion = bela::swaple(oh->MajorImageVersion);
    oh->MinorImageVersion = bela::swaple(oh->MinorImageVersion);
    oh->MajorSubsystemVersion = bela::swaple(oh->MajorSubsystemVersion);
    oh->MinorSubsystemVersion = bela::swaple(oh->MinorSubsystemVersion);
    oh->Win32VersionValue = bela::swaple(oh->Win32VersionValue);
    oh->SizeOfImage = bela::swaple(oh->SizeOfImage);
    oh->SizeOfHeaders = bela::swaple(oh->SizeOfHeaders);
    oh->CheckSum = bela::swaple(oh->CheckSum);
    oh->Subsystem = bela::swaple(oh->Subsystem);
    oh->DllCharacteristics = bela::swaple(oh->DllCharacteristics);
    oh->SizeOfStackReserve = bela::swaple(oh->SizeOfStackReserve);
    oh->SizeOfStackCommit = bela::swaple(oh->SizeOfStackCommit);
    oh->SizeOfHeapReserve = bela::swaple(oh->SizeOfHeapReserve);
    oh->SizeOfHeapCommit = bela::swaple(oh->SizeOfHeapCommit);
    oh->LoaderFlags = bela::swaple(oh->LoaderFlags);
    oh->NumberOfRvaAndSizes = bela::swaple(oh->NumberOfRvaAndSizes);
    for (auto &d : oh->DataDirectory) {
      d.Size = bela::swaple(d.Size);
      d.VirtualAddress = bela::swaple(d.VirtualAddress);
    }
  }
}

inline void swaple(SectionHeader32 &sh) {
  if constexpr (bela::IsBigEndian()) {
    sh.VirtualSize = bela::swaple(sh.VirtualSize);
    sh.VirtualAddress = bela::swaple(sh.VirtualAddress);
    sh.SizeOfRawData = bela::swaple(sh.SizeOfRawData);
    sh.PointerToRawData = bela::swaple(sh.PointerToRawData);
    sh.PointerToRelocations = bela::swaple(sh.PointerToRelocations);
    sh.PointerToLineNumbers = bela::swaple(sh.PointerToLineNumbers);
    sh.NumberOfRelocations = bela::swaple(sh.NumberOfRelocations);
    sh.NumberOfLineNumbers = bela::swaple(sh.NumberOfLineNumbers);
    sh.Characteristics = bela::swaple(sh.Characteristics);
  }
}

void File::Free() {
  if (fd != nullptr) {
    fclose(fd);
    fd = nullptr;
  }
}

void File::FileMove(File &&other) {
  Free();
  fd = other.fd;
  is64bit = other.is64bit;
  other.fd = nullptr;
  stringTable = std::move(other.stringTable);
  sections = std::move(other.sections);
  memcpy(&fh, &other.fh, sizeof(FileHeader));
  memcpy(&oh, &other.oh, sizeof(OptionalHeader64));
}

std::optional<File> File::NewFile(std::wstring_view p, bela::error_code &ec) {
  FILE *fd = nullptr;
  if (auto eno = _wfopen_s(&fd, p.data(), L"rb"); eno != 0) {
    ec = bela::make_stdc_error_code(eno, L"open file: ");
    return std::nullopt;
  }
  File file;
  file.fd = fd;
  DosHeader dh;
  if (fread(&dh, 1, sizeof(DosHeader), fd) != sizeof(DosHeader)) {
    ec = bela::make_stdc_error_code(ferror(fd), L"open file: ");
    return std::nullopt;
  }
  constexpr auto x = 0x3c;

  int64_t base = 0;
  if (bela::swaple(dh.e_magic) == IMAGE_DOS_SIGNATURE) {
    auto signoff = static_cast<int64_t>(bela::swaple(dh.e_lfanew));
    uint8_t sign[4];
    if (auto eno = _fseeki64(fd, signoff, SEEK_SET); eno != 0) {
      ec = bela::make_stdc_error_code(eno, L"Invalid PE COFF file signature of ");
      return std::nullopt;
    }
    if (fread(sign, 1, 4, fd) != 4) {
      ec = bela::make_stdc_error_code(ferror(fd), L"Invalid PE COFF file signature of ");
      return std::nullopt;
    }
    if (!(sign[0] == 'P' && sign[1] == 'E' && sign[2] == 0 && sign[3] == 0)) {
      ec = bela::make_error_code(1, L"Invalid PE COFF file signature of ['", int(sign[0]), L"','", int(sign[1]), L"','",
                                 int(sign[2]), L"','", int(sign[3]), L"']");
      return std::nullopt;
    }
    base = signoff + 4;
  }
  if (auto eno = _fseeki64(fd, base, SEEK_SET); eno != 0) {
    ec = bela::make_stdc_error_code(eno, L"unable seek to base");
    return std::nullopt;
  }
  if (fread(&file.fh, 1, sizeof(FileHeader), file.fd) != sizeof(FileHeader)) {
    ec = bela::make_stdc_error_code(ferror(file.fd), L"Invalid PE COFF file FileHeader ");
    return std::nullopt;
  }
  swaple(file.fh);
  file.is64bit = (file.fh.SizeOfOptionalHeader == sizeof(OptionalHeader64));
  if (!readStringTable(&file.fh, fd, file.stringTable, ec)) {
    return std::nullopt;
  }
  // if (!readCOFFSymbols(&file.fh, file.fd, file.coffsymbol, ec)) {
  //   return std::nullopt;
  // }

  if (auto eno = _fseeki64(fd, base + sizeof(FileHeader), SEEK_SET); eno != 0) {
    ec = bela::make_stdc_error_code(eno, L"unable seek to base");
    return std::nullopt;
  }
  if (file.is64bit) {
    if (fread(&file.oh, 1, sizeof(OptionalHeader64), fd) != sizeof(OptionalHeader64)) {
      ec = bela::make_stdc_error_code(ferror(file.fd), L"Invalid PE COFF file OptionalHeader64 ");
      return std::nullopt;
    }
    swaple(&file.oh);
  } else {
    if (fread(&file.oh, 1, sizeof(OptionalHeader32), fd) != sizeof(OptionalHeader32)) {
      ec = bela::make_stdc_error_code(ferror(file.fd), L"Invalid PE COFF file OptionalHeader32 ");
      return std::nullopt;
    }
    swaple(reinterpret_cast<OptionalHeader32 *>(&file.oh));
  }
  file.sections.reserve(file.fh.NumberOfSections);
  for (int i = 0; i < file.fh.NumberOfSections; i++) {
    SectionHeader32 sh;
    if (fread(&sh, 1, sizeof(SectionHeader32), fd) != sizeof(SectionHeader32)) {
      ec = bela::make_stdc_error_code(ferror(file.fd), L"Invalid PE COFF file SectionHeader32 ");
      return std::nullopt;
    }
    swaple(sh);
    Section sec;
    sec.Header.Name = sectionFullName(sh, file.stringTable);
    sec.Header.VirtualSize = sh.VirtualSize;
    sec.Header.VirtualAddress = sh.VirtualAddress;
    sec.Header.Size = sh.SizeOfRawData;
    sec.Header.Offset = sh.PointerToRawData;
    sec.Header.PointerToRelocations = sh.PointerToRelocations;
    sec.Header.PointerToLineNumbers = sh.PointerToLineNumbers;
    sec.Header.NumberOfRelocations = sh.NumberOfRelocations;
    sec.Header.NumberOfLineNumbers = sh.NumberOfLineNumbers;
    sec.Header.Characteristics = sh.Characteristics;
    file.sections.emplace_back(std::move(sec));
  }
  for (auto &sec : file.sections) {
    readRelocs(sec, fd);
  }
  return std::make_optional(std::move(file));
}

uint16_t getFunctionHit(std::vector<char> &section, int start) {
  if (start < 0 || start - 2 > section.size()) {
    return 0;
  }
  return bela::readle<uint16_t>(section.data() + start);
}

bool File::LookupExports(std::vector<ExportedSymbol> &exports, bela::error_code &ec) const {
  uint32_t ddlen = 0;
  const DataDirectory *exd = nullptr;
  if (is64bit) {
    ddlen = oh.NumberOfRvaAndSizes;
    exd = &(oh.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]);
  } else {
    auto oh3 = reinterpret_cast<const OptionalHeader32 *>(&oh);
    ddlen = oh3->NumberOfRvaAndSizes;
    exd = &(oh3->DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT]);
  }
  if (ddlen < IMAGE_DIRECTORY_ENTRY_IMPORT + 1 || exd->VirtualAddress == 0) {
    return true;
  }
  const Section *ds = nullptr;
  for (const auto &sec : sections) {
    if (sec.Header.VirtualAddress <= exd->VirtualAddress &&
        exd->VirtualAddress < sec.Header.VirtualAddress + sec.Header.VirtualSize) {
      ds = &sec;
    }
  }
  if (ds == nullptr) {
    return true;
  }
  std::vector<char> sdata;
  if (!readSectionData(sdata, *ds, fd)) {
    ec = bela::make_error_code(L"unable read section data");
    return false;
  }
  auto N = exd->VirtualAddress - ds->Header.VirtualAddress;
  std::string_view sv{sdata.data() + N, sdata.size() - N};
  if (sv.size() < sizeof(IMAGE_EXPORT_DIRECTORY)) {
    return true;
  }
  IMAGE_EXPORT_DIRECTORY ied;
  if constexpr (bela::IsLittleEndian()) {
    memcpy(&ied, sv.data(), sizeof(IMAGE_EXPORT_DIRECTORY));
  } else {
    auto cied = reinterpret_cast<const IMAGE_EXPORT_DIRECTORY *>(sv.data());
    ied.Characteristics = bela::swaple(cied->Characteristics);
    ied.TimeDateStamp = bela::swaple(cied->TimeDateStamp);
    ied.MajorVersion = bela::swaple(cied->MajorVersion);
    ied.MinorVersion = bela::swaple(cied->MinorVersion);
    ied.Name = bela::swaple(cied->Name);
    ied.Base = bela::swaple(cied->Base);
    ied.NumberOfFunctions = bela::swaple(cied->NumberOfFunctions);
    ied.NumberOfNames = bela::swaple(cied->NumberOfNames);
    ied.AddressOfFunctions = bela::swaple(cied->AddressOfFunctions);       // RVA from base of image
    ied.AddressOfNames = bela::swaple(cied->AddressOfNames);               // RVA from base of image
    ied.AddressOfNameOrdinals = bela::swaple(cied->AddressOfNameOrdinals); // RVA from base of image
  }
  auto ordinalBase = static_cast<uint16_t>(ied.Base);
  exports.resize(ied.NumberOfNames);
  if (ied.AddressOfNameOrdinals > ds->Header.VirtualAddress &&
      ied.AddressOfNameOrdinals < ds->Header.VirtualAddress + ds->Header.VirtualSize) {
    auto N = ied.AddressOfNameOrdinals - ds->Header.VirtualAddress;
    auto sv = std::string_view{sdata.data() + N, sdata.size() - N};
    if (sv.size() > exports.size() * 2) {
      for (size_t i = 0; i < exports.size(); i++) {
        exports[i].Ordinal = bela::readle<uint16_t>(sv.data() + i * 2) + ordinalBase;
        exports[i].Hint = i;
      }
    }
  }
  if (ied.AddressOfNames > ds->Header.VirtualAddress &&
      ied.AddressOfNames < ds->Header.VirtualAddress + ds->Header.VirtualSize) {
    auto N = ied.AddressOfNames - ds->Header.VirtualAddress;
    auto sv = std::string_view{sdata.data() + N, sdata.size() - N};
    if (sv.size() >= exports.size() * 4) {
      for (size_t i = 0; i < exports.size(); i++) {
        auto start = bela::readle<uint32_t>(sv.data() + i * 4) - ds->Header.VirtualAddress;
        exports[i].Name = getString(sdata, start);
      }
    }
  }
  if (ied.AddressOfFunctions > ds->Header.VirtualAddress &&
      ied.AddressOfFunctions < ds->Header.VirtualAddress + ds->Header.VirtualSize) {
    auto N = ied.AddressOfFunctions - ds->Header.VirtualAddress;
    for (size_t i = 0; i < exports.size(); i++) {
      auto sv = std::string_view{sdata.data() + N, sdata.size() - N};
      if (sv.size() > exports[i].Ordinal * 4 + 4) {
        exports[i].Address = bela::readle<uint32_t>(sv.data() + (exports[i].Ordinal - ordinalBase) * 4);
      }
    }
  }

  return true;
}

// Delay imports
// https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#delay-load-import-tables-image-only
bool File::LookupDelayImports(FunctionTable::symbols_map_t &sm, bela::error_code &ec) const {
  uint32_t ddlen = 0;
  const DataDirectory *delay = nullptr;
  if (is64bit) {
    ddlen = oh.NumberOfRvaAndSizes;
    delay = &(oh.DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT]);
  } else {
    auto oh3 = reinterpret_cast<const OptionalHeader32 *>(&oh);
    ddlen = oh3->NumberOfRvaAndSizes;
    delay = &(oh3->DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT]);
  }
  if (ddlen < IMAGE_DIRECTORY_ENTRY_IMPORT + 1 || delay->VirtualAddress == 0) {
    return true;
  }
  const Section *ds = nullptr;
  for (const auto &sec : sections) {
    if (sec.Header.VirtualAddress <= delay->VirtualAddress &&
        delay->VirtualAddress < sec.Header.VirtualAddress + sec.Header.VirtualSize) {
      ds = &sec;
    }
  }
  if (ds == nullptr) {
    return true;
  }
  std::vector<char> sdata;
  if (!readSectionData(sdata, *ds, fd)) {
    ec = bela::make_error_code(L"unable read section data");
    return false;
  }
  auto N = delay->VirtualAddress - ds->Header.VirtualAddress;
  std::string_view sv{sdata.data() + N, sdata.size() - N};

  constexpr size_t dslen = sizeof(IMAGE_DELAYLOAD_DESCRIPTOR);
  std::vector<ImportDelayDirectory> ida;
  while (sv.size() > dslen) {
    const auto dt = reinterpret_cast<const IMAGE_DELAYLOAD_DESCRIPTOR *>(sv.data());
    sv.remove_prefix(dslen);
    ImportDelayDirectory id;
    id.Attributes = bela::swaple(dt->Attributes.AllAttributes);
    id.DllNameRVA = bela::swaple(dt->DllNameRVA);
    id.ModuleHandleRVA = bela::swaple(dt->ModuleHandleRVA);
    id.ImportAddressTableRVA = bela::swaple(dt->ImportAddressTableRVA);
    id.ImportNameTableRVA = bela::swaple(dt->ImportNameTableRVA);
    id.BoundImportAddressTableRVA = bela::swaple(dt->BoundImportAddressTableRVA);
    id.UnloadInformationTableRVA = bela::swaple(dt->UnloadInformationTableRVA);
    id.TimeDateStamp = bela::swaple(dt->TimeDateStamp);
    if (id.ModuleHandleRVA == 0) {
      break;
    }
    ida.emplace_back(std::move(id));
  }
  auto ptrsize = is64bit ? sizeof(uint64_t) : sizeof(uint32_t);
  for (auto &dt : ida) {
    dt.DllName = getString(sdata, int(dt.DllNameRVA - ds->Header.VirtualAddress));
    uint32_t N = dt.ImportNameTableRVA - ds->Header.VirtualAddress;
    std::string_view d{sdata.data() + N, sdata.size() - N};
    std::vector<Function> functions;
    while (d.size() >= ptrsize) {
      if (is64bit) {
        auto va = bela::readle<uint64_t>(d.data());
        d.remove_prefix(8);
        if (va == 0) {
          break;
        }
        // IMAGE_ORDINAL_FLAG64
        if ((va & 0x8000000000000000) > 0) {
          auto ordinal = IMAGE_ORDINAL64(va);
          functions.emplace_back("", 0, static_cast<int>(ordinal));
          // TODO add dynimport ordinal support.
        } else {
          auto fn = getString(sdata, static_cast<int>(static_cast<uint64_t>(va)) - ds->Header.VirtualAddress + 2);
          auto hit = getFunctionHit(sdata, static_cast<int>(static_cast<uint64_t>(va)) - ds->Header.VirtualAddress);
          functions.emplace_back(fn, static_cast<int>(hit));
        }
      } else {
        auto va = bela::readle<uint32_t>(d.data());
        d.remove_prefix(4);
        if (va == 0) {
          break;
        }
        // IMAGE_ORDINAL_FLAG32
        if ((va & 0x80000000) > 0) {
          auto ordinal = IMAGE_ORDINAL32(va);
          functions.emplace_back("", 0, static_cast<int>(ordinal));
          // is Ordinal
          // TODO add dynimport ordinal support.
          // ord := va&0x0000FFFF
        } else {
          auto fn = getString(sdata, static_cast<int>(va) - ds->Header.VirtualAddress + 2);
          auto hit = getFunctionHit(sdata, static_cast<int>(static_cast<uint32_t>(va)) - ds->Header.VirtualAddress);
          functions.emplace_back(fn, static_cast<int>(hit));
        }
      }
    }
    sm.emplace(std::move(dt.DllName), std::move(functions));
  }
  return true;
}

bool File::LookupImports(FunctionTable::symbols_map_t &sm, bela::error_code &ec) const {
  uint32_t ddlen = 0;
  const DataDirectory *idd = nullptr;
  if (is64bit) {
    ddlen = oh.NumberOfRvaAndSizes;
    idd = &(oh.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT]);
  } else {
    auto oh3 = reinterpret_cast<const OptionalHeader32 *>(&oh);
    ddlen = oh3->NumberOfRvaAndSizes;
    idd = &(oh3->DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT]);
  }
  if (ddlen < IMAGE_DIRECTORY_ENTRY_IMPORT + 1 || idd->VirtualAddress == 0) {
    return true;
  }
  const Section *ds = nullptr;
  for (const auto &sec : sections) {
    if (sec.Header.VirtualAddress <= idd->VirtualAddress &&
        idd->VirtualAddress < sec.Header.VirtualAddress + sec.Header.VirtualSize) {
      ds = &sec;
    }
  }
  if (ds == nullptr) {
    return true;
  }
  std::vector<char> sdata;
  if (!readSectionData(sdata, *ds, fd)) {
    ec = bela::make_error_code(L"unable read section data");
    return false;
  }
  auto N = idd->VirtualAddress - ds->Header.VirtualAddress;
  std::string_view sv{sdata.data() + N, sdata.size() - N};
  std::vector<ImportDirectory> ida;
  while (sv.size() > 20) {
    const auto dt = reinterpret_cast<const IMAGE_IMPORT_DESCRIPTOR *>(sv.data());
    sv.remove_prefix(20);
    ImportDirectory id;
    id.OriginalFirstThunk = bela::swaple(dt->OriginalFirstThunk);
    id.TimeDateStamp = bela::swaple(dt->TimeDateStamp);
    id.ForwarderChain = bela::swaple(dt->ForwarderChain);
    id.Name = bela::swaple(dt->Name);
    id.FirstThunk = bela::swaple(dt->FirstThunk);
    if (id.OriginalFirstThunk == 0) {
      break;
    }
    ida.emplace_back(std::move(id));
  }
  auto ptrsize = is64bit ? sizeof(uint64_t) : sizeof(uint32_t);
  for (auto &dt : ida) {
    dt.DllName = getString(sdata, int(dt.Name - ds->Header.VirtualAddress));
    auto T = dt.OriginalFirstThunk == 0 ? dt.FirstThunk : dt.OriginalFirstThunk;
    if (T < ds->Header.VirtualAddress) {
      break;
    }
    auto N = T - ds->Header.VirtualAddress;
    std::string_view d{sdata.data() + N, sdata.size() - N};
    std::vector<Function> functions;
    while (d.size() >= ptrsize) {
      if (is64bit) {
        auto va = bela::readle<uint64_t>(d.data());
        d.remove_prefix(8);
        if (va == 0) {
          break;
        }
        // IMAGE_ORDINAL_FLAG64
        if ((va & 0x8000000000000000) > 0) {
          auto ordinal = IMAGE_ORDINAL64(va);
          functions.emplace_back("", 0, static_cast<int>(ordinal));
          // TODO add dynimport ordinal support.
        } else {
          auto fn = getString(sdata, static_cast<int>(static_cast<uint64_t>(va)) - ds->Header.VirtualAddress + 2);
          auto hit = getFunctionHit(sdata, static_cast<int>(static_cast<uint64_t>(va)) - ds->Header.VirtualAddress);
          functions.emplace_back(fn, static_cast<int>(hit));
        }
      } else {
        auto va = bela::readle<uint32_t>(d.data());
        d.remove_prefix(4);
        if (va == 0) {
          break;
        }
        // IMAGE_ORDINAL_FLAG32
        if ((va & 0x80000000) > 0) {
          auto ordinal = IMAGE_ORDINAL32(va);
          functions.emplace_back("", 0, static_cast<int>(ordinal));
          // is Ordinal
          // TODO add dynimport ordinal support.
          // ord := va&0x0000FFFF
        } else {
          auto fn = getString(sdata, static_cast<int>(va) - ds->Header.VirtualAddress + 2);
          auto hit = getFunctionHit(sdata, static_cast<int>(static_cast<uint32_t>(va)) - ds->Header.VirtualAddress);
          functions.emplace_back(fn, static_cast<int>(hit));
        }
      }
    }
    sm.emplace(std::move(dt.DllName), std::move(functions));
  }
  return true;
}

// Lookup function table
bool File::LookupFunctionTable(FunctionTable &ft, bela::error_code &ec) const {
  if (!LookupImports(ft.imports, ec)) {
    return false;
  }
  if (!LookupDelayImports(ft.delayimprots, ec)) {
    return false;
  }
  return LookupExports(ft.exports, ec);
}

} // namespace bela::pe
