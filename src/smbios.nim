import std/tables
import std/strformat

import console
import uefi, uefitypes

type
  SmbiosEntryPoint32* {.packed.} = object
    anchor: uint32
    checksum: uint8
    length: uint8
    majorVersion: uint8
    minorVersion: uint8
    maxStructSize: uint16
    revision: uint8
    formattedArea: array[5, uint8]
    intermediateAnchor: array[5, uint8]
    intermediateChecksum: uint8
    structTableLen: uint16
    structTableAddr: uint32
    structCount: uint16
    revisionBcd: uint8

  SmbiosStructHeader* {.packed.} = object
    `type`: uint8
    length: uint8
    handle: uint16

  BiosInformation {.packed.} = object
    hdr: SmbiosStructHeader
    vendor: uint8
    version: uint8
    startingAddressSegment: uint16
    releaseDate: uint8
    romSize: uint8
    characteristics: uint64
    characteristicsExtensionByte1: uint8
    characteristicsExtensionByte2: uint8
    systemBiosMajorRelease: uint8
    systemBiosMinorRelease: uint8
    embeddedControllerFwMajorRelease: uint8
    embeddedControllerFwMinorRelease: uint8

  SystemInformation {.packed.} = object
    hdr: SmbiosStructHeader
    manufacturer: uint8
    productName: uint8
    version: uint8
    serialNo: uint8
    uuid: array[16, uint8]
    wakeupType: uint8
    sku: uint8
    family: uint8

  SystemEnclosure {.packed.} = object
    hdr: SmbiosStructHeader
    manufacturer: uint8
    `type`: uint8
    version: uint8
    serialNo: uint8
    assetTag: uint8
    bootupState: uint8
    powerSupplyState: uint8
    thermalState: uint8
    securityStatus: uint8
    oemDefined: uint32
    height: uint8
    numPowerCords: uint8
    containedElementCount: uint8
    containedElementRecordLen: uint8
    # containedElements: [?]uint8
    # sku: uint8

  ProcessorInformation {.packed.} = object
    hdr: SmbiosStructHeader
    socketDesignation: uint8
    procType: uint8
    procFamily: uint8
    procManufacturer: uint8
    procId: uint64
    procVersion: uint8
    voltage: uint8
    externalClock: uint16
    maxSpeed: uint16
    currentSpeed: uint16
    status: uint8
    procUpgrade: uint8
    l1CacheHandle: uint16
    l2CacheHandle: uint16
    l3CacheHandle: uint16
    serialNo: uint8
    assetTag: uint8
    partNo: uint8
    coreCount: uint8
    coreEnabled: uint8
    threadCount: uint8
    procCharacteristics: uint16
    procFamily2: uint16
    # SMBIOS 3.0 fields
    # core_count2: uint16
    # core_enabled2: uint16
    # thread_count2: uint16

  PhysicalMemoryArray {.packed.} = object
    hdr: SmbiosStructHeader
    location: uint8
    use: uint8
    errorCorrection: uint8
    maxCapacityKB: uint32
    errorInfoHandle: uint16
    memoryDeviceCount: uint16
    extendedMaxCapacity: uint64

  MemoryDevice {.packed.} = object
    hdr: SmbiosStructHeader
    physicalMemoryArrayHandle: uint16
    errorInformationHandle: uint16
    totalWidth: uint16
    dataWidth: uint16
    size: uint16
    formFactor: uint8
    deviceSet: uint8
    deviceLocator: uint8
    bankLocator: uint8
    memoryType: uint8
    typeDetail: uint16
    # SMBIOS 2.3
    speed: uint16
    manufacturer: uint8
    serialNo: uint8
    assetTag: uint8
    partNo: uint8
    # SMBIOS 2.6
    attributes: uint8
    # SMBIOS 2.7
    extendedSize: uint32
    configuredMemorySpeed: uint16
    # SMBIOS 2.8
    minVoltage: uint16
    maxVoltage: uint16
    configuredVoltage: uint16
    # SMBIOS 3.2
    memoryTechnology: uint8
    memoryOpModeCapability: uint16
    firmwareVersion: uint8
    moduleManufacturerId: uint16
    moduleProductId: uint16
    memorySubsystemControllerManufacturerId: uint16
    memorySubsystemControllerProductId: uint16
    nonvolatileSize: uint64
    volatileSize: uint64
    cacheSize: uint64
    logicalSize: uint64
    # SMBIOS 3.3
    extendedSpeed: uint32
    extendedConfiguredMemorySpeed: uint32

  MemoryArrayMappedAddress {.packed.} = object
    hdr: SmbiosStructHeader
    startingAddress: uint32
    endingAddress: uint32
    memoryArrayHandle: uint16
    partitionWidth: uint8
    extendedStartingAddress: uint32
    extendedEndingAddress: uint32

  SystemBootInformation {.packed.} = object
    hdr: SmbiosStructHeader
    reserved: array[6, uint8]
    status: uint8

proc parseStringBytes(stringBytes: ptr UncheckedArray[char], strings: var seq[cstring]): int =
  if stringBytes[0] == '\0':
    return 2

  strings &= ""

  var start, `end` = 0
  while stringBytes[start] != '\0':
    `end` = start
    while stringBytes[`end`] != '\0':
      inc(`end`)
    strings &= cast[cstring](addr stringBytes[start])
    start = `end` + 1

  return start + 1

proc showBiosInformation(table: ptr BiosInformation, strings: seq[cstring]) =
  writeln(&"    BIOS Information (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Vendor:                          {strings[table.vendor]}")
  writeln(&"      Version:                         {strings[table.version]}")
  writeln(&"      Release Date:                    {strings[table.release_date]}")
  writeln(&"      Starting Address Segment:        {table.startingAddressSegment:0>4x}h")
  writeln(&"      ROM Size:                        {(table.romSize.int64 + 1) * 64 * 1024}")
  writeln(&"      Characteristics:                 {table.characteristics:0>16x}")
  writeln(&"      Characteristics Extension:       {table.characteristicsExtensionByte1:0>2x}, {table.characteristicsExtensionByte2:0>2x}")
  writeln(&"      System BIOS Release:             {table.systemBiosMajorRelease}.{table.systemBios_MinorRelease}")
  writeln(&"      Embedded Controller FW Release:  {table.embeddedControllerFwMajorRelease}.{table.embeddedControllerFwMinorRelease}")

proc showSystemInformation(table: ptr SystemInformation, strings: seq[cstring]) =
  writeln(&"    System Information (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Manufacturer:                    {strings[table.manufacturer]}")
  writeln(&"      Product Name:                    {strings[table.productName]}")
  writeln(&"      Version:                         {strings[table.version]}")
  writeln(&"      Serial No:                       {strings[table.serialNo]}")
  writeln(&"      Wake-up Type:                    {table.wakeupType}")
  writeln(&"      SKU:                             {strings[table.sku]}")
  writeln(&"      Family:                          {strings[table.family]}")

proc showSystemEnclosure(table: ptr SystemEnclosure, strings: seq[cstring]) =
  writeln(&"    System Enclosure or Chassis (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Manufacturer:                    {strings[table.manufacturer]}")
  writeln(&"      Type:                            {table.type}")
  writeln(&"      Version:                         {strings[table.version]}")
  writeln(&"      Serial No:                       {strings[table.serialNo]}")
  writeln(&"      Asset Tag No:                    {strings[table.assetTag]}")
  writeln(&"      Boot-up State:                   {table.bootupState}")
  writeln(&"      Power Supply State:              {table.powerSupplyState}")
  writeln(&"      Thermal State:                   {table.thermalState}")
  writeln(&"      Security Status:                 {table.securityStatus}")
  writeln(&"      OEM-defined:                     {table.oemDefined}")
  writeln(&"      Height:                          {table.height}")
  writeln(&"      # Power Cords:                   {table.numPowerCords}")
  writeln(&"      # Contained Elements:            {table.containedElementCount}")
  writeln(&"      Contained Element Record Length: {table.containedElementRecordLen}")

proc showProcessorInformation(table: ptr ProcessorInformation, strings: seq[cstring]) =
  writeln(&"    Processor Information (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Socket Designation:              {strings[table.socketDesignation]}")
  writeln(&"      Procssor Type:                   {table.procType}")
  writeln(&"      Procssor Family:                 {table.procFamily}")
  writeln(&"      Processor Manufacturer:          {strings[table.proc_manufacturer]}")
  writeln(&"      Processor ID:                    {table.procId:0>16x}h")
  writeln(&"      Processor Version:               {strings[table.procVersion]}")
  writeln(&"      Voltage:                         {table.voltage}")
  writeln(&"      Max Speed:                       {table.maxSpeed} MHz")
  writeln(&"      Current Speed:                   {table.currentSpeed} MHz")
  writeln(&"      Status:                          {table.status:0>2x}h")
  writeln(&"      Processor Upgrade:               {table.procUpgrade}")
  writeln(&"      L1 Cache Handle:                 {table.l1CacheHandle:0>4x}h")
  writeln(&"      L2 Cache Handle:                 {table.l2CacheHandle:0>4x}h")
  writeln(&"      L3 Cache Handle:                 {table.l3CacheHandle:0>4x}h")
  writeln(&"      Serial No:                       {strings[table.serialNo]}")
  writeln(&"      Asset Tag:                       {strings[table.assetTag]}")
  writeln(&"      Part No:                         {strings[table.partNo]}")
  writeln(&"      Core Count:                      {table.coreCount}")
  writeln(&"      Core Enabled:                    {table.coreEnabled}")
  writeln(&"      Thread Count:                    {table.threadCount}")
  writeln(&"      Processor Characteristics:       {table.procCharacteristics:0>4x}")
  writeln(&"      Procssor Family 2:               {table.procFamily2}")
  # SMBIOS 3.0 fields
  # io.println("      Core Count 2:              {}", .{table.core_count2});
  # io.println("      Core Enabled 2:            {}", .{table.core_enabled2});
  # io.println("      Thread Count 2:            {}", .{table.thread_count2});

proc showPhysicalMemoryArray(table: ptr PhysicalMemoryArray, strings: seq[cstring]) =
  writeln(&"    Physical Memory Array (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Location:                        {table.location}")
  writeln(&"      Use:                             {table.use}")
  writeln(&"      Error Correction:                {table.errorCorrection}")
  writeln(&"      Maximum Capacity:                {table.maxCapacityKB div 1024} MB")
  writeln(&"      Error Information Handle:        {table.errorInfoHandle:0>4x}h")
  writeln(&"      Number of Memory Devices:        {table.memoryDeviceCount}")
  writeln(&"      Extended Maximum Capacity:       {table.extendedMaxCapacity}")

proc showMemoryDevice(table: ptr MemoryDevice, strings: seq[cstring]) =
  writeln(&"    Memory Device (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Physical Memory Array Handle:    {table.physicalMemoryArrayHandle:0>4x}h")
  writeln(&"      Memory Error Information Handle: {table.errorInformationHandle:0>4x}h")
  writeln(&"      Total Width:                     {table.totalWidth:0>4x}h")
  writeln(&"      Data Width:                      {table.dataWidth:0>4x}h")
  writeln(&"      Size:                            {table.size} MB")
  writeln(&"      Form Factor:                     {table.formFactor}")
  writeln(&"      Device Set:                      {table.deviceSet}")
  writeln(&"      Device Locator:                  {strings[table.deviceLocator]}")
  writeln(&"      Bank Locator:                    {strings[table.bankLocator]}")
  writeln(&"      Memory Type:                     {table.memoryType}")
  writeln(&"      Type Detail:                     {table.typeDetail}")
  writeln(&"      Speed:                           {table.speed:0>4x}h")
  writeln(&"      Manufacturer:                    {strings[table.manufacturer]}")
  writeln(&"      Serial Number:                   {strings[table.serialNo]}")
  writeln(&"      Asset Tag:                       {strings[table.assetTag]}")
  writeln(&"      Part Number:                     {strings[table.partNo]}")
  writeln(&"      Attributes:                      {table.attributes:0>2x}h")
  writeln(&"      Extended Size:                   {table.extendedSize}")
  writeln(&"      Configured Speed:                {table.configuredMemorySpeed:0>4x}h")
  writeln(&"      Minimum Voltage:                 {table.minVoltage}")
  writeln(&"      Maximum Voltage:                 {table.maxVoltage}")
  writeln(&"      Configured Voltage:              {table.configuredVoltage}")

proc showMemoryArrayMappedAddress(table: ptr MemoryArrayMappedAddress, strings: seq[cstring]) =
  writeln(&"    Memory Array Mapped Address (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Starting Address:                {table.startingAddress:0>8x}h ({table.startingAddress div 1024} MB)")
  writeln(&"      Ending Address:                  {table.endingAddress:0>8x}h ({(table.endingAddress + 1) div 1024} MB)")
  writeln(&"      Physical Memory Array Handle:    {table.memoryArrayHandle:0>4x}h")
  writeln(&"      Partition Width:                 {table.partitionWidth}")
  writeln(&"      Extended Starting Address:       {table.extendedStartingAddress:0>16x}h")
  writeln(&"      Extended Ending Address:         {table.extendedEndingAddress:0>16x}h")

proc showSystemBootInformation(table: ptr SystemBootInformation, strings: seq[cstring]) =
  writeln(&"    System Boot Information (Type: {table.hdr.type}, Handle: {table.hdr.handle:0>4x}h)")
  writeln(&"      Status:                          {table.status}")

proc showSmbios*(sysTable: ptr EfiSystemTable) =
  let configTables = getUefiConfigTables(sysTable)
  var smbiosConfigTable = configTables.getOrDefault(EfiSmbiosTableGuid)

  if isNil(smbiosConfigTable):
    quit("Cannot find SMBIOS table")

  let smbios = cast[ptr SmbiosEntryPoint32](smbiosConfigTable)

  writeln("SMBIOS")
  writeln(&"  Version: {smbios.majorVersion}.{smbios.minorVersion}")
  writeln(&"  Maximum Structure Size: {smbios.maxStructSize}")
  writeln(&"  Structure Table Length: {smbios.structTableLen}")
  writeln(&"  Structure Count: {smbios.structCount}")

  var hdr = cast[ptr SmbiosStructHeader](smbios.structTableAddr.uint64)

  for i in 0.uint16 ..< smbios.structCount:
    let stringBytes = cast[ptr UncheckedArray[char]](cast[uint64](hdr) + hdr.length)
    var strings: seq[cstring]
    let stringsLen = parseStringBytes(stringBytes, strings)

    writeln("")
    case hdr.type:
    of 0: showBiosInformation(cast[ptr BiosInformation](hdr), strings)
    of 1: showSystemInformation(cast[ptr SystemInformation](hdr), strings)
    of 3: showSystemEnclosure(cast[ptr SystemEnclosure](hdr), strings)
    of 4: showProcessorInformation(cast[ptr ProcessorInformation](hdr), strings)
    of 16: showPhysicalMemoryArray(cast[ptr PhysicalMemoryArray](hdr), strings)
    of 17: showMemoryDevice(cast[ptr MemoryDevice](hdr), strings)
    of 19: showMemoryArrayMappedAddress(cast[ptr MemoryArrayMappedAddress](hdr), strings)
    of 32: showSystemBootInformation(cast[ptr SystemBootInformation](hdr), strings)
    else: discard

    hdr = cast[ptr SmbiosStructHeader](cast[uint64](hdr) + hdr.length.uint64 + stringsLen.uint64)
