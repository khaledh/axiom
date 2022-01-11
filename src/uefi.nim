import std/strformat
import std/tables

import lib/guid
import debug
import uefitypes

const
  EfiLzmaCustomDecompressGuid*   = parseGuid("ee4e5898-3914-4259-6e9d-dc7bd79403cf")
  EfiDxeServicesTableGuid*       = parseGuid("05ad34ba-6f02-4214-2e95-4da0398e2bb9")
  EfiHobListGuid*                = parseGuid("7739f24c-93d7-11d4-3a9a-0090273fc14d")
  EfiMemoryTypeInfoGuid*         = parseGuid("4c19049f-4137-4dd3-109c-8b97a83ffdfa")
  EfiDebugImageInfoTableGuid*    = parseGuid("49152e77-1ada-4764-a2b7-7afefed95e8b")
  EfiMemoryStatusCodeRecordGuid* = parseGuid("060cc026-4c0d-4dda-418f-595fef00a502")
  EfiSmbiosTableGuid*            = parseGuid("eb9d2d31-2d88-11d3-169a-0090273fc14d")
  EfiAcpi1TableGuid*             = parseGuid("eb9d2d30-2d88-11d3-169a-0090273fc14d")
  EfiAcpi2TableGuid*             = parseGuid("8868e871-e4f1-11d3-22bc-0080c73c8881")
  EfiMemoryAttributesTableGuid*  = parseGuid("dcfa911d-26eb-469f-20a2-38b7dc461220")

let efiGuids = {
  EfiLzmaCustomDecompressGuid   : ("LZMA_CUSTOM_DECOMPRESS_GUID", "LZMA Custom Decompress"),
  EfiDxeServicesTableGuid       : ("DXE_SERVICES_TABLE_GUID", "DXE Services Table"),
  EfiHobListGuid                : ("HOB_LIST_GUID", "HOB (Hand-Off Block) List"),
  EfiMemoryTypeInfoGuid         : ("EFI_MEMORY_TYPE_INFORMATION_GUID", "Memory Type Information"),
  EfiDebugImageInfoTableGuid    : ("EFI_DEBUG_IMAGE_INFO_TABLE_GUID", "Debug Image Info Table"),
  EfiMemoryStatusCodeRecordGuid : ("MEMORY_STATUS_CODE_RECORD_GUID", "Memory Status Code Record"),
  EfiSmbiosTableGuid            : ("SMBIOS_TABLE_GUID", "SMBIOS Table"),
  EfiAcpi1TableGuid             : ("ACPI_TABLE_GUID", "ACPI 1.0 Table"),
  EfiAcpi2TableGuid             : ("EFI_ACPI_TABLE_GUID", "ACPI 2.0+ Table"),
  EfiMemoryAttributesTableGuid  : ("EFI_MEMORY_ATTRIBUTES_TABLE_GUID", "Memory Attributes Table"),
}.toTable

proc getUefiConfigTables*(st: ptr EfiSystemTable): Table[Guid, pointer] =
  for i in 0 ..< st.numTableEntries:
    let entry = st.configTable[i]
    result[entry.vendorGuid] = entry.vendorTable

proc dumpUefiConfigTables*(st: ptr EfiSystemTable) =
  let configTables = getUefiConfigTables(st)

  println("")
  println("UEFI Configuration Table")
  for guid, p in configTables.pairs:
    print(&"  {$guid}")
    if efiGuids.contains(guid):
      print(&"  {efiGuids[guid][1]}")
