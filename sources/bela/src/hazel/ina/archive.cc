//// archive format
// BZ 7z Rar!
#include <string_view>
#include <optional>
#include <charconv>
#include <bela/ascii.hpp>
#include <bela/str_cat.hpp>
#include <bela/numbers.hpp>
#include "hazelinc.hpp"

namespace hazel::internal {
// https://en.wikipedia.org/wiki/ZIP_(file_format)
// https://en.wikipedia.org/wiki/Comparison_of_file_archivers
// https://en.wikipedia.org/wiki/List_of_archive_formats
// 7z details:
// https://github.com/mcmilk/7-Zip-zstd/blob/master/CPP/7zip/Archive/7z/7zHeader.h
constexpr const unsigned k7zSignatureSize = 6;
#pragma pack(1)
struct p7z_header_t {
  uint8_t signature[k7zSignatureSize];
  uint8_t major; /// 7z major version default is 0
  uint8_t minor;
};
#pragma pack()

status_t lookup_7zinternal(bela::MemView mv, hazel_result &hr) {
  constexpr const uint8_t k7zSignature[k7zSignatureSize] = {'7', 'z', 0xBC, 0xAF, 0x27, 0x1C};
  constexpr const uint8_t k7zFinishSignature[k7zSignatureSize] = {'7', 'z', 0xBC, 0xAF, 0x27, 0x1C + 1};
  auto hd = mv.cast<p7z_header_t>(0);
  if (hd == nullptr) {
    return None;
  }
  if (memcmp(hd->signature, k7zSignature, k7zSignatureSize) != 0) {
    return None;
  }
  hr.assign(types::p7z, L"7-zip archive data");
  hr.append(L"MajorVersion", static_cast<int>(hd->major));
  hr.append(L"MinorVersion", static_cast<int>(hd->minor));
  return Found;
}

// RAR archive
// https://www.rarlab.com/technote.htm
status_t lookup_rarinternal(bela::MemView mv, hazel_result &hr) {
  /*RAR 5.0 signature consists of 8 bytes: 0x52 0x61 0x72 0x21 0x1A 0x07 0x01
   * 0x00. You need to search for this signature in supposed archive from
   * beginning and up to maximum SFX module size. Just for comparison this is
   * RAR 4.x 7 byte length signature: 0x52 0x61 0x72 0x21 0x1A 0x07 0x00.*/
  constexpr const uint8_t rarSignature[] = {0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00};
  constexpr const uint8_t rar4Signature[] = {0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00};
  if (mv.StartsWith(rarSignature)) {
    hr.assign(types::rar, L"Roshal Archive (RAR)");
    hr.append(L"Version", 5);
    return Found;
  }
  if (mv.StartsWith(rar4Signature)) {
    hr.assign(types::rar, L"Roshal Archive (RAR)");
    hr.append(L"Version", 4);
    return Found;
  }
  return None;
}

///
#pragma pack(1)
struct xar_header {
  uint32_t magic; // xar!
  uint16_t size;  // BE
  uint16_t version;
  uint64_t toc_length_compressed;
  uint64_t toc_length_uncompressed;
  uint32_t cksum_alg;
  /* A nul-terminated, zero-padded to multiple of 4, message digest name
   * appears here if cksum_alg is 3 which must not be empty ("") or "none".
   */
};
#pragma pack()

status_t lookup_xarinternal(bela::MemView mv, hazel_result &hr) {
  // https://github.com/mackyle/xar/wiki/xarformat
  constexpr const uint8_t xarSignature[] = {'x', 'a', 'r', '!'};
  if (!mv.StartsWith(xarSignature)) {
    return None;
  }
  auto xhd = mv.cast<xar_header>(0);
  if (xhd == nullptr || bela::frombe(xhd->size) < 28) {
    return None;
  }
  hr.assign(types::xar, L"eXtensible ARchive format");
  hr.append(L"Version", bela::frombe(xhd->version));
  return Found;
}

// OS X .dmg
// https://en.wikipedia.org/wiki/Apple_Disk_Image
#pragma pack(1)
struct uuid_t {
  uint8_t uuid[16];
};
struct apple_disk_image_header {
  uint8_t Signature[4];
  uint32_t Version;
  uint32_t HeaderSize;
  uint32_t Flags;
  uint64_t RunningDataForkOffset;
  uint64_t DataForkOffset;
  uint64_t DataForkLength;
  uint64_t RsrcForkOffset;
  uint64_t RsrcForkLength;
  uint32_t SegmentNumber;
  uint32_t SegmentCount;
  uuid_t SegmentID;
  uint32_t DataChecksumType;
  uint32_t DataChecksumSize;
  uint32_t DataChecksum[32];
  uint64_t XMLOffset;
  uint64_t XMLLength;
  uint8_t Reserved1[120];
  uint32_t ChecksumType;
  uint32_t ChecksumSize;
  uint32_t Checksum[32];
  uint32_t ImageVariant;
  uint64_t SectorCount;
  uint32_t reserved2;
  uint32_t reserved3;
  uint32_t reserved4;
};
#pragma pack()

status_t lookup_dmginternal(bela::MemView mv, hazel_result &hr) {
  constexpr const uint8_t dmgSignature[] = {'k', 'o', 'l', 'y'};
  if (!mv.StartsWith(dmgSignature)) {
    return None;
  }
  auto hd = mv.cast<apple_disk_image_header>(0);
  constexpr auto hsize = sizeof(apple_disk_image_header);
  if (hd == nullptr || bela::frombe(hd->HeaderSize) != hsize) {
    return None;
  }
  hr.assign(types::dmg, L"Apple Disk Image");
  hr.append(L"Version", bela::frombe(hd->Version));
  return Found;
}

// PDF file format
status_t lookup_pdfinternal(bela::MemView mv, hazel_result &hr) {
  // https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_reference_1-7.pdf
  // %PDF-1.7
  constexpr const uint8_t pdfMagic[] = {0x25, 0x50, 0x44, 0x46, '-'};
  if (!mv.StartsWith(pdfMagic) || mv.size() < 8) {
    return None;
  }
  auto sv = mv.submv(5).sv();
  auto pos = sv.find_first_of("\r\n");
  if (pos == std::string_view::npos) {
    return None;
  }
  auto vstr = bela::StripAsciiWhitespace(sv.substr(0, pos));
  hr.assign(types::pdf, L"Portable Document Format (PDF)");
  hr.append(L"Version", vstr);
  return Found;
}

// WIM
// https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-7/dd799284(v=ws.10)
enum wim_compression_type : uint32_t {
  WimReserved = 0x00000001,
  WimCompression = 0x00000002,
  WimReadOnly = 0x00000004,
  WimSpanned = 0x00000008,
  WimResourceOnly = 0x00000010,
  WimMetadataOnly = 0x00000020,
  WimWriteInProgress = 0x00000040,
  WimReparsePointFix = 0x00000080,
  WimCompressReserved = 0x00010000,
  WimCompressionXpress = 0x00020000,
  WimCompressionLXZ = 0x00040000,
  WimCompressionLZMS = 0x00080000,
  WimCompressionXPRESS2 = 0x00200000
};
// DISK SIZE 208
// VERSION 0x10d00
// VERSION SOLID 0xe00
#define WIM_HEADER_DISK_SIZE 208
#pragma pack(1)
struct reshdr_disk_short {
  union {
    uint64_t flags; /* one byte is a combination of RESHDR_FLAG_XXX */
    uint64_t size;  /* the 7 low-bytes are used to store the size */
  };
  uint64_t offset;
  uint64_t original_size;
};

struct wim_header_t {
  uint8_t magic[8]; // "MSWIM\0\0"
  uint32_t cbSize;
  uint32_t dwVersion;
  uint32_t dwFlags;
  uint32_t dwCompressionSize;
  uint8_t gWIMGuid[16];
  uint16_t usPartNumber;
  uint16_t usTotalParts;
  uint32_t dwImageCount;
  uint16_t rhOffsetTable;
  reshdr_disk_short rhXmlData;
  reshdr_disk_short rhBootMetadata;
  uint32_t dwBootIndex;
  reshdr_disk_short rhIntegrity;
  uint8_t bUnused[60];
};
#pragma pack()
// https://www.microsoft.com/en-us/download/details.aspx?id=13096
status_t lookup_wiminternal(bela::MemView mv, hazel_result &hr) {
  constexpr const uint8_t wimMagic[] = {'M', 'S', 'W', 'I', 'M', 0x00, 0x00, 0x00};
  if (!mv.StartsWith(wimMagic)) {
    return None;
  }
  auto hd = mv.cast<wim_header_t>(0);
  constexpr const size_t hdsize = sizeof(wim_header_t);
  if (hd == nullptr || bela::fromle(hd->cbSize) < hdsize) {
    return None;
  }
  hr.assign(types::wim, L"Windows Imaging Format");
  hr.append(L"Version", bela::fromle(hd->dwVersion));
  auto flags = bela::fromle(hd->dwFlags);
  hr.append(L"Flags", flags);
  if ((flags & WimReadOnly) != 0) {
    hr.append(L"ReadOnly", 1);
  }
  std::vector<std::wstring> compression;
  if ((flags & WimCompression) != 0) {
    if ((flags & WimCompressionXpress) != 0) {
      compression.emplace_back(L"XPRESS");
    }
    if ((flags & WimCompressionLXZ) != 0) {
      compression.emplace_back(L"LXZ");
    }
    if ((flags & WimCompressionLZMS) != 0) {
      compression.emplace_back(L"LZMS");
    }
    if ((flags & WimCompressionXPRESS2) != 0) {
      compression.emplace_back(L"XPRESSv2");
    }
    hr.append(L"Compression", std::move(compression));
  }
  hr.append(L"Imagecount", bela::fromle(hd->dwImageCount));
  hr.append(L"TotalParts", bela::fromle(hd->usTotalParts));
  hr.append(L"PartNumber", bela::fromle(hd->usPartNumber));

  return Found;
}

// cab Microsoft Cabinet Format
// https://docs.microsoft.com/en-us/previous-versions//bb267310(v=vs.85)

struct cabinet_header_t {
  uint8_t signature[4]; // M','S','C','F'
  uint32_t reserved1;   //// 00000
  uint32_t cbCabinet;
  uint32_t reserved2;
  uint32_t coffFiles;   /* offset of the first CFFILE entry */
  uint32_t reserved3;   /* reserved */
  uint8_t versionMinor; /* cabinet file format version, minor */
  uint8_t versionMajor; /* cabinet file format version, major */
  uint16_t cFolders;    /* number of CFFOLDER entries in this */
                        /*    cabinet */
  uint16_t cFiles;      /* number of CFFILE entries in this cabinet */
  uint16_t flags;       /* cabinet file option indicators */
  uint16_t setID;       /* must be the same for all cabinets in a */
                        /*    set */
  uint16_t iCabinet;    /* number of this cabinet file in a set */
  uint16_t cbCFHeader;  /* (optional) size of per-cabinet reserved */
                        /*    area */
  uint8_t cbCFFolder;   /* (optional) size of per-folder reserved */
                        /*    area */
  uint8_t cbCFData;     /* (optional) size of per-datablock reserved */
                        /*    area */
  // uint8_t  abReserve[];      /* (optional) per-cabinet reserved area */
  // uint8_t  szCabinetPrev[];  /* (optional) name of previous cabinet file */
  // uint8_t  szDiskPrev[];     /* (optional) name of previous disk */
  // uint8_t  szCabinetNext[];  /* (optional) name of next cabinet file */
  // uint8_t  szDiskNext[];     /* (optional) name of next disk */
};

status_t lookup_cabinetinternal(bela::MemView mv, hazel_result &hr) {
  constexpr const uint8_t cabMagic[] = {'M', 'S', 'C', 'F', 0, 0, 0, 0};
  if (!mv.StartsWith(cabMagic)) {
    return None;
  }
  auto hd = mv.cast<cabinet_header_t>(0);
  if (hd == nullptr) {
    return None;
  }
  hr.assign(types::cab, L"Microsoft Cabinet data (cab)");
  hr.append(L"MajorVersion", static_cast<int>(hd->versionMajor));
  hr.append(L"MinorVersion", static_cast<int>(hd->versionMinor));
  return Found;
}

// TAR
// https://github.com/libarchive/libarchive/blob/master/libarchive/archive_read_support_format_tar.c#L54

#pragma pack(1)
struct ustar_header_t {
  char name[100];
  char mode[8];
  char uid[8];
  char gid[8];
  char size[12];
  char mtime[12];
  char checksum[8];
  char typeflag;
  char linkname[100]; /* "old format" header ends here */
  char magic[6];      /* For POSIX: "ustar\0" */
  char version[2];    /* For POSIX: "00" */
  char uname[32];
  char gname[32];
  char rdevmajor[8];
  char rdevminor[8];
  char prefix[155];
};

/*
 * Structure of GNU tar header
 */
struct gnu_sparse_t {
  char offset[12];
  char numbytes[12];
};

struct gnutar_header_t {
  char name[100];
  char mode[8];
  char uid[8];
  char gid[8];
  char size[12];
  char mtime[12];
  char checksum[8];
  char typeflag;
  char linkname[100];
  char magic[8]; /* "ustar  \0" (note blank/blank/null at end) */
  char uname[32];
  char gname[32];
  char rdevmajor[8];
  char rdevminor[8];
  char atime[12];
  char ctime[12];
  char offset[12];
  char longnames[4];
  char unused;
  gnu_sparse_t sparse[4];
  char isextended;
  char realsize[12];
  /*
   * Old GNU format doesn't use POSIX 'prefix' field; they use
   * the 'L' (longname) entry instead.
   */
};
#pragma pack()

status_t lookup_tarinternal(bela::MemView mv, hazel_result &hr) {
  auto hd = mv.cast<ustar_header_t>(0);
  if (hd == nullptr) {
    return None;
  }
  constexpr const uint8_t ustarMagic[] = {'u', 's', 't', 'a', 'r', 0};
  constexpr const uint8_t gnutarMagic[] = {'u', 's', 't', 'a', 'r', ' ', ' ', 0};
  if (memcmp(hd->magic, ustarMagic, ArrayLength(ustarMagic)) == 0) {
    hr.assign(types::tar, L"Tarball (ustar) archive data");
    return Found;
  }
  if (memcmp(hd->magic, gnutarMagic, ArrayLength(gnutarMagic)) == 0 && mv.size() > sizeof(gnutar_header_t)) {
    hr.assign(types::tar, L"Tarball (gnutar) archive data");
    return Found;
  }
  return None;
}

struct sqlite_header_t {
  uint8_t sigver[16];
  uint16_t pagesize;
  uint16_t version;
};

status_t lookup_sqliteinternal(bela::MemView mv, hazel_result &hr) {
  constexpr const uint8_t sqliteMagic[] = {'S', 'Q', 'L', 'i', 't', 'e', ' ', 'f', 'o', 'r', 'm', 'a', 't'};
  if (!mv.StartsWith(sqliteMagic)) {
    return None;
  }
  auto hd = mv.cast<sqlite_header_t>(0);
  if (hd == nullptr || hd->sigver[15] != 0) {
    return None;
  }
  hr.assign(types::sqlite, L"SQLite DB");
  hr.append(L"Version", static_cast<int>(hd->sigver[14]));
  return Found;
}

// EPUB file
inline bool IsEPUB(const uint8_t *buf, size_t size) {
  return size > 57 && buf[0] == 0x50 && buf[1] == 0x4B && buf[2] == 0x3 && buf[3] == 0x4 && buf[30] == 0x6D &&
         buf[31] == 0x69 && buf[32] == 0x6D && buf[33] == 0x65 && buf[34] == 0x74 && buf[35] == 0x79 &&
         buf[36] == 0x70 && buf[37] == 0x65 && buf[38] == 0x61 && buf[39] == 0x70 && buf[40] == 0x70 &&
         buf[41] == 0x6C && buf[42] == 0x69 && buf[43] == 0x63 && buf[44] == 0x61 && buf[45] == 0x74 &&
         buf[46] == 0x69 && buf[47] == 0x6F && buf[48] == 0x6E && buf[49] == 0x2F && buf[50] == 0x65 &&
         buf[51] == 0x70 && buf[52] == 0x75 && buf[53] == 0x62 && buf[54] == 0x2B && buf[55] == 0x7A &&
         buf[56] == 0x69 && buf[57] == 0x70;
}

bool IsSwf(const uint8_t *buf, size_t size) {
  return (size > 2 && (buf[0] == 0x43 || buf[0] == 0x46) && buf[1] == 0x57 && buf[2] == 0x53);
}

/// Magic only
status_t lookup_archivesinternal(bela::MemView mv, hazel_result &hr) {
  // MSI // 0x4d434923
  constexpr const uint8_t msiMagic[] = {0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1};
  if (mv.StartsWith(msiMagic)) {
    hr.assign(types::msi, L"Windows Installer packages");
    return Found;
  }
  // DEB
  constexpr const uint8_t debMagic[] = {0x21, 0x3C, 0x61, 0x72, 0x63, 0x68, 0x3E, 0x0A, 0x64, 0x65, 0x62,
                                        0x69, 0x61, 0x6E, 0x2D, 0x62, 0x69, 0x6E, 0x61, 0x72, 0x79};
  if (mv.StartsWith(debMagic)) {
    hr.assign(types::deb, L"Debian packages");
    return Found;
  }
  // RPM
  constexpr const uint8_t rpmMagic[] = {0xED, 0xAB, 0xEE, 0xDB}; // size>96
  if (mv.StartsWith(rpmMagic) && mv.size() > 96) {
    hr.assign(types::rpm, L"RPM Package Manager");
    return Found;
  }
  constexpr const uint8_t crxMagic[] = {0x43, 0x72, 0x32, 0x34};
  if (mv.StartsWith(crxMagic)) {
    hr.assign(types::crx, L"Chrome Extension");
    return Found;
  }
  // XZ
  constexpr const uint8_t xzMagic[] = {0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00};
  if (mv.StartsWith(xzMagic)) {
    hr.assign(types::xz, L"XZ archive data");
    return Found;
  }
  // GZ
  constexpr const uint8_t gzMagic[] = {0x1F, 0x8B, 0x8};
  if (mv.StartsWith(gzMagic)) {
    hr.assign(types::gz, L"GZ archive data");
    return Found;
  }
  // BZ2
  // https://github.com/dsnet/compress/blob/master/doc/bzip2-format.pdf
  constexpr const uint8_t bz2Magic[] = {0x42, 0x5A, 0x68};
  if (mv.StartsWith(bz2Magic)) {
    hr.assign(types::bz2, L"BZ2 archive data");
    return Found;
  }

  // NES
  constexpr const uint8_t nesMagic[] = {0x41, 0x45, 0x53, 0x1A};
  if (mv.StartsWith(nesMagic)) {
    hr.assign(types::nes, L"Nintendo NES ROM");
    return Found;
  }

  // AR
  // constexpr const uint8_t arMagic[]={0x21,0x3c,0x61,0x72,0x63,0x68,0x3E};
  constexpr const uint8_t zMagic[] = {0x1F, 0xA0, 0x1F, 0x9D};
  if (mv.StartsWith(zMagic)) {
    hr.assign(types::z, L"X compressed archive data");
    return Found;
  }

  constexpr const uint8_t lzMagic[] = {0x4C, 0x5A, 0x49, 0x50};
  if (mv.StartsWith(lzMagic)) {
    hr.assign(types::lz, L"LZ archive data");
    return Found;
  }
  // SWF
  if (IsSwf(mv.data(), mv.size())) {
    hr.assign(types::swf, L"Adobe Flash file format");
    return Found;
  }
  // EPUB
  if (IsEPUB(mv.data(), mv.size())) {
    hr.assign(types::epub, L"EPUB document");
    return Found;
  }
  return None;
}

inline bool IsZip(const uint8_t *buf, size_t size) {
  return (size > 3 && buf[0] == 0x50 && buf[1] == 0x4B && (buf[2] == 0x3 || buf[2] == 0x5 || buf[2] == 0x7) &&
          (buf[3] == 0x4 || buf[3] == 0x6 || buf[3] == 0x8));
}

status_t LookupArchives(bela::MemView mv, hazel_result &hr) {
  if (IsZip(mv.data(), mv.size())) {
    hr.assign(types::zip, L"ZIP file");
    return Found;
  }
  if (lookup_7zinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_rarinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_xarinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_dmginternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_pdfinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_wiminternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_cabinetinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_tarinternal(mv, hr) == Found) {
    return Found;
  }
  if (lookup_sqliteinternal(mv, hr) == Found) {
    return Found;
  }
  return lookup_archivesinternal(mv, hr);
}
} // namespace hazel::internal
