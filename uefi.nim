import util

type
  EfiStatus* = distinct uint

  EfiHandle* = pointer

  EfiTableHeader* = object
    signature*: uint64
    revision*: uint32
    headerSize*: uint32
    crc32*: uint32
    reserved*: uint32

  EfiConfigurationTableEntry* = object
    vendorGuid*: Guid
    vendorTable*: pointer

  EfiSystemTable* = object
    header*: EfiTableHeader
    firmwareVendor*: WideCString
    firmwareRevision*: uint32
    consoleInHandle*: EfiHandle
    conIn*: pointer
    consoleOutHandle*: EfiHandle
    conOut*: ptr SimpleTextOutputInterface
    standardErrorHandle*: EfiHandle
    stdErr*: ptr SimpleTextOutputInterface
    runtimeServices*: pointer
    bootServices*: ptr EfiBootServices
    numTableEntries*: uint
    configTable*: ptr UncheckedArray[EfiConfigurationTableEntry]

  SimpleTextOutputInterface* = object
    reset*: TextReset
    outputString*: TextOutputString
    testString*: TextTestString
    queryMode*: TextQueryMode
    setMode*: TextSetMode
    setAttribute*: TextSetAttribute
    clearScreen*: TextClearScreen
    setCursorPos*: TextSetCursorPosition
    enableCursor*: TextEnableCursor
    mode*: ptr SimpleTextOutputMode

  TextReset = proc (this: ptr SimpleTextOutputInterface, extendedVerification: bool): EfiStatus {.cdecl.}
  TextOutputString = proc (this: ptr SimpleTextOutputInterface, str: ptr Utf16Char): EfiStatus {.cdecl, gcsafe, locks: 0, tags: [WriteIOEffect].}
  TextTestString = proc (this: ptr SimpleTextOutputInterface, str: openArray[Utf16Char]): EfiStatus {.cdecl.}
  TextQueryMode = proc (this: ptr SimpleTextOutputInterface, modeNum: uint, cols, rows: ptr uint): EfiStatus {.cdecl.}
  TextSetMode = proc (this: ptr SimpleTextOutputInterface, modeNum: uint): EfiStatus {.cdecl.}
  TextSetAttribute = proc (this: ptr SimpleTextOutputInterface, attribute: uint): EfiStatus {.cdecl.}
  TextClearScreen = proc (this: ptr SimpleTextOutputInterface): EfiStatus {.cdecl.}
  TextSetCursorPosition = proc (this: ptr SimpleTextOutputInterface, cols, rows: uint): EfiStatus {.cdecl.}
  TextEnableCursor = proc (this: ptr SimpleTextOutputInterface, enable: bool): EfiStatus {.cdecl.}

  SimpleTextOutputMode* = object
    maxMode*: int32
    currentMode*: int32
    attribute*: int32
    cursorCol*: int32
    cursorRow*: int32
    cursorVisible*: bool

  EfiBootServices = object
    hdr*: EfiTableHeader
    # task priority services
    raiseTpl*: pointer
    restoreTpl*: pointer
    # memory services
    allocatePages*: pointer
    freePages*: pointer
    getMemoryMap*: GetMemoryMap
    allocatePool*: AllocatePool
    freePool*: pointer
    # event & timer services
    createEvent*: pointer
    setTimer*: pointer
    waitForEvent*: pointer
    signalEvent*: pointer
    closeEvent*: pointer
    checkEvent*: pointer
    # protocol handler services
    installProtocolInterface*: pointer
    reinstallProtocolInterface*: pointer
    uninstallProtocolInterface*: pointer
    handleProtocol*: pointer
    reserved*: pointer
    registerProtocolNotify*: pointer
    locateHandle*: pointer
    locateDevicePath*: pointer
    installConfigurationTable*: pointer
    # image services
    loadImage*: pointer
    startImage*: pointer
    exit*: pointer
    unloadImage*: pointer
    exitBootServices*: ExitBootServices
    # misc services
    getNextMonotonicCount*: pointer
    stall*: pointer
    setWatchdogTimer*: pointer
    # driver support services
    connectController*: pointer
    disconnectController*: pointer
    # open and close protocol services
    openProtocol*: pointer
    closeProtocol*: pointer
    openProtocolInformation*: pointer
    # library services
    protocolsPerHandle*: pointer
    locateHandleBuffer*: pointer
    locateProtocol*: LocateProtocol
    installMultipleProtocolInterfaces*: pointer
    uninstallMultipleProtocolInterfaces*: pointer
    # 32-bit CRC services
    calculateCrc32*: pointer
    # misc services
    copyMem*: pointer
    setMem*: pointer
    createEventEx*: pointer

  ExitBootServices* = proc (imageHandler: EfiHandle, mapKey: uint): EfiStatus {.cdecl.}
  LocateProtocol* = proc (protocol: ptr Guid, registration: pointer, `interface`: ptr pointer): EfiStatus {.cdecl.}

  #[
    Memory Management
  ]#

  AllocatePool* = proc (poolType: EfiMemoryType, size: uint, buffer: ptr pointer): EfiStatus {.cdecl.}

  GetMemoryMap* = proc (
    memoryMapSize: ptr uint,
    memoryMap: ptr UncheckedArray[EfiMemoryDescriptor],
    mapKey: ptr uint,
    descriptorSize: ptr uint,
    descriptorVersion: ptr uint32
  ): EfiStatus {.cdecl.}

  EfiMemoryType* = enum
    mtReservedMemoryType      = "Reserved"
    mtLoaderCode              = "Loader Code"
    mtLoaderData              = "Loader Data"
    mtBootServicesCode        = "Boot Services Code"
    mtBootServicesData        = "Boot Services Data"
    mtRuntimeServicesCode     = "Runtime Services Code"
    mtRuntimeServicesData     = "Runtime Services Data"
    mtConventionalMemory      = "Conventional Memory"
    mtUnusableMemory          = "Unusable Memory"
    mtACPIReclaimMemory       = "ACPI Reclaim Memory"
    mtACPIMemoryNVS           = "ACPI Memory NVS"
    mtMemoryMappedIO          = "Memory Mapped IO"
    mtMemoryMappedIOPortSpace = "Memory Mapped IO Port Space"
    mtPalCode                 = "PAL Code"
    mtPersistentMemory        = "Persistent Memory"
    mtMaxMemoryType

  EfiMemoryDescriptor* = object
    `type`*: EfiMemoryType
    physicalStart*: EfiPhysicalAddress
    virtualStart*: EfiVirtualAddress
    numberOfPages*: uint64
    attribute*: uint64
  EfiPhysicalAddress* = uint64
  EfiVirtualAddress* = uint64

  #[
    Graphics Output Protocol
  ]#

  EfiGraphicsOutputProtocol* = object
    queryMode*: GopQueryMode
    setMode*: GopSetMode
    blt*: pointer
    mode*: ptr GopMode

  GopMode* = object
    maxMode*: uint32
    currentMode*: uint32
    info*: ptr GopModeInfo
    sizeOfInfo*: uint
    frameBufferBase*: EfiPhysicalAddress
    frameBufferSize*: uint

  GopPixelBitmask* = object
    redMask*: uint32
    greenMask*: uint32
    blueMask*: uint32
    reservedMask*: uint32

  GopPixelFormat* = enum
    gpfPixelRedGreenBlueReserved8BitPerColor,
    gpfPixelBlueGreenRedReserved8BitPerColor,
    gpfPixelBitMask,
    gpfPixelBltOnly,
    gpfPixelFormatMax

  GopModeInfo* = object
    version*: uint32
    horizontalResolution*: uint32
    verticalResolution*: uint32
    pixelFormat*: GopPixelFormat
    pixelInfo*: GopPixelBitmask
    pixelsPerScanLine*: uint32

  GopQueryMode* = proc (this: ptr EfiGraphicsOutputProtocol, modeNumber: uint32, sizeOfInfo: ptr uint, info: ptr ptr GopModeInfo): EfiStatus {.cdecl.}
  GopSetMode* = proc (this: ptr EfiGraphicsOutputProtocol, modeNumber: uint32): EfiStatus {.cdecl.}
