////
/// DON'T include this file
/// km/ntifs.h
#error "DON'T include this file"
#ifndef REPARSE_H
#define REPARSE_H
//
// Maximum allowed size of the reparse data.
//

#define MAXIMUM_REPARSE_DATA_BUFFER_SIZE      ( 16 * 1024 )

//
// Predefined reparse tags.
// These tags need to avoid conflicting with IO_REMOUNT defined in ntos\inc\io.h
//

#define IO_REPARSE_TAG_RESERVED_ZERO             (0)
#define IO_REPARSE_TAG_RESERVED_ONE              (1)
#define IO_REPARSE_TAG_RESERVED_TWO              (2)

//
// The value of the following constant needs to satisfy the following conditions:
//  (1) Be at least as large as the largest of the reserved tags.
//  (2) Be strictly smaller than all the tags in use.
//

#define IO_REPARSE_TAG_RESERVED_RANGE            IO_REPARSE_TAG_RESERVED_TWO

//
// The reparse tags are a ULONG. The 32 bits are laid out as follows:
//
//   3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1
//   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//  +-+-+-+-+-----------------------+-------------------------------+
//  |M|R|N|D|     Reserved bits     |       Reparse Tag Value       |
//  +-+-+-+-+-----------------------+-------------------------------+
//
// M is the Microsoft bit. When set to 1, it denotes a tag owned by Microsoft.
//   All ISVs must use a tag with a 0 in this position.
//   Note: If a Microsoft tag is used by non-Microsoft software, the
//   behavior is not defined.
//
// R is reserved.  Must be zero for non-Microsoft tags.
//
// N is name surrogate. When set to 1, the file represents another named
//   entity in the system.
//
// D is the directory bit. When set to 1, indicates that any directory
//   with this reparse tag can have children. Has no special meaning when used
//   on a non-directory file. Not compatible with the name surrogate bit.
//
// The M and N bits are OR-able.
// The following macros check for the M and N bit values:
//

//
// Macro to determine whether a reparse point tag corresponds to a tag
// owned by Microsoft.
//

#define IsReparseTagMicrosoft(_tag) (              \
                           ((_tag) & 0x80000000)   \
                           )

//
// Macro to determine whether a reparse point tag is a name surrogate
//

#define IsReparseTagNameSurrogate(_tag) (          \
                           ((_tag) & 0x20000000)   \
                           )

//
// Macro to determine whether a directory with this reparse point can have
// children.
//

#define IsReparseTagDirectory(_tag) (    \
                           ((_tag) & 0x10000000)   \
                           )

// end_winnt

//
// The following constant represents the bits that are valid to use in
// reparse tags.
//

#define IO_REPARSE_TAG_VALID_VALUES     (0xF000FFFF)

//
// Macro to determine whether a reparse tag is a valid tag.
//

#define IsReparseTagValid(_tag) (                               \
                  !((_tag) & ~IO_REPARSE_TAG_VALID_VALUES) &&   \
                  ((_tag) > IO_REPARSE_TAG_RESERVED_RANGE) &&   \
                  (((_tag) & 0x30000000) != 0x30000000)         \
                 )

///////////////////////////////////////////////////////////////////////////////
//
// Microsoft tags for reparse points.
//
///////////////////////////////////////////////////////////////////////////////

#define IO_REPARSE_TAG_MOUNT_POINT              (0xA0000003L)       // winnt
#define IO_REPARSE_TAG_HSM                      (0xC0000004L)       // winnt
#define IO_REPARSE_TAG_DRIVE_EXTENDER           (0x80000005L)
#define IO_REPARSE_TAG_HSM2                     (0x80000006L)       // winnt
#define IO_REPARSE_TAG_SIS                      (0x80000007L)       // winnt
#define IO_REPARSE_TAG_WIM                      (0x80000008L)       // winnt
#define IO_REPARSE_TAG_CSV                      (0x80000009L)       // winnt
#define IO_REPARSE_TAG_DFS                      (0x8000000AL)       // winnt
#define IO_REPARSE_TAG_FILTER_MANAGER           (0x8000000BL)
#define IO_REPARSE_TAG_SYMLINK                  (0xA000000CL)       // winnt
#define IO_REPARSE_TAG_IIS_CACHE                (0xA0000010L)
#define IO_REPARSE_TAG_DFSR                     (0x80000012L)       // winnt
#define IO_REPARSE_TAG_DEDUP                    (0x80000013L)       // winnt
#define IO_REPARSE_TAG_APPXSTRM                 (0xC0000014L)
#define IO_REPARSE_TAG_NFS                      (0x80000014L)       // winnt
#define IO_REPARSE_TAG_FILE_PLACEHOLDER         (0x80000015L)       // winnt
#define IO_REPARSE_TAG_DFM                      (0x80000016L)
#define IO_REPARSE_TAG_WOF                      (0x80000017L)       // winnt
#define IO_REPARSE_TAG_WCI                      (0x80000018L)       // winnt
#define IO_REPARSE_TAG_WCI_1                    (0x90001018L)       // winnt
#define IO_REPARSE_TAG_GLOBAL_REPARSE           (0xA0000019L)       // winnt
#define IO_REPARSE_TAG_CLOUD                    (0x9000001AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_1                  (0x9000101AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_2                  (0x9000201AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_3                  (0x9000301AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_4                  (0x9000401AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_5                  (0x9000501AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_6                  (0x9000601AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_7                  (0x9000701AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_8                  (0x9000801AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_9                  (0x9000901AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_A                  (0x9000A01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_B                  (0x9000B01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_C                  (0x9000C01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_D                  (0x9000D01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_E                  (0x9000E01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_F                  (0x9000F01AL)       // winnt
#define IO_REPARSE_TAG_CLOUD_MASK               (0x0000F000L)       // winnt
#define IO_REPARSE_TAG_APPEXECLINK              (0x8000001BL)       // winnt
#define IO_REPARSE_TAG_PROJFS                   (0x9000001CL)       // winnt
#define IO_REPARSE_TAG_LX_SYMLINK               (0xA000001DL)
#define IO_REPARSE_TAG_STORAGE_SYNC             (0x8000001EL)       // winnt
#define IO_REPARSE_TAG_WCI_TOMBSTONE            (0xA000001FL)       // winnt
#define IO_REPARSE_TAG_UNHANDLED                (0x80000020L)       // winnt
#define IO_REPARSE_TAG_ONEDRIVE                 (0x80000021L)       // winnt
#define IO_REPARSE_TAG_PROJFS_TOMBSTONE         (0xA0000022L)       // winnt
#define IO_REPARSE_TAG_AF_UNIX                  (0x80000023L)       // winnt
#define IO_REPARSE_TAG_LX_FIFO                  (0x80000024L)
#define IO_REPARSE_TAG_LX_CHR                   (0x80000025L)
#define IO_REPARSE_TAG_LX_BLK                   (0x80000026L)

///////////////////////////////////////////////////////////////////////////////
//
// Non-Microsoft tags for reparse points
//
///////////////////////////////////////////////////////////////////////////////

//
// Tag allocated to CONGRUENT, May 2000. Used by IFSTEST
//

#define IO_REPARSE_TAG_IFSTEST_CONGRUENT        (0x00000009L)

//
//  Tag allocated to Moonwalk Univeral for HSM
//  GUID: 257ABE42-5A28-4C8C-AC46-8FEA5619F18F
//

#define IO_REPARSE_TAG_MOONWALK_HSM             (0x0000000AL)

//
//  Tag allocated to Tsinghua Univeristy for Research purposes
//  No released products should use this tag
//  GUID: b86dff51-a31e-4bac-b3cf-e8cfe75c9fc2
//

#define IO_REPARSE_TAG_TSINGHUA_UNIVERSITY_RESEARCH (0x0000000BL)

//
// Tag allocated to ARKIVIO for HSM
//

#define IO_REPARSE_TAG_ARKIVIO                  (0x0000000CL)

//
//  Tag allocated to SOLUTIONSOFT for name surrogate
//

#define IO_REPARSE_TAG_SOLUTIONSOFT             (0x2000000DL)

//
//  Tag allocated to COMMVAULT for HSM
//

#define IO_REPARSE_TAG_COMMVAULT                (0x0000000EL)

//
//  Tag allocated to Overtone Software for HSM
//

#define IO_REPARSE_TAG_OVERTONE                 (0x0000000FL)

//
//  Tag allocated to Symantec (formerly to KVS Inc) for HSM
//  GUID: A49F7BF6-77CA-493c-A0AA-18DBB28D1098
//

#define IO_REPARSE_TAG_SYMANTEC_HSM2            (0x00000010L)

//
//  Tag allocated to Enigma Data for HSM
//

#define IO_REPARSE_TAG_ENIGMA_HSM               (0x00000011L)

//
//  Tag allocated to Symantec for HSM
//  GUID: B99F4235-CF1C-48dd-9E6C-459FA289F8C7
//

#define IO_REPARSE_TAG_SYMANTEC_HSM             (0x00000012L)

//
//  Tag allocated to INTERCOPE for HSM
//  GUID: F204BE2D-AEEB-4728-A31C-C7F4E9BEA758}
//

#define IO_REPARSE_TAG_INTERCOPE_HSM            (0x00000013L)

//
//  Tag allocated to KOM Networks for HSM
//

#define IO_REPARSE_TAG_KOM_NETWORKS_HSM         (0x00000014L)

//
//  Tag allocated to MEMORY_TECH for HSM
//  GUID: E51BA456-046C-43ea-AEC7-DC1A87E1FD49
//

#define IO_REPARSE_TAG_MEMORY_TECH_HSM          (0x00000015L)

//
//  Tag allocated to BridgeHead Software for HSM
//  GUID: EBAFF6E3-F21D-4496-8342-58144B3D2BD0
//

#define IO_REPARSE_TAG_BRIDGEHEAD_HSM           (0x00000016L)

//
//  Tag allocated to OSR for samples reparse point filter
//  GUID: 3740c860-b19b-11d9-9669-0800200c9a66
//

#define IO_REPARSE_TAG_OSR_SAMPLE               (0x20000017L)

//
//  Tag allocated to Global 360 for HSM
//  GUID: C4B51F66-7F00-4c55-9441-8A1B159F209B
//

#define IO_REPARSE_TAG_GLOBAL360_HSM            (0x00000018L)

//
//  Tag allocated to Altiris for HSM
//  GUID: fc1047eb-fb2d-45f2-a2f4-a71c1032fa2dB
//

#define IO_REPARSE_TAG_ALTIRIS_HSM              (0x00000019L)

//
//  Tag allocated to Hermes for HSM
//  GUID: 437E0FD5-FCB4-42fe-877A-C785DA662AC2
//

#define IO_REPARSE_TAG_HERMES_HSM               (0x0000001AL)

//
//  Tag allocated to PointSoft for HSM
//  GUID: 547BC7FD-9604-4deb-AE07-B6514DF5FBC6
//

#define IO_REPARSE_TAG_POINTSOFT_HSM            (0x0000001BL)

//
//  Tag allocated to GRAU Data Storage for HSM
//  GUID: 6662D310-5653-4D10-8C31-F8E166D1A1BD
//

#define IO_REPARSE_TAG_GRAU_DATASTORAGE_HSM     (0x0000001CL)

//
//  Tag allocated to CommVault for HSM
//  GUID: cc38adf3-c583-4efa-b183-72c1671941de
//

#define IO_REPARSE_TAG_COMMVAULT_HSM            (0x0000001DL)


//
//  Tag allocated to Data Storage Group for single instance storage
//  GUID: C1182673-0562-447a-8E40-4F0549FDF817
//

#define IO_REPARSE_TAG_DATASTOR_SIS             (0x0000001EL)


//
//  Tag allocated to Enterprise Data Solutions, Inc. for HSM
//  GUID: EB63DF9D-8874-41cd-999A-A197542CDAFC
//

#define IO_REPARSE_TAG_EDSI_HSM                 (0x0000001FL)


//
//  Tag allocated to HP StorageWorks Reference Information Manager for Files (HSM)
//  GUID: 3B0F6B23-0C2E-4281-9C19-C6AEEBC88CD8
//

#define IO_REPARSE_TAG_HP_HSM                   (0x00000020L)


//
//  Tag allocated to SER Beteiligung Solutions Deutschland GmbH (HSM)
//  GUID: 55B673F0-978E-41c5-9ADB-AF99640BE90E
//

#define IO_REPARSE_TAG_SER_HSM                  (0x00000021L)


//
//  Tag allocated to Double-Take Software (formerly NSI Software, Inc.) for HSM
//  GUID: f7cb0ce8-453a-4ae1-9c56-db41b55f6ed4
//

#define IO_REPARSE_TAG_DOUBLE_TAKE_HSM          (0x00000022L)


//
//  Tag allocated to Beijing Wisdata Systems CO, LTD for HSM
//  GUID: d546500a-2aeb-45f6-9482-f4b1799c3177
//

#define IO_REPARSE_TAG_WISDATA_HSM              (0x00000023L)


//
//  Tag allocated to Mimosa Systems Inc for HSM
//  GUID: 8ddd4144-1a22-404b-8a5a-fcd91c6ee9f3
//

#define IO_REPARSE_TAG_MIMOSA_HSM               (0x00000024L)


//
//  Tag allocated to H&S Heilig und Schubert Software AG for HSM
//  GUID: 77CA30C0-E5EC-43df-9E44-A4910378E284
//

#define IO_REPARSE_TAG_HSAG_HSM                 (0x00000025L)


//
//  Tag allocated to Atempo Inc. (Atempo Digital Archive)  for HSM
//  GUID: 9B64518A-D6A4-495f-8D01-392F38862F0C
//

#define IO_REPARSE_TAG_ADA_HSM                  (0x00000026L)


//
//  Tag allocated to Autonomy Corporation for HSM
//  GUID: EB112A57-10FC-4b42-B590-A61897FDC432
//

#define IO_REPARSE_TAG_AUTN_HSM                 (0x00000027L)


//
//  Tag allocated to Nexsan for HSM
//  GUID: d35eba9a-e722-445d-865f-dde1120acf16
//

#define IO_REPARSE_TAG_NEXSAN_HSM               (0x00000028L)


//
//  Tag allocated to Double-Take for SIS
//  GUID: BDA506C2-F74D-4495-9A8D-44FD8D5B4F42
//

#define IO_REPARSE_TAG_DOUBLE_TAKE_SIS          (0x00000029L)


//
//  Tag allocated to Sony for HSM
//  GUID: E95032E4-FD81-4e15-A8E2-A1F078061C4E
//

#define IO_REPARSE_TAG_SONY_HSM                 (0x0000002AL)


//
//  Tag allocated to Eltan Comm for HSM
//  GUID: E1596D9F-44D8-43f4-A2D6-E9FE8D3E28FB
//

#define IO_REPARSE_TAG_ELTAN_HSM                (0x0000002BL)


//
//  Tag allocated to Utixo LLC for HSM
//  GUID: 5401F960-2F95-46D0-BBA6-052929FE2C32
//

#define IO_REPARSE_TAG_UTIXO_HSM                (0x0000002CL)


//
//  Tag allocated to Quest Software for HSM
//  GUID: D546500A-2AEB-45F6-9482-F4B1799C3177
//

#define IO_REPARSE_TAG_QUEST_HSM                (0x0000002DL)


//
//  Tag allocated to DataGlobal GmbH for HSM
//  GUID: 7A09CA83-B7B1-4614-ADFD-0BD5F4F989C9
//

#define IO_REPARSE_TAG_DATAGLOBAL_HSM           (0x0000002EL)


//
//  Tag allocated to Qi Tech LLC for HSM
//  GUID: C8110B39-A4CE-432E-B58A-FBEAD296DF03
//

#define IO_REPARSE_TAG_QI_TECH_HSM              (0x2000002FL)

//
//  Tag allocated to DataFirst Corporation for HSM
//  GUID: E0E40591-6434-479f-94AC-DECF6DAEFB5C
//

#define IO_REPARSE_TAG_DATAFIRST_HSM            (0x00000030L)

//
//  Tag allocated to C2C Systems for HSM
//  GUID: 6F2F829C-36AE-4E88-A3B6-E2C24377EA1C
//

#define IO_REPARSE_TAG_C2CSYSTEMS_HSM           (0x00000031L)

//
//  Tag allocated to Waterford Technologies for deduplication
//  GUID: 0AF8B999-B8E8-408b-805F-5448E68F9274
//

#define IO_REPARSE_TAG_WATERFORD                (0x00000032L)

//
//  Tag allocated to Riverbed Technology for HSM
//  GUID: 3336274-255B-4038-9D39-14B0EC3F8256
//

#define IO_REPARSE_TAG_RIVERBED_HSM             (0x00000033L)

//
//  Tag allocated to Caringo, Inc.  for HSM
//  GUID: B92426FA-D35F-48DB-A452-8FD557A23353
//

#define IO_REPARSE_TAG_CARINGO_HSM              (0x00000034L)

//
//  Tag allocated to MaxiScale, Inc. for HSM
//  GUID: 643B4714-BA13-427b-B771-C5BFDE787BB7
//

#define IO_REPARSE_TAG_MAXISCALE_HSM            (0x20000035L)

//
//  Tag allocated to Citrix Systems for profile management
//  GUID: B9150EDE-5845-4818-841B-5BCBB3B848E3
//

#define IO_REPARSE_TAG_CITRIX_PM                (0x00000036L)

//
//  Tag allocated to OpenAFS for DFS
//  GUID: EF21A155-5C92-4470-AB3B-370403D96369
//

#define IO_REPARSE_TAG_OPENAFS_DFS              (0x00000037L)

//
//  Tag allocated to ZL Technologies Inc for HSM
//  GUID: A521FE7A-EB10-4148-BAC7-264359827B7E
//

#define IO_REPARSE_TAG_ZLTI_HSM                 (0x00000038L)

//
//  Tag allocated to EMC Corporation for HSM
//  GUID: 119EA2B9-8979-48b9-B4CE-5082AF2D81E5
//

#define IO_REPARSE_TAG_EMC_HSM                  (0x00000039L)

//
//  Tag allocated to VMware for profile management
//  GUID: 6D020A57-C9BB-4DA4-A43F-49686D8D5E77
//

#define IO_REPARSE_TAG_VMWARE_PM                (0x0000003AL)

//
//  Tag allocated to Arco Computer Products for backup
//  GUID: C933F72B-A64D-44d9-8CD9-F339D12390CC
//

#define IO_REPARSE_TAG_ARCO_BACKUP              (0x0000003BL)

//
//  Tag allocated to Carroll-Net for HSM
//  GUID: 805EB191-564B-415a-A78C-9ED0AF8E02FF
//

#define IO_REPARSE_TAG_CARROLL_HSM              (0x0000003CL)

//
//  Tag allocated to ComTrade for HSM
//  GUID: D546500A-2AEB-45F6-9482-F4B1799C3177
//

#define IO_REPARSE_TAG_COMTRADE_HSM             (0x0000003DL)

//
//  Tag allocated to EaseVault for HSM
//  GUID: BBA65D6F-F8A0-48CC-B748-DBD5FFFCCFB1
//

#define IO_REPARSE_TAG_EASEVAULT_HSM            (0x0000003EL)

//
//  Tag allocated to Hitachi Data Systems for HSM
//  GUID: DC095FD2-AC3C-46BA-9E58-DD182BE86AF4
//

#define IO_REPARSE_TAG_HDS_HSM                  (0x0000003FL)

//
//  Tag allocated to Maginatics for network redirector
//  GUID: 1907AE87-388D-4854-AF63-B585A619DF28
//

#define IO_REPARSE_TAG_MAGINATICS_RDR           (0x00000040L)

//
//  Tag allocated to Google for HSM
//  GUID: 40550C94-68DB-4726-9C62-47BB88577BD0
//

#define IO_REPARSE_TAG_GOOGLE_HSM               (0x00000041L)

//
//  Tag allocated to Quaddra for HSM
//  GUID: 491D6619-20C3-4BFA-AF98-4EA2A7F53F1D
//

#define IO_REPARSE_TAG_QUADDRA_HSM              (0x00000042L)

//
//  Tag allocated to HP for backup
//  GUID: 0c5ed442-4928-473e-970e-5389ff2b4328
//

#define IO_REPARSE_TAG_HP_BACKUP                (0x00000043L)

//
//  Tag allocated to DropBox for HSM
//  GUID: C5BB0F16-68E9-4456-B6B9-5F5EE5F89965
//

#define IO_REPARSE_TAG_DROPBOX_HSM              (0x00000044L)

//
//  Tag allocated to Adobe for HSM
//  GUID: 48F5DB1C-ED3C-44F7-8EBA-3623C09D6179
//

#define IO_REPARSE_TAG_ADOBE_HSM                (0x00000045L)

//
//  Tag allocated to HP for HPE Data Protector HSM
//  GUID: 3370DFC4-DCED-4DEB-AD0C-9A2416B3198B
//

#define IO_REPARSE_TAG_HP_DATA_PROTECT          (0x00000046L)

//
//  Tag allocated to Activision for HSM
//  GUID: 18CC35B3-5DFF-408E-B42E-9FA6731BC506
//

#define IO_REPARSE_TAG_ACTIVISION_HSM           (0x00000047L)

//
//  Tag allocated to Hitachi for HSM
//  GUID: DFFD30B6-6CC0-46A8-94C2-AAE32C9B16D1
//

#define IO_REPARSE_TAG_HDS_HCP_HSM              (0x00000048L)

//
//  Tag allocated to AuriStor File System
//  GUID: AFBD291F-3DF8-46BA-BE87-47A632714BB7
//

#define IO_REPARSE_TAG_AURISTOR_FS              (0x00000049L)

//
//  Tag allocated to ItStation for restore
//  GUID: C33A7A21-6142-4860-9AAA-0008F1064616
//

#define IO_REPARSE_TAG_ITSTATION                (0x0000004AL)

//
//  Tag allocated to Spharsoft for dedup
//  GUID: 2AB7C758-E6AA-43FB-9194-80A436E22F26
//

#define IO_REPARSE_TAG_SPHARSOFT                (0x0000004BL)

//
//  Tag allocated to AlertBoot for encryption
//  GUID: 80050DB9-52D3-4742-B28B-3918177242D5
//

#define IO_REPARSE_TAG_ALERTBOOT                (0x2000004CL)

//
//  Tag allocated to mTalos for monitoring
//  GUID: C51BB90B-77D2-43B9-8E88-CC5745E977FF
//

#define IO_REPARSE_TAG_MTALOS                   (0x0000004DL)

//
//  Tag allocated to CTERA for HSM
//  GUID: A0431A3B-7789-485C-8638-FCA288FDBA71
//

#define IO_REPARSE_TAG_CTERA_HSM                (0x0000004EL)

//
//  Tag allocated to Nippon Techno Lab for HSM
//  GUID: 8E5C2A8D-7344-4923-A741-2E9EFF128126
//

#define IO_REPARSE_TAG_NIPPON_HSM               (0x0000004FL)

//
//  Tag allocated to Redstor for HSM
//  GUID: E6636830-4534-4FA2-9D4F-DDD22818EDCC
//

#define IO_REPARSE_TAG_REDSTOR_HSM              (0x00000050L)

//
//  Tag allocated to NeuShield for monitoring
//  GUID: 585414E1-6E0E-46B6-8838-ED837173F590
//

#define IO_REPARSE_TAG_NEUSHIELD                (0x00000051L)
#endif