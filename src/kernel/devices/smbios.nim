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
