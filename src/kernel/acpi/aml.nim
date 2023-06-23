#[
  ACPI AML Parser
]#
import std/options
import std/sequtils
import std/strformat
import std/strutils
import std/sugar
import std/tables

import ../debug
import ../devices/console

var storeCount = 0

type
  Char = enum
    chNull         = 0x00
    chAsciiStart   = 0x01
    chDigitStart   = 0x30  # ('0'-   )
    chDigitEnd     = 0x39  # (   -'9')
    chAlphaStart   = 0x41  # ('A'-   )
    chAlphaEnd     = 0x5A  # (   -'Z')
    chRoot         = 0x5C  # '\'
    chParentPrefix = 0x5E # '^'
    chUnderscore   = 0x5F   # '_'
    chAsciiEnd     = 0x7F
  
  Prefix = enum
    pfByte      = 0x0A
    pfWord      = 0x0B
    pfDWord     = 0x0C
    pfString    = 0x0D
    pfQWord     = 0x0E
    pfDualName  = 0x2E
    pfMultiName = 0x2F
    pfExtOp     = 0x5B

  OpCodeByte = enum
    ocbZeroOp             = 0x00
    ocbOneOp              = 0x01
    ocbNameOp             = 0x08
    ocbScopeOp            = 0x10
    ocbBufferOp           = 0x11
    ocbPackageOp          = 0x12
    ocbMethodOp           = 0x14
    ocbLocal0Op           = 0x60
    ocbLocal1Op           = 0x61
    ocbLocal2Op           = 0x62
    ocbLocal3Op           = 0x63
    ocbLocal4Op           = 0x64
    ocbLocal5Op           = 0x65
    ocbLocal6Op           = 0x66
    ocbLocal7Op           = 0x67
    ocbArg0Op             = 0x68
    ocbArg1Op             = 0x69
    ocbArg2Op             = 0x6A
    ocbArg3Op             = 0x6B
    ocbArg4Op             = 0x6C
    ocbArg5Op             = 0x6D
    ocbArg6Op             = 0x6E
    ocbStoreOp            = 0x70
    ocbSubtractOp         = 0x74
    ocbIncrementOp        = 0x75
    ocbShiftLeftOp        = 0x79
    ocbAndOp              = 0x7B
    ocbOrOp               = 0x7D
    ocbDerefOfOp          = 0x83
    ocbSizeOfOp           = 0x87
    ocbIndexOp            = 0x88
    ocbCreateDWordFieldOp = 0x8A
    ocbLOrOp              = 0x91
    ocbLNotOp             = 0x92
    ocbLEqualOp           = 0x93
    ocbLLessOp            = 0x95
    ocbToBufferOp         = 0x96
    ocbToHexStringOp      = 0x98
    ocbIfOp               = 0xA0
    ocbElseOp             = 0xA1
    ocbWhileOp            = 0xA2
    ocbReturnOp           = 0xA4
    ocbOnesOp             = 0xFF

  OpCodeWord = enum
    ocwMutexOp            = 0x01_5B
    # ocwEventOp            = 0x02_5B
    # ocwCondRefOfOp        = 0x12_5B
    # ocwCreateFieldOp      = 0x13_5B
    # ocwLoadTableOp        = 0x1F_5B
    # ocwLoadOp             = 0x20_5B
    # ocwStallOp            = 0x21_5B
    # ocwSleepOp            = 0x22_5B
    ocwAcquireOp          = 0x23_5B
    # ocwSignalOp           = 0x24_5B
    # ocwWaitOp             = 0x25_5B
    # ocwResetOp            = 0x26_5B
    ocwReleaseOp          = 0x27_5B
    # ocwFromBCDOp          = 0x28_5B
    # ocwToBCD              = 0x29_5B
    # ocwReserved           = 0x2A_5B
    # ocwRevisionOp         = 0x30_5B
    # ocwDebugOp            = 0x31_5B
    # ocwFatalOp            = 0x32_5B
    # ocwTimerOp            = 0x33_5B
    ocwOpRegionOp         = 0x80_5B
    ocwFieldOp            = 0x81_5B
    ocwDeviceOp           = 0x82_5B
    # ocwProcessorOp        = 0x83_5B // deprecated in 6.4
    # ocwPowerResOp         = 0x84_5B
    # ocwThermalZoneOp      = 0x85_5B
    # ocwIndexFieldOp       = 0x86_5B
    # ocwBankFieldOp        = 0x87_5B
    # ocwDataRegionOp       = 0x88_5B
    # ocwLNotEqualOp        = 0x93_92
    # ocwLLessEqualOp       = 0x94_92
    # ocwLGreaterEqualOp    = 0x95_92

  TermList = seq[TermObj]

  TermObjKind = enum
    toObject
    toStatement
    toExpression
  TermObj = ref object
    case kind: TermObjKind
    of toObject:     obj: Obj
    of toStatement:  stmt: StatementOpcode
    of toExpression: expr: ExpressionOpcode

  ObjKind = enum
    okNsModObj
    okNamedObj
  Obj = ref object
    case kind: ObjKind
    of okNsModObj: nsModObj: NamespaceModifierObj
    of okNamedObj: namedObj: NamedObj

  NsModObjKind = enum
    nmoDefName
    nmoDefScope
  NamespaceModifierObj = ref object
    case kind: NsModObjKind
    of nmoDefName:  defName: DefName
    of nmoDefScope: defScope: DefScope

  DefName = ref object
    name: NameString
    obj: DataObject
  
  DataRefObjKind = enum
    droDataObject
    droObjectRef
  DataRefObj = ref object
    case kind: DataRefObjKind
    of droDataObject: obj: DataObject
    of droObjectRef:  objRef: TermArg

  DefScope = ref object
    name: NameString
    terms: TermList

  NamedObjKind = enum
    # noDefBankField
    # noDefCreateBitField
    # noDefCreateByteField
    noDefCreateDWordField
    # noDefCreateField
    # noDefCreateQWordField
    # noDefCreateWordField
    # noDefDataRegion
    noDefDevice
    # noDefEvent
    noDefField
    # noDefFunction
    # noDefIndexField
    noDefMethod
    noDefMutex
    noDefOpRegion
    # noDefPowerRes
    # noDefProcessor # deprecated in 6.4
    # noDefThermalZone
  NamedObj = ref object
    case kind: NamedObjKind
    # of noDefBankField:        defBankField: DefBankField
    # of noDefCreateBitField:   defCreateBitField: DefCreateBitField
    # of noDefCreateByteField:  defCreateByteField: DefCreateByteField
    of noDefCreateDWordField: defCreateDWordField: DefCreateDWordField
    # of noDefCreateField:      defCreateField: DefCreateField
    # of noDefCreateQWordField: defCreateQWordField: DefCreateQWordField
    # of noDefCreateWordField:  defCreateWordField: DefCreateWordField
    # of noDefDataRegion:       defDataRegion: DefDataRegion
    of noDefDevice:           defDevice: DefDevice
    # of noDefEvent:            defEvent: DefEvent
    of noDefField:            defField: DefField
    # of noDefFunction:         defFunction: DefFunction
    # of noDefIndexField:       defIndexField: DefIndexField
    of noDefMethod:           defMethod: DefMethod
    of noDefMutex:            defMutex: DefMutex
    of noDefOpRegion:         defOpRegion: DefOpRegion
    # of noDefPowerRes:         defPowerRes: DefPowerRes
    # of noDefProcessor:        defProcessor: DefProcessor
    # of noDefThermalZone:      defThermalZone: DefThermalZone

  DefCreateDWordField = ref object
    srcBuffer: TermArg
    byteIndex: TermArg
    name: NameString

  DefDevice = ref object
    name: NameString
    body: TermList

  DefField = ref object
    regionName: NameString
    flags: FieldFlags
    elements: seq[FieldElement]
  FieldFlags {.packed.} = object
    accessType {.bitsize: 4}: FieldAccessType
    lockRule   {.bitsize: 1}: FieldLockRule
    updateRule {.bitsize: 2}: FieldUpdateRule
    reserved   {.bitsize: 1}: bool
  FieldAccessType = enum
    fatAnyAcc    = (0, "AnyAcc")
    fatByteAcc   = (1, "ByteAcc")
    fatWordAcc   = (2, "WordAcc")
    fatDWordAcc  = (3, "DWordAcc")
    fatQWordAcc  = (4, "QWordAcc")
    fatBufferAcc = (5, "BufferAcc")
  FieldLockRule = enum
    flrNoLock = (0, "NoLock")
    flrLock   = (1, "Lock")
  FieldUpdateRule = enum
    furPreserve     = (0, "Preserve")
    furWriteAsOnes  = (1, "WriteAsOnes")
    furWriteAsZeros = (2, "WriteAsZeros")
  FieldElementKind = enum
    feNamedField
    feReservedField
    # feAccessField
    # feExtendedAccessField
    # feConnectField
  FieldElement = ref object
    case kind: FieldElementKind
    of feNamedField: namedField: NamedField
    of feReservedField: reservedField: ReservedField
    # of feAccessField: accessField: AccessField
    # of feExtendedAccessField: extendedAccessField: ExtendedAccessField
    # of feConnectField: connectField: ConnectField
  NamedField = object
    name: string
    bits: uint32
  ReservedField = object
    bits: uint32
  
  DefMethod = ref object
    name: NameString
    flags: MethodFlags
    terms: TermList
  MethodFlags {.packed.} = object
    argCount   {.bitsize: 3}: uint8
    serialized {.bitsize: 1}: bool
    syncLevel  {.bitsize: 4}: uint8

  DefMutex = ref object
    name: NameString
    syncLevel: uint8

  DefOpRegion = ref object
    name: NameString
    space: RegionSpace
    offset: TermArg
    len: TermArg
  RegionSpace = enum
    rsSystemMemory     = (0x00, "SystemMemory")
    rsSystemIO         = (0x01, "SystemIO")
    rsPciConfig        = (0x02, "PCI_Config")
    rsEmbeddedControl  = (0x03, "EmbeddedControl")
    rsSMBus            = (0x04, "SMBus")
    rsSystemCMOS       = (0x05, "SystemCMOS")
    rsPciBarTarget     = (0x06, "PciBarTarget")
    rsIPMI             = (0x07, "IPMI")
    rsGeneralPurposeIO = (0x08, "GeneralPurposeIO")
    rsGenericSerialBus = (0x09, "GenericSerialBus")
    rsPCC              = (0x0A, "PCC")

  TermArgKind = enum
    taExpr
    taDataObject
    taArgObj
    taLocalObj
    taName
  TermArg = ref object
    case kind: TermArgKind
    of taExpr:       expr: ExpressionOpcode
    of taDataObject: dataObj: DataObject
    of taArgObj:     argObj: ArgObj
    of taLocalObj:   localObj: LocalObj
    of taName:       name: NameString
  
  SimpleNameKind = enum
    snName
    snArg
    snLocal
  SimpleName = ref object
    case kind: SimpleNameKind
    of snName:  name: NameString
    of snArg:   arg: ArgObj
    of snLocal: local: LocalObj

  SuperNameKind = enum
    snSimpleName
    # snDebugObj
    snRefTypeOpcode
  SuperName = ref object
    case kind: SuperNameKind
    of snSimpleName:    simpleName: SimpleName
    # of snDebugObj:    debugObj: DebugObj
    of snRefTypeOpcode: refTypeOpcode: RefTypeOpcode

  NameString = string

  DataObjectKind = enum
    doComputationalData
    doDefPackage
    # doDefVarPackage
  DataObject = ref object
    case kind: DataObjectKind
    of doComputationalData: compData: ComputationalData
    of doDefPackage:        defPackage: DefPackage
    # of doDefVarPackage:     defVarPackage: DefVarPackage

  ComputationalDataKind = enum
    cdByteConst
    cdWordConst
    cdDWordConst
    # cdQWordConst
    cdString
    cdConstObj
    # cdRevisionOp
    cdDefBuffer
  ConstObj = enum
    coZero = 0x00
    coOne  = 0x01
    coOnes = 0xFF
  ComputationalData = ref object
    case kind: ComputationalDataKind
    of cdByteConst:   byteConst: uint8
    of cdWordConst:   wordConst: uint16
    of cdDWordConst:  dwordConst: uint32
    # of cdQWordConst:  qwordConst: uint64
    of cdString:      str: string
    of cdConstObj:    constObj: ConstObj
    # of cdRevisionOp:  revisionOp: uint64
    of cdDefBuffer:   defBuffer: DefBuffer

  ArgObj = enum
    aoArg0 = ocbArg0Op
    aoArg1 = ocbArg1Op
    aoArg2 = ocbArg2Op
    aoArg3 = ocbArg3Op
    aoArg4 = ocbArg4Op
    aoArg5 = ocbArg5Op
    aoArg6 = ocbArg6Op

  LocalObj = enum
    loLocal0 = ocbLocal0Op
    loLocal1 = ocbLocal1Op
    loLocal2 = ocbLocal2Op
    loLocal3 = ocbLocal3Op
    loLocal4 = ocbLocal4Op
    loLocal5 = ocbLocal5Op
    loLocal6 = ocbLocal6Op
    loLocal7 = ocbLocal7Op

  ExpressionOpcodeKind = enum
    expBuffer
    expToHexString
    expToBuffer
    expSubtract
    expSizeOf
    expStore
    expLEqual
    expLLess
    expIndex
    expDerefOf
    expIncrement
    expAnd
    expLNot
    expLOr
    expOr
    expAcquire
    expShiftLeft
    expMethodInvocation
    expPackage
  ExpressionOpcode = ref object
    case kind: ExpressionOpcodeKind
    of expAcquire: defAcquire: DefAcquire
    # add: Add
    of expAnd: defAnd: DefAnd
    of expBuffer: defBuffer: DefBuffer
    # DefConcat
    # DefConcatRes
    # DefCondRefOf
    # DefCopyObject
    # DefDecrement
    of expDerefOf: defDerefOf: DefDerefOf
    # DefDivide
    # DefFindSetLeftBit
    # DefFindSetRightBit
    # DefFromBCD
    of expIncrement: defIncrement: DefIncrement
    of expIndex: defIndex: DefIndex
    # land: LAnd
    of expLEqual: defLEqual: DefLEqual
    # lgreater: LGreater
    # DefLGreaterEqual
    of expLLess: defLLess: DefLLess
    # DefLLessEqual
    # DefMid
    of expLNot: defLNot: DefLNot
    # DefLNotEqual
    # DefLoadTable
    of expLOr: defLOr: DefLOr
    # DefMatch
    # DefMod
    # DefMultiply
    # DefNAnd
    # DefNOr
    # DefNot
    # DefObjectType
    of expOr: defOr: DefOr
    of expPackage: defPackage: DefPackage
    # var_package: VarPackage
    # ref_of: RefOf
    of expShiftLeft: defShiftLeft: DefShiftLeft
    # shift_right: ShiftRight
    of expSizeOf: defSizeOf: DefSizeOf
    of expStore: defStore: DefStore
    of expSubtract: defSubtract: DefSubtract
    # DefTimer
    # DefToBCD
    of expToBuffer: defToBuffer: DefToBuffer
    # DefToDecimalString
    of expToHexString: defToHexString: DefToHexString
    # DefToInteger
    # DefToString
    # DefWait
    # DefXOr
    of expMethodInvocation: call: MethodInvocation

  RefTypeOpcodeKind = enum
    # rtoRefOf
    # rtoDerefOf
    rtoIndex
  RefTypeOpcode = ref object
    case kind: RefTypeOpcodeKind
    # of rtoRefOf:   defRefOf: DefRefOf
    # of rtoDerefOf: defDerefOf: DerefOf
    of rtoIndex:   defIndex: DefIndex

  DefAcquire = ref object
    mutex: SuperName
    timeout: uint16

  DefAnd = ref object
    operand1: Operand
    operand2: Operand
    target: Target

  BufferPayloadKind = enum
    bpResourceDesc
    bpBytes
  DefBuffer = ref object
    size: TermArg
    case kind: BufferPayloadKind
    of bpBytes: bytes: seq[byte]
    of bpResourceDesc: resourceDesc: ResourceDescriptor

  DefToHexString = ref object
    operand: Operand
    target: Target

  DefToBuffer = ref object
    operand: Operand
    target: Target

  DefSubtract = ref object
    operand1: Operand
    operand2: Operand
    target: Target
  
  DefSizeOf = ref object
    name: SuperName
  
  DefStore = ref object
    src: TermArg
    dst: SuperName

  DefLEqual = ref object
    operand1: Operand
    operand2: Operand

  DefLLess = ref object
    operand1: Operand
    operand2: Operand
  
  DefLNot = ref object
    operand: Operand

  DefLOr = ref object
    operand1: Operand
    operand2: Operand

  DefOr = ref object
    operand1: Operand
    operand2: Operand
    target: Target

  DefPackage = ref object
    elements: seq[PackageElement]
  PackageElementKind = enum
    peDataObj
    peNameString
  PackageElement = ref object
    case kind: PackageElementKind
    of peDataObj: dataObj: DataObject
    of peNameString: name: NameString

  DefIndex = ref object
    src: TermArg
    idx: TermArg
    dst: Target
  
  DefDerefOf = ref object
    src: TermArg
  
  DefIncrement = ref object
    addend: SuperName
  
  DefShiftLeft = ref object
    operand: Operand
    count: TermArg
    target: Target

  MethodInvocation = ref object
    name: NameString
    args: seq[TermArg]

  StatementOpcodeKind = enum
    stmtIfElse
    stmtWhile
    stmtRelease
    stmtReturn
  StatementOpcode = ref object
    case kind: StatementOpcodeKind
    # break_: *Break,
    # // break_point: *BreakPoint,
    # // continue_: *Continue,
    # // fatal: *Fatal,
    of stmtIfElse: defIfElse: DefIfElse
    # // noop: *Noop,
    # notify: *Notify,
    of stmtRelease: defRelease: DefRelease
    # // reset: *Reset,
    of stmtReturn: defReturn: DefReturn
    # // signal: *Signal,
    # // sleep: *Sleep,
    # // stall: *Stall,
    of stmtWhile: defWhile: DefWhile

  DefIfElse = ref object
    predicate: TermArg
    ifBody: TermList
    elseBody: Option[TermList]

  DefRelease = ref object
    mutex: SuperName

  DefReturn = ref object
    arg: TermArg

  DefWhile = ref object
    predicate: TermArg
    body: TermList

  Operand = TermArg

  TargetKind = enum
    tgSuperName
    tgNullName
  Target = ref object
    case kind: TargetKind
    of tgSuperName: superName: SuperName
    of tgNullName: discard

  AddressSpaceResourceType = enum
    resMemoryRange    = (0, "MemoryRange")
    resIORange        = (1, "IORange")
    resBusNumberRange = (2, "BusNumberRange")
  DecodeType = enum
    decSubDecode = (0, "PosDecode")
    decPosDecode = (1, "SubDecode")
  IsMinFixed = enum
    minNotFixed = (0, "MinNotFixed")
    minFixed    = (1, "MinFixed")
  IsMaxFixed = enum
    maxNotFixed = (0, "MaxNotFixed")
    maxFixed    = (1, "MaxFixed")
  AddressSpaceFlags {.packed.} = object
    ignored    {.bitsize: 1}: bool
    decodeType {.bitsize: 1}: DecodeType
    minFixed   {.bitsize: 1}: IsMinFixed
    maxFixed   {.bitsize: 1}: IsMaxFixed
    reserved   {.bitsize: 4}: uint8
  MemoryWriteStatus = enum
    mwsReadOnly  = (0, "ReadOnly")
    mwsReadWrite = (1, "ReadWrite")
  MemoryResourceAttributes = enum
    mattrNonCacheable   = (0, "NonCacheable")
    mattrCacheable      = (1, "Cacheable")
    mattrWriteCombining = (2, "WriteCombining")
    mattrPrefetchable   = (3, "Prefetchable")
  MemoryResourceType = enum
    mtypAddressRangeMemory   = (0, "AddressRangeMemory")
    mtypAddressRangeReserved = (1, "AddressRangeReserved")
    mtypAddressRangeACPI     = (2, "AddressRangeACPI")
    mtypAddressRangeNVS      = (3, "AddressRangeNVS")
  MemoryToIOTranslation = enum
    mioTranslation = (0, "TypeTranslation")
    mioStatic      = (1, "TypeStatic")
  MemorySpecificFlags {.packed.} = object
    readWrite  {.bitsize: 1}: MemoryWriteStatus
    memAttrs   {.bitsize: 2}: MemoryResourceAttributes
    memType    {.bitsize: 2}: MemoryResourceType
    memIOTrans {.bitsize: 1}: MemoryToIOTranslation
    reserved   {.bitsize: 2}: int
  DWordAddrSpaceDesc {.packed.} = ref object
    resType        : AddressSpaceResourceType
    addrSpaceFlags : AddressSpaceFlags
    memFlags       : MemorySpecificFlags
    granularity:                  uint32
    minAddr:                      uint32
    maxAddr:                      uint32
    translationOffset:            uint32
    addressLength:                uint32
    # resourceSourceIndex:        uint8
    # resourceSource:             string

  ResourceUsage = enum
    ruProducer = (0, "Producer")
    ruConsumer = (1, "Consumer")

  InterruptMode = enum
    imLevelTriggered = (0, "LevelTriggered")
    imEdgeTriggered  = (1, "EdgeTriggered")
  InterruptPolarity = enum
    ipActiveHigh = (0, "ActiveHigh")
    ipActiveLow  = (1, "ActiveLow")
  InterruptSharing = enum
    isShared    = (0, "Shared")
    isExclusive = (1, "Exclusive")
  InterruptWakeCap = enum
    iwNotWakeCapable = (0, "NotWakeCapable")
    iwWakeCapable    = (1, "WakeCapable")
  ExtendedInterruptFlags {.packed.} = object
    resUsage {.bitsize: 1}: ResourceUsage
    mode     {.bitsize: 1}: InterruptMode
    polarity {.bitsize: 1}: InterruptPolarity
    sharing  {.bitsize: 1}: InterruptSharing
    wakeCap  {.bitsize: 1}: InterruptWakeCap
    reserved {.bitsize: 3}: uint8
  ExtendedInterruptDesc {.packed.} = ref object
    flags: ExtendedInterruptFlags
    intNums: seq[uint32]

  ResourceDescriptorKind = enum
    rdReserved          = 0x00
    # rdGenericRegister   = 0x82
    rdDWordAddressSpace = 0x87
    # rdWordAddressSpace  = 0x88
    rdExtendedInterrupt = 0x89
    # rdQWordAddressSpace = 0x8A
    # rdGpioConnection    = 0x8B
  ResourceDescriptor = ref object
    case kind: ResourceDescriptorKind
    of rdReserved: discard
    of rdDWordAddressSpace: dwordAddrSpace: DWordAddrSpaceDesc
    of rdExtendedInterrupt: extInterrupt: ExtendedInterruptDesc


# proc dumpHex*(bytes: openArray[uint8]) =
#   for i in 0 ..< bytes.len:
#     if i mod 16 == 0:
#       writeln("")
#     write(&"{bytes[i]:0>2x} ")

type
  Parser* = object
    ctx: ParseContext
    ctxStack: seq[ParseContext]
    indent: int
    methods: Table[string, DefMethod]

  ParseContext = object
    chunk: ptr UncheckedArray[byte]
    len: int
    loc: int

proc enterContext(p: var Parser, len: uint32) =
  p.ctxStack.add(p.ctx)
  let chunk = cast[ptr UncheckedArray[byte]](addr p.ctx.chunk[p.ctx.loc])
  p.ctx = ParseContext(chunk: chunk, len: len.int, loc: 0)

proc exitContext(p: var Parser) =
  let oldCtx = p.ctx
  p.ctx = p.ctxStack.pop
  inc p.ctx.loc, oldCtx.len

proc rewindContext(p: var Parser) =
  p.ctx = p.ctxStack.pop

template withContext(p: var Parser, len: uint32, body: untyped) =
  p.enterContext(len)
  body
  p.exitContext()


# forward declarations ({.experimental: "codeReordering".} doesn't work with circular deps)
proc termList(p: var Parser): TermList
proc termObj(p: var Parser): Option[TermObj]
proc obj(p: var Parser): Option[Obj]

proc namespaceModifierObj(p: var Parser): Option[NamespaceModifierObj]
proc defName(p: var Parser): Option[DefName]

proc namedObj(p: var Parser): Option[NamedObj]
proc defCreateDWordField(p: var Parser): Option[DefCreateDWordField]
proc defField(p: var Parser): Option[DefField]
proc defDevice(p: var Parser): Option[DefDevice]
proc defMutex(p: var Parser): Option[DefMutex]
proc defOpRegion(p: var Parser): Option[DefOpRegion]
proc fieldList(p: var Parser): seq[FieldElement]
proc namedField(p: var Parser): Option[NamedField]
proc reservedField(p: var Parser): Option[ReservedField]
proc defMethod(p: var Parser): Option[DefMethod]
proc defScope*(p: var Parser): Option[DefScope]
proc pkgLength(p: var Parser): Option[(uint8, uint32)]
# proc pkgPayload(p: var Parser): Option[(ptr UncheckedArray[byte], int)]
proc nameString(p: var Parser): Option[NameString]
proc prefixPath(p: var Parser): Option[string]
proc namePath(p: var Parser): Option[string]
proc nameSeg(p: var Parser): Option[string]
proc dualNamePath(p: var Parser): Option[string]
proc multiNamePath(p: var Parser): Option[string]
proc leadNameChar(p: var Parser): Option[char]
proc nameChar(p: var Parser): Option[char]

proc termArg(p: var Parser): Option[TermArg]
proc simpleName(p: var Parser): Option[SimpleName]
proc superName(p: var Parser): Option[SuperName]
proc dataObject(p: var Parser): Option[DataObject]

proc computationalData(p: var Parser): Option[ComputationalData]
proc byteConst(p: var Parser): Option[uint8]
proc wordConst(p: var Parser): Option[uint16]
proc dwordConst(p: var Parser): Option[uint32]
proc constObj(p: var Parser): Option[ConstObj]
proc str(p: var Parser): Option[string]

proc argObj(p: var Parser): Option[ArgObj]
proc localObj(p: var Parser): Option[LocalObj]

proc expressionOpcode(p: var Parser): Option[ExpressionOpcode]
proc refTypeOpcode(p: var Parser): Option[RefTypeOpcode]
proc defAcquire(p: var Parser): Option[DefAcquire]
proc defAnd(p: var Parser): Option[DefAnd]
proc defBuffer(p: var Parser): Option[DefBuffer]
proc defToHexString(p: var Parser): Option[DefToHexString]
proc defToBuffer(p: var Parser): Option[DefToBuffer]
proc defSubtract(p: var Parser): Option[DefSubtract]
proc defSizeOf(p: var Parser): Option[DefSizeOf]
proc defStore(p: var Parser): Option[DefStore]
proc defLEqual(p: var Parser): Option[DefLEqual]
proc defLLess(p: var Parser): Option[DefLLess]
proc defLNot(p: var Parser): Option[DefLNot]
proc defLOr(p: var Parser): Option[DefLOr]
proc defOr(p: var Parser): Option[DefOr]
proc defPackage(p: var Parser): Option[DefPackage]
proc defIndex(p: var Parser): Option[DefIndex]
proc defDerefOf(p: var Parser): Option[DefDerefOf]
proc defIncrement(p: var Parser): Option[DefIncrement]
proc defShiftLeft(p: var Parser): Option[DefShiftLeft]
proc methodInvocation(p: var Parser): Option[MethodInvocation]

proc resourceDesc(p: var Parser): Option[ResourceDescriptor]
proc dwordAddrSpaceDesc(p: var Parser): Option[DWordAddrSpaceDesc]
proc extendedInterruptDesc(p: var Parser): Option[ExtendedInterruptDesc]

proc statementOpcode(p: var Parser): Option[StatementOpcode]
proc defIfElse(p: var Parser): Option[DefIfElse]
proc defRelease(p: var Parser): Option[DefRelease]
proc defReturn(p: var Parser): Option[DefReturn]
proc defWhile(p: var Parser): Option[DefWhile]

proc operand(p: var Parser): Option[Operand]
proc target(p: var Parser): Option[Target]

proc chr(p: var Parser, ch: Char): Option[char]
proc byt(p: var Parser, `byte`: byte): Option[byte]
proc charRange(p: var Parser, start: Char, `end`: Char): Option[char]
proc byteRange(p: var Parser, start: byte, `end`: byte): Option[byte]

proc matchOpCodeByte(p: var Parser, opCode: OpCodeByte): bool
proc matchOpCodeWord(p: var Parser, opCode: OpCodeWord): bool
proc matchPrefix(p: var Parser, prefix: Prefix): bool
proc matchChar(p: var Parser, ch: Char): bool
proc matchByte(p: var Parser, `byte`: byte): bool

proc peekByte(p: var Parser): Option[byte] {.inline.}
proc peekWord(p: var Parser): Option[uint16] {.inline.}

proc readByte(p: var Parser): Option[byte] {.inline.}
proc readWord(p: var Parser): Option[uint16] {.inline.}
proc readDWord(p: var Parser): Option[uint32] {.inline.}
proc readBuffer(p: var Parser, len: int): Option[seq[byte]] {.inline.}
proc readBuffer(p: var Parser): Option[seq[byte]] {.inline.}


proc parse*(p: var Parser, aml: ptr UncheckedArray[byte], len: int): TermList =
  # dumpHex(aml.toOpenArray(0, 63))
  p.ctx = ParseContext(chunk: aml, len: len, loc: 0)
  result = p.termList()

proc termList(p: var Parser): TermList =
  # TermList := Nothing | <TermObj TermList>
  # debugln(&"TermList")
  
  var termObj = p.termObj()
  while termObj.isSome:
    result.add(termObj.get)
    termObj = p.termObj()

  # debugln(&"TermList: {result.len}")
  
proc termObj(p: var Parser): Option[TermObj] =
  # TermObj := Object | StatementOpcode | ExpressionOpcode
  # debugln(&"TermObj")
  let obj = p.obj()
  if obj.isSome:
    # debugln(&"TermObj: {obj.get.kind}")
    result = option TermObj(kind: toObject, obj: obj.get)
    return
  
  let stmt = p.statementOpcode()
  if stmt.isSome:
    # debugln(&"TermObj: {stmt.get.kind}")
    result = option TermObj(kind: toStatement, stmt: stmt.get)
    return

  let exprOpcode = p.expressionOpcode()
  if exprOpcode.isSome:
    # debugln(&"TermObj: {exprOpcode.get.kind}")
    result = option TermObj(kind: toExpression, expr: exprOpcode.get)
    return

proc obj(p: var Parser): Option[Obj] =
  # Object := NameSpaceModifierObj | NamedObj
  # debugln(&"Object")
  result = p.namespaceModifierObj().map(nmo => Obj(kind: okNsModObj, nsModObj: nmo))
  if result.isSome:
    return

  result = p.namedObj().map(no => Obj(kind: okNamedObj, namedObj: no))
  

proc namespaceModifierObj(p: var Parser): Option[NamespaceModifierObj] =
  # NameSpaceModifierObj := DefAlias | DefName | DefScope
  # debugln(&"NamespaceModifierObj")
  result = p.defName().map(dn => NamespaceModifierObj(kind: nmoDefName, defName: dn))
  if result.isSome:
    return

  result = p.defScope().map(ds => NamespaceModifierObj(kind: nmoDefScope, defScope: ds))
  if result.isSome:
    return

proc defName(p: var Parser): Option[DefName] =
  # AML spec is inconsistent with ASL spec
  # AML ==> DefName := NameOp NameString DataRefObject
  # ASL ==> NameTerm := Name (
  #                       ObjectName, // NameString
  #                       Object // DataObject
  #                     )
  # debugln(&"DefName")
  if p.matchOpCodeByte(ocbNameOp):
    let name = p.nameString()
    if name.isSome:
      let dataObj = p.dataObject()
      if dataObj.isSome:
        result = option DefName(name: name.get, obj: dataObj.get)

proc namedObj(p: var Parser): Option[NamedObj] =
  # NamedObj := DefBankField | DefCreateBitField | DefCreateByteField | DefCreateDWordField
  #           | DefCreateField | DefCreateQWordField | DefCreateWordField | DefDataRegion
  #           | DefDevice | DefEvent | DefField | DefFunction | DefIndexField | DefMethod | DefMutex
  #           | DefOpRegion | DefPowerRes | DefProcessor | DefThermalZone
  # debugln(&"NamedObj")
  result = p.defCreateDWordField().map(dcd => NamedObj(kind: noDefCreateDWordField, defCreateDWordField: dcd))
  if result.isSome:
    return

  result = p.defDevice().map(dd => NamedObj(kind: noDefDevice, defDevice: dd))
  if result.isSome:
    return

  result = p.defMutex().map(dm => NamedObj(kind: noDefMutex, defMutex: dm))
  if result.isSome:
    return

  result = p.defOpRegion().map(dor => NamedObj(kind: noDefOpRegion, defOpRegion: dor))
  if result.isSome:
    return

  result = p.defField().map(df => NamedObj(kind: noDefField, defField: df))
  if result.isSome:
    return

  result = p.defMethod().map(dm => NamedObj(kind: noDefMethod, defMethod: dm))
  if result.isSome:
    return

proc defCreateDWordField(p: var Parser): Option[DefCreateDWordField] =
  # DefCreateDWordField := CreateDWordFieldOp SourceBuff ByteIndex NameString
  # debugln(&"DefCreateDWordField")
  if p.matchOpCodeByte(ocbCreateDWordFieldOp):
    let srcBuffer = p.termArg()
    if srcBuffer.isSome:
      let byteIndex = p.termArg()
      if byteIndex.isSome:
        let name = p.nameString()
        if name.isSome:
          result = option DefCreateDWordField(srcBuffer: srcBuffer.get, byteIndex: byteIndex.get, name: name.get)

proc defDevice(p: var Parser): Option[DefDevice] =
  # DefDevice := DeviceOp PkgLength NameString TermList
  # debugln(&"DefDevice")
  if p.matchOpCodeWord(ocwDeviceOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let name = p.nameString()
        if name.isSome:
          let termList = p.termList()
          result = option DefDevice(name: name.get, body: termList)

proc defMutex(p: var Parser): Option[DefMutex] =
  # DefMutex := MutexOp NameString SyncFlags
  # debugln(&"DefMutex")
  if p.matchOpCodeWord(ocwMutexOp):
    let name = p.nameString()
    if name.isSome:
      let syncFlags = p.readByte()
      if syncFlags.isSome:
        let syncLevel = syncFlags.get and 0x0F
        result = option DefMutex(name: name.get, syncLevel: syncLevel)

proc defOpRegion(p: var Parser): Option[DefOpRegion] =
  # DefOpRegion := OpRegionOp NameString RegionSpace RegionOffset RegionLen
  #   RegionOffset := TermArg => Integer
  #   RegionLen := TermArg => Integer
  # debugln(&"DefOpRegion")
  if p.matchOpCodeWord(ocwOpRegionOp):
    let nameStr = p.nameString()
    if nameStr.isSome:
      let regionSpace = p.readByte()
      if regionSpace.isSome:
        let regionOffset = p.termArg()
        if regionOffset.isSome:
          let regionLen = p.termArg()
          if regionLen.isSome:
            result = option DefOpRegion(
              name: nameStr.get,
              space: RegionSpace(regionSpace.get),
              offset: regionOffset.get,
              len: regionLen.get
            )

proc defField(p: var Parser): Option[DefField] =
  # DefField := FieldOp PkgLength NameString FieldFlags FieldList
  # debugln(&"DefField")
  if p.matchOpCodeWord(ocwFieldOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let regionName = p.nameString()
        if regionName.isSome:
          let flags = p.readByte()
          if flags.isSome:
            let elements = p.fieldList()
            result = option DefField(
              regionName: regionName.get,
              flags: cast[FieldFlags](flags.get),
              elements: elements
            )

proc fieldList(p: var Parser): seq[FieldElement] =
  # FieldList := Nothing | <FieldElement FieldList>
  # debugln(&"FieldList")
  while true:
    let namedField = p.namedField()
    if namedField.isSome:
      result.add(FieldElement(kind: feNamedField, namedField: namedField.get))
      continue

    let reservedField = p.reservedField()
    if reservedField.isSome:
      result.add(FieldElement(kind: feReservedField, reservedField: reservedField.get))
      continue

    break

proc namedField(p: var Parser): Option[NamedField] =
  # debugln(&"NamedField")
  let name = p.nameSeg()
  if name.isSome:
    let pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (_, bits) = pkgResult.get
      result = option NamedField(name: name.get, bits: bits)

proc reservedField(p: var Parser): Option[ReservedField] =
  # debugln(&"ReservedField")
  if p.matchByte(0x00):
    let pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (_, bits) = pkgResult.get
      result = option ReservedField(bits: bits)

proc defMethod(p: var Parser): Option[DefMethod] =
  # DefMethod := MethodOp PkgLength NameString MethodFlags TermList
  # debugln(&"DefMethod")
  if p.matchOpCodeByte(ocbMethodOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let name = p.nameString()
        if name.isSome:
          let flags = p.readByte()
          if flags.isSome:
            let terms = p.termList()
            result = option DefMethod(
              name: name.get,
              flags: cast[MethodFlags](flags.get),
              terms: terms
            )
            # add the method to a table so that we can use it to resolve method invocations
            p.methods[name.get] = result.get

proc defScope*(p: var Parser): Option[DefScope] =
  # DefScope := ScopeOp PkgLength NameString TermList
  # debugln(&"DefScope")
  if p.matchOpCodeByte(ocbScopeOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let name = p.nameString()
        if name.isSome:
          let terms = p.termList()
          # debugln(&"Scope ({name.get}), terms: {terms.len}")
          result = option DefScope(name: name.get, terms: terms)

proc pkgLength(p: var Parser): Option[(uint8, uint32)] =
  # PkgLeadByte |
  # <PkgLeadByte ByteData> |
  # <PkgLeadByte ByteData ByteData> |
  # <PkgLeadByte ByteData ByteData ByteData>
  # debugln(&"PkgLength")
  # debugln(&"{p.ctx.loc=}, {p.ctx.len=}")
  let leadByte = p.readByte()
  if leadByte.isSome:
    let leadByte = leadByte.get
    let byteCount = leadByte shr 6

    if byteCount == 0:
      # single-byte, length is in bits 5:0
      result = option (1.uint8, leadByte.uint32 and 0x3F)
      # debugln(&"PkgLength: {result.get}")
    elif byteCount > 3:
      # invalid
      result = none((uint8, uint32))
    elif (leadByte and 0b00110000) != 0:
      # invalid
      result = none((uint8, uint32))
    else:
      # multi-byte, bits 3:0 of the lead byte are the least significan bits of the length
      var len: uint32 = leadByte and 0x0F
      for i in 1.uint8 .. byteCount:
        let next = p.readByte()
        if next.isNone:
          return none((uint8, uint32))
        len = len or (next.get.uint32 shl (i * 8 - 4))
      result = option (byteCount + 1, len)
      # debugln(&"PkgLength: {len}")

proc nameString(p: var Parser): Option[NameString] =
  # NameString := <RrootChar NamePath> | <PrefixPath NamePath>
  # debugln(&"NameString")
  if p.matchChar(chRoot):
    result = p.namePath().map(np => NameString("\\" & np))
  else:
    let prefix = p.prefixPath().get("")
    result = p.namePath().map(np => NameString(prefix & np))

proc prefixPath(p: var Parser): Option[string] =
  # PrefixPath := Nothing | <'^' PrefixPath>
  # debugln(&"PrefixPath")
  var count = 0
  while p.matchChar(chParentPrefix):
    count += 1
  if count > 0:
    result = option "^".repeat(count)

proc namePath(p: var Parser): Option[string] =
  # NamePath := NameSeg | DualNamePath | MultiNamePath | NullName
  # debugln(&"NamePath")
  let nameSeg = p.nameSeg()
  if nameSeg.isSome:
    result = option nameSeg.get
  else:
    let dualNamePath = p.dualNamePath()
    if dualNamePath.isSome:
      result = option dualNamePath.get
    else:
      let multiNamePath = p.multiNamePath()
      if multiNamePath.isSome:
        result = option multiNamePath.get
      else:
        let nullName = p.chr(chNull)
        if nullName.isSome:
          result = option ""

proc nameSeg(p: var Parser): Option[string] =
  # NameSeg := <LeadNameChar NameChar NameChar NameChar>
  # debugln(&"NameSeg")
  var name = newStringOfCap(4)

  var ch = p.leadNameChar()
  if ch.isSome:
    name &= ch.get
    for i in 1 .. 3:
      ch = p.nameChar()
      if ch.isNone:
        break
      name &= ch.get

  if name.len == 4:
    result = option name.strip(leading = false, chars = {'_'})

proc dualNamePath(p: var Parser): Option[string] =
  # DualNamePath := DualNamePrefix NameSeg NameSeg
  # debugln(&"DualNamePath")
  if p.matchPrefix(pfDualName):
    let nameSeg1 = p.nameSeg()
    if nameSeg1.isSome:
      let nameSeg2 = p.nameSeg()
      if nameSeg2.isSome:
        result = option nameSeg1.get & "." & nameSeg2.get

proc multiNamePath(p: var Parser): Option[string] =
  # MultiNamePath := MultiNamePrefix SegCount NameSeg(SegCount)
  # debugln(&"MultiNamePath")
  var segs: seq[string]
  if p.matchPrefix(pfMultiName):
    let segCount = p.readByte()
    if segCount.isSome:
      let segCount = segCount.get
      for i in 0'u8 ..< segCount:
        let nameSeg = p.nameSeg()
        if nameSeg.isNone:
          break
        segs.add(nameSeg.get)
      if segs.len == segCount.int:
        result = option segs.join(".")

proc leadNameChar(p: var Parser): Option[char] =
  # LeadNameChar := 'A'-'Z' | '_'
  # debugln(&"LeadNameChar")
  result = p.charRange(chAlphaStart, chAlphaEnd)
  if result.isNone:
    result = p.chr(chUnderscore)

proc nameChar(p: var Parser): Option[char] =
  # NameChar := LeadNameChar | DigitChar
  # debugln(&"NameChar")
  result = p.leadNameChar()
  if result.isNone:
    result = p.charRange(chDigitStart, chDigitEnd)

### TermArg

proc termArg(p: var Parser): Option[TermArg] =
  # TermArg := ExpressionOpcode | DataObject | ArgObj | LocalObj | NameString

  # DataObject needs to come before ExpressionOpcode, because of an ambiguity between:
  #   DataObject -> ComputationalData -> ConstObj -> ZeroOp (0x00), and
  #   ExpressionOpcode -> MethodInvocation -> NameString -> NamePath -> NullName (0x00)
  # In this case we're giving precedence to DataObject, which is more common.

  result = p.dataObject().map(dobj => TermArg(kind: taDataObject, dataObj: dobj))
  if result.isSome:
    return
  
  result = p.expressionOpcode().map(exp => TermArg(kind: taExpr, expr: exp))
  if result.isSome:
    return

  result = p.argObj().map(aobj => TermArg(kind: taArgObj, argObj: aobj))
  if result.isSome:
    return

  result = p.localObj().map(lobj => TermArg(kind: taLocalObj, localObj: lobj))
  if result.isSome:
    return

  result = p.nameString().map(ns => TermArg(kind: taName, name: ns))
  if result.isSome:
    return

# SimpleName / SuperName

proc simpleName(p: var Parser): Option[SimpleName] =
  # SimpleName := NameString | ArgObj | LocalObj
  # debugln(&"SimpleName")
  result = p.nameString().map(ns => SimpleName(kind: snName, name: ns))
  if result.isSome:
    return

  result = p.argObj().map(aobj => SimpleName(kind: snArg, arg: aobj))
  if result.isSome:
    return

  result = p.localObj().map(lobj => SimpleName(kind: snLocal, local: lobj))

proc superName(p: var Parser): Option[SuperName] =
  # SuperName := SimpleName | DebugObj | ReferenceTypeOpcode
  # debugln(&"SuperName")
  result = p.simpleName().map(sn => SuperName(kind: snSimpleName, simpleName: sn))
  if result.isSome:
    return

  # result = p.debugObj().map(dobj => SuperName(kind: snDebugObj, debugObj: dobj))
  # if result.isSome:
  #   return

  result = p.refTypeOpcode().map(rto => SuperName(kind: snRefTypeOpcode, refTypeOpcode: rto))
  if result.isSome:
    return

proc refTypeOpcode(p: var Parser): Option[RefTypeOpcode] =
  # ReferenceTypeOpcode := DefRefOf | DefDerefOf | DefIndex | UserTermObj
  # debugln(&"RefTypeOpcode")
  # result = p.defRefOf().map(dro => RefTypeOpcode(kind: rtoDefRefOf, defRefOf: dro))
  # if result.isSome:
  #   return

  # result = p.defDerefOf().map(ddo => RefTypeOpcode(kind: rtoDefDerefOf, defDerefOf: ddo))
  # if result.isSome:
  #   return

  result = p.defIndex().map(di => RefTypeOpcode(kind: rtoIndex, defIndex: di))
  if result.isSome:
    return

  # result = p.userTermObj().map(uto => RefTypeOpcode(kind: rtoUserTermObj, userTermObj: uto))
  # if result.isSome:
  #   return

### DataObject

proc dataObject(p: var Parser): Option[DataObject] =
  # DataObject := ComputationalData | DefPackage | DefVarPackage
  # debugln(&"DataObject")
  result = p.computationalData().map(cd => DataObject(kind: doComputationalData, compData: cd))
  if result.isSome:
    return

  result = p.defPackage().map(dp => DataObject(kind: doDefPackage, defPackage: dp))
  if result.isSome:
    return

### ComputationalData

proc computationalData(p: var Parser): Option[ComputationalData] =
  # ComputationalData := ByteConst | WordConst | DWordConst | QWordConst | String | ConstObj | RevisionOp | DefBuffer
  # debugln(&"ComputationalData")
  result = p.byteConst().map(bc => ComputationalData(kind: cdByteConst, byteConst: bc))
  if result.isSome:
    return

  result = p.wordConst().map(wc => ComputationalData(kind: cdWordConst, wordConst: wc))
  if result.isSome:
    return

  result = p.dwordConst().map(dwc => ComputationalData(kind: cdDWordConst, dwordConst: dwc))
  if result.isSome:
    return

  # result = p.qwordConst().map(qwc => ComputationalData(kind: cdQWordConst, qwordConst: qwc))
  # if result.isSome:
  #   return

  result = p.str().map(s => ComputationalData(kind: cdString, str: s))
  if result.isSome:
    return

  result = p.constObj().map(co => ComputationalData(kind: cdConstObj, constObj: co))
  if result.isSome:
    return

  # revisionOp()

  result = p.defBuffer().map(dbuf => ComputationalData(kind: cdDefBuffer, defBuffer: dbuf))
  if result.isSome:
    return

proc byteConst(p: var Parser): Option[uint8] =
  # ByteConst := BytePrefix ByteData
  # debugln(&"ByteConst")
  if p.matchPrefix(pfByte):
    result = p.readByte()

proc wordConst(p: var Parser): Option[uint16] =
  # WordConst := WordPrefix WordData
  # debugln(&"WordConst")
  if p.matchPrefix(pfWord):
    result = p.readWord()

proc dwordConst(p: var Parser): Option[uint32] =
  # DWordConst := DWordPrefix DWordData
  # debugln(&"DWordConst")
  if p.matchPrefix(pfDWord):
    result = p.readDWord()

proc constObj(p: var Parser): Option[ConstObj] =
  # ConstObj := ZeroOp | OneOp | OnesOp
  #   ZeroOp := 0x00
  #   OneOp := 0x01
  #   OnesOp := 0xFF
  # debugln(&"ConstObj")
  if p.matchOpCodeByte(ocbZeroOp):
    result = option coZero
  elif p.matchOpCodeByte(ocbOneOp):
    result = option coOne
  elif p.matchOpCodeByte(ocbOnesOp):
    result = option coOnes

proc str(p: var Parser): Option[string] =
  # String := StringPrefix AsciiCharList NullChar
  # debugln(&"String")
  if p.matchPrefix(pfString):
    var s = ""
    while not p.matchChar(chNull):
      let ch = p.charRange(chAsciiStart, chAsciiEnd)
      if ch.isNone:
        return
      s.add(ch.get)

    result = option s

### ArgObj / LocalObj

proc argObj(p: var Parser): Option[ArgObj] =
  # ArgObj := Arg0Op | Arg1Op | Arg2Op | Arg3Op | Arg4Op | Arg5Op | Arg6Op
  # debugln(&"ArgObj")
  result = p.byteRange(ocbArg0Op.byte, ocbArg6Op.byte).map(b => ArgObj(b))

proc localObj(p: var Parser): Option[LocalObj] =
  # LocalObj := Local0Op | Local1Op | Local2Op | Local3Op | Local4Op | Local5Op | Local6Op | Local7Op
  # debugln(&"LocalObj")
  result = p.byteRange(ocbLocal0Op.byte, ocbLocal7Op.byte).map(b => LocalObj(b))

### ExpressionOpcode

proc expressionOpcode(p: var Parser): Option[ExpressionOpcode] =
  # ExpressionOpcode
  # := DefAcquire | DefAdd | DefAnd | DefBuffer | DefConcat | DefConcatRes | DefCondRefOf
  #  | DefCopyObject | DefDecrement | DefDerefOf | DefDivide | DefFindSetLeftBit
  #  | DefFindSetRightBit | DefFromBCD | DefIncrement | DefIndex | DefLAnd | DefLEqual
  #  | DefLGreater | DefLGreaterEqual | DefLLess | DefLLessEqual | DefMid | DefLNot | DefLNotEqual
  #  | DefLoadTable | DefLOr | DefMatch | DefMod | DefMultiply | DefNAnd | DefNOr | DefNot
  #  | DefObjectType | DefOr | DefPackage | DefVarPackage | DefRefOf | DefShiftLeft | DefShiftRight
  #  | DefSizeOf | DefStore | DefSubtract | DefTimer | DefToBCD | DefToBuffer | DefToDecimalString
  #  | DefToHexString | DefToInteger | DefToString | DefWait | DefXOr | MethodInvocation
  # debugln(&"ExpressionOpcode")
  result = p.defAcquire().map(da => ExpressionOpcode(kind: expAcquire, defAcquire: da))
  if result.isSome:
    return

  result = p.defAnd().map(da => ExpressionOpcode(kind: expAnd, defAnd: da))
  if result.isSome:
    return

  result = p.defBuffer().map(db => ExpressionOpcode(kind: expBuffer, defBuffer: db))
  if result.isSome:
    return

  result = p.defToHexString().map(ths => ExpressionOpcode(kind: expToHexString, defToHexString: ths))
  if result.isSome:
    return

  result = p.defToBuffer().map(tb => ExpressionOpcode(kind: expToBuffer, defToBuffer: tb))
  if result.isSome:
    return
  
  result = p.defSubtract().map(ds => ExpressionOpcode(kind: expSubtract, defSubtract: ds))
  if result.isSome:
    return

  result = p.defSizeOf().map(so => ExpressionOpcode(kind: expSizeOf, defSizeOf: so))
  if result.isSome:
    return

  result = p.defStore().map(ds => ExpressionOpcode(kind: expStore, defStore: ds))
  if result.isSome:
    return
  
  result = p.defLEqual().map(dle => ExpressionOpcode(kind: expLEqual, defLEqual: dle))
  if result.isSome:
    return

  result = p.defLLess().map(dll => ExpressionOpcode(kind: expLLess, defLLess: dll))
  if result.isSome:
    return
  
  result = p.defLNot().map(dln => ExpressionOpcode(kind: expLNot, defLNot: dln))
  if result.isSome:
    return

  result = p.defLOr().map(dlo => ExpressionOpcode(kind: expLOr, defLOr: dlo))
  if result.isSome:
    return

  result = p.defOr().map(dor => ExpressionOpcode(kind: expOr, defOr: dor))
  if result.isSome:
    return

  result = p.defPackage().map(dp => ExpressionOpcode(kind: expPackage, defPackage: dp))
  if result.isSome:
    return

  result = p.defIndex().map(di => ExpressionOpcode(kind: expIndex, defIndex: di))
  if result.isSome:
    return

  result = p.defDerefOf().map(ddo => ExpressionOpcode(kind: expDerefOf, defDerefOf: ddo))
  if result.isSome:
    return

  result = p.defIncrement().map(di => ExpressionOpcode(kind: expIncrement, defIncrement: di))
  if result.isSome:
    return

  result = p.defShiftLeft().map(dsl => ExpressionOpcode(kind: expShiftLeft, defShiftLeft: dsl))
  if result.isSome:
    return

  result = p.methodInvocation().map(mi => ExpressionOpcode(kind: expMethodInvocation, call: mi))
  if result.isSome:
    return

proc defAcquire(p: var Parser): Option[DefAcquire] =
  # DefAcquire := AcquireOp MutexObject Timeout
  # debugln(&"DefAcquire")
  if p.matchOpCodeWord(ocwAcquireOp):
    let mutex = p.superName()
    if mutex.isSome:
      let timeout = p.readWord()
      if timeout.isSome:
        result = option DefAcquire(mutex: mutex.get, timeout: timeout.get)

proc defAnd(p: var Parser): Option[DefAnd] =
  # DefAnd := AndOp Operand Operand Target
  # debugln(&"DefAnd")
  if p.matchOpCodeByte(ocbAndOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        let target = p.target()
        if target.isSome:
          result = option DefAnd(operand1: op1.get, operand2: op2.get, target: target.get)

proc defBuffer(p: var Parser): Option[DefBuffer] =
  # DefBuffer := BufferOp PkgLength BufferSize ByteList
  #   BufferSize := TermArg => Integer
  #   ByteList := Nothing | <ByteData ByteList>
  # debugln(&"DefBuffer")
  if p.matchOpCodeByte(ocbBufferOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let buffSize = p.termArg()
        if buffSize.isSome:
          let resourceDesc = p.resourceDesc()
          if resourceDesc.isSome:
            result = option DefBuffer(
              size: buffSize.get,
              kind: bpResourceDesc,
              resourceDesc: resourceDesc.get,
            )
          else:
            let buffer = p.readBuffer()
            if buffer.isSome:
              result = option DefBuffer(
                size: buffSize.get,
                kind: bpBytes,
                bytes: buffer.get,
              )

proc defToHexString(p: var Parser): Option[DefToHexString] =
  # DefToHexString := ToHexStringOp Operand Target
  # debugln(&"DefToHexString")
  if p.matchOpCodeByte(ocbToHexStringOp):
    let op = p.operand()
    if op.isSome:
      let target = p.target()
      if target.isSome:
        result = option DefToHexString(operand: op.get, target: target.get)

proc defToBuffer(p: var Parser): Option[DefToBuffer] =
  # DefToBuffer := ToBufferOp Operand Target
  # debugln(&"DefToBuffer")
  if p.matchOpCodeByte(ocbToBufferOp):
    let op = p.operand()
    if op.isSome:
      let target = p.target()
      if target.isSome:
        result = option DefToBuffer(operand: op.get, target: target.get)

proc defSubtract(p: var Parser): Option[DefSubtract] =
  # DefSubtract := SubtractOp Operand Operand Target
  # debugln(&"DefSubtract")
  if p.matchOpCodeByte(ocbSubtractOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        let target = p.target()
        if target.isSome:
          result = option DefSubtract(operand1: op1.get, operand2: op2.get, target: target.get)

proc defSizeOf(p: var Parser): Option[DefSizeOf] =
  # DefSizeOf := SizeOfOp SuperName
  # debugln(&"DefSizeOf")
  if p.matchOpCodeByte(ocbSizeOfOp):
    result = p.superName().map(sn => DefSizeOf(name: sn))

proc defStore(p: var Parser): Option[DefStore] =
  # DefStore := StoreOp TermArg SuperName
  if p.matchOpCodeByte(ocbStoreOp):
    inc storeCount
    let ta = p.termArg()
    if ta.isSome:
      let sn = p.superName()
      if sn.isSome:
        result = option DefStore(src: ta.get, dst: sn.get)

proc defLEqual(p: var Parser): Option[DefLEqual] =
  # DefLEqual := LEqualOp Operand Operand
  # debugln(&"DefLEqual")
  if p.matchOpCodeByte(ocbLEqualOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        result = option DefLEqual(operand1: op1.get, operand2: op2.get)

proc defLLess(p: var Parser): Option[DefLLess] =
  # DefLLess := LLessOp Operand Operand
  # debugln(&"DefLLess")
  if p.matchOpCodeByte(ocbLLessOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        result = option DefLLess(operand1: op1.get, operand2: op2.get)

proc defLNot(p: var Parser): Option[DefLNot] =
  # DefLNot := LNotOp Operand
  # debugln(&"DefLNot")
  if p.matchOpCodeByte(ocbLNotOp):
    result = p.operand().map(op => DefLNot(operand: op))

proc defLOr(p: var Parser): Option[DefLOr] =
  # DefLOr := LOrOp Operand Operand
  # debugln(&"DefLOr")
  if p.matchOpCodeByte(ocbLOrOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        result = option DefLOr(operand1: op1.get, operand2: op2.get)

proc defOr(p: var Parser): Option[DefOr] =
  # DefOr := OrOp Operand Operand Target
  # debugln(&"DefOr")
  if p.matchOpCodeByte(ocbOrOp):
    let op1 = p.operand()
    if op1.isSome:
      let op2 = p.operand()
      if op2.isSome:
        let target = p.target()
        if target.isSome:
          result = option DefOr(operand1: op1.get, operand2: op2.get, target: target.get)

proc packageElement(p: var Parser): Option[PackageElement] =
  # PackageElement := DataObject | NameString
  # debugln(&"DefPackageElement")
  result = p.dataObject().map(dobj => PackageElement(kind: peDataObj, dataObj: dobj))
  if result.isSome:
    return

  result = p.nameString().map(ns => PackageElement(kind: peNameString, name: ns))
  if result.isSome:
    return

proc defPackage(p: var Parser): Option[DefPackage] =
  # DefPackage := PackageOp PkgLength NumElements PackageElementList
  #   PackageElementList := Nothing | <PackageElement PackageElementList>
  #   PackageElement := DataRefObject | NameString
  # debugln(&"DefPackage")
  if p.matchOpCodeByte(ocbPackageOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let numElements = p.readByte()
        if numElements.isSome:
          let num = numElements.get
          var elements: seq[PackageElement]
          for i in 0 ..< num.int:
            let pe = p.packageElement()
            if pe.isSome:
              elements.add(pe.get)
          # if elements.len == num.int:
          result = option DefPackage(elements: elements)

proc defIndex(p: var Parser): Option[DefIndex] =
  # DefIndex := IndexOp BuffPkgStrObj IndexValue Target
  # debugln(&"DefIndex")
  if p.matchOpCodeByte(ocbIndexOp):
    let src = p.termArg()
    if src.isSome:
      let idx = p.termArg()
      if idx.isSome:
        let dst = p.target()
        if dst.isSome:
          result = option DefIndex(src: src.get, idx: idx.get, dst: dst.get)

proc defDerefOf(p: var Parser): Option[DefDerefOf] =
  # DefDerefOf := DerefOfOp ObjReference
  # debugln(&"DefDerefOf")
  if p.matchOpCodeByte(ocbDerefOfOp):
    result = p.termArg().map(ta => DefDerefOf(src: ta))

proc defIncrement(p: var Parser): Option[DefIncrement] =
  # DefIncrement := IncrementOp SuperName
  # debugln(&"DefIncrement")
  if p.matchOpCodeByte(ocbIncrementOp):
    result = p.superName().map(sn => DefIncrement(addend: sn))

proc defShiftLeft(p: var Parser): Option[DefShiftLeft] =
  # DefShiftLeft := ShiftLeftOp Operand ShiftCount Target
  #   ShiftCount := TermArg
  # debugln(&"DefShiftLeft")
  if p.matchOpCodeByte(ocbShiftLeftOp):
    let op = p.operand()
    if op.isSome:
      let shiftCount = p.termArg()
      if shiftCount.isSome:
        let target = p.target()
        if target.isSome:
          result = option DefShiftLeft(operand: op.get, count: shiftCount.get, target: target.get)

proc methodInvocation(p: var Parser): Option[MethodInvocation] =
  # MethodInvocation := NameString TermArgList
  #   TermArgList := Nothing | <TermArg TermArgList>
  # debugln(&"MethodInvocation")
  let loc = p.ctx.loc

  # get method name
  let name = p.nameString()
  if name.isSome:
    # check if method is defined
    let m = p.methods.getOrDefault(name.get, nil)
    if m.isNil:
      # not a method, rewind context
      p.ctx.loc = loc
      return

    # get method args
    var args = newSeqOfCap[TermArg](m.flags.argCount)
    for i in 0.uint8 ..< m.flags.argCount:
      let arg = p.termArg()
      if arg.isNone:
        # args don't match expected count, rewind context
        p.ctx.loc = loc
        return
      args.add(arg.get)

    result = option MethodInvocation(name: name.get, args: args)

### Resource Descriptors

proc resourceDesc(p: var Parser): Option[ResourceDescriptor] =
  result = p.dwordAddrSpaceDesc().map(dwas => ResourceDescriptor(kind: rdDWordAddressSpace, dwordAddrSpace: dwas))
  if result.isSome:
    return

  result = p.extendedInterruptDesc().map(eid => ResourceDescriptor(kind: rdExtendedInterrupt, extInterrupt: eid))
  if result.isSome:
    return

proc dwordAddrSpaceDesc(p: var Parser): Option[DWordAddrSpaceDesc] =
  # debugln(&"DWordAddressSpace")
  if p.matchByte(rdDWordAddressSpace.byte):
    let len = p.readWord()
    if len.isSome:
      let resType = p.readByte()
      if resType.isSome:
        let addrSpaceFlags = p.readByte()
        if addrSpaceFlags.isSome:
          let memFlags = p.readByte()
          if memFlags.isSome:
            let granularity = p.readDWord()
            if granularity.isSome:
              let addrRangeMin = p.readDWord()
              if addrRangeMin.isSome:
                let addrRangeMax = p.readDWord()
                if addrRangeMax.isSome:
                  let addrTranslationOffset = p.readDWord()
                  if addrTranslationOffset.isSome:
                    let addrLen = p.readDWord()
                    if addrLen.isSome:
                      result = option DWordAddrSpaceDesc(
                        resType: cast[AddressSpaceResourceType](resType.get),
                        addrSpaceFlags: cast[AddressSpaceFlags](addrSpaceFlags.get),
                        memFlags: cast[MemorySpecificFlags](memFlags.get),
                        granularity: granularity.get,
                        minAddr: addrRangeMin.get,
                        maxAddr: addrRangeMax.get,
                        translationOffset: addrTranslationOffset.get,
                        addressLength: addrLen.get
                      )

proc extendedInterruptDesc(p: var Parser): Option[ExtendedInterruptDesc] =
  # debugln(&"ExtendedInterrupt")
  if p.matchByte(rdExtendedInterrupt.byte):
    let len = p.readWord()
    if len.isSome:
      let flags = p.readByte()
      if flags.isSome:
        let count = p.readByte()
        if count.isSome:
          var intNums: seq[uint32]
          for i in 0.uint8 ..< count.get:
            let intNum = p.readDWord()
            if intNum.isSome:
              intNums.add(intNum.get)
          result = option ExtendedInterruptDesc(
            flags: cast[ExtendedInterruptFlags](flags.get),
            intNums: intNums
          )

### Statements

proc statementOpcode(p: var Parser): Option[StatementOpcode] =
  # StatementOpcode
  #   := DefBreak | DefBreakPoint | DefContinue | DefFatal | DefIfElse | DefNoop | DefNotify
  #    | DefRelease | DefReset | DefReturn | DefSignal | DefSleep | DefStall | DefWhile
  # debugln(&"StatementOpcode")
  result = p.defIfElse().map(die => StatementOpcode(kind: stmtIfElse, defIfElse: die))
  if result.isSome:
    return

  result = p.defRelease().map(dr => StatementOpcode(kind: stmtRelease, defRelease: dr))
  if result.isSome:
    return

  result = p.defReturn().map(dr => StatementOpcode(kind: stmtReturn, defReturn: dr))
  if result.isSome:
    return

  result = p.defWhile().map(dw => StatementOpcode(kind: stmtWhile, defWhile: dw))
  if result.isSome:
    return

proc defIfElse(p: var Parser): Option[DefIfElse] =
  # DefIfElse := IfOp PkgLength Predicate TermList DefElse
  #   DefElse := Nothing | <ElseOp PkgLength TermList>
  # debugln(&"DefIfElse")
  if p.matchOpCodeByte(ocbIfOp):
    var ifBody: TermList
    var elseBody: Option[TermList]
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let predicate = p.termArg()
        if predicate.isSome:
          ifBody = p.termList()
          if p.matchOpCodeByte(ocbElseOp):
            var pkgResult = p.pkgLength()
            if pkgResult.isSome:
              let (bytesRead, pkgLen) = pkgResult.get
              p.withContext(pkgLen - bytesRead):
                elseBody = option p.termList()
          result = option DefIfElse(predicate: predicate.get, ifBody: ifBody, elseBody: elseBody)
      # some implementations (e.g. QEMU) have the else part outside the if statement
      if p.matchOpCodeByte(ocbElseOp):
        var pkgResult = p.pkgLength()
        if pkgResult.isSome:
          let (bytesRead, pkgLen) = pkgResult.get
          p.withContext(pkgLen - bytesRead):
            elseBody = option p.termList()
            result = option DefIfElse(predicate: predicate.get, ifBody: ifBody, elseBody: elseBody)

proc defRelease(p: var Parser): Option[DefRelease] =
  # DefRelease := ReleaseOp MutexObject
  #   MutexObject := SuperName
  # debugln(&"DefRelease")
  if p.matchOpCodeWord(ocwReleaseOp):
    result = p.superName().map(sn => DefRelease(mutex: sn))

proc defReturn(p: var Parser): Option[DefReturn] =
  # DefReturn := ReturnOp ArgObject
  # debugln(&"DefReturn")
  if p.matchOpCodeByte(ocbReturnOp):
    result = p.termArg().map(ta => DefReturn(arg: ta))

proc defWhile(p: var Parser): Option[DefWhile] =
  # DefWhile := WhileOp PkgLength Predicate TermList
  # debugln(&"DefWhile")
  if p.matchOpCodeByte(ocbWhileOp):
    var pkgResult = p.pkgLength()
    if pkgResult.isSome:
      let (bytesRead, pkgLen) = pkgResult.get
      p.withContext(pkgLen - bytesRead):
        let predicate = p.termArg()
        if predicate.isSome:
          let body = p.termList()
          result = option DefWhile(predicate: predicate.get, body: body)


### operand/target

proc operand(p: var Parser): Option[Operand] =
  # Operand := TermArg => Integer
  # debugln(&"Operand")
  result = p.termArg().map(ta => Operand(ta))

proc target(p: var Parser): Option[Target] =
  # Target := SuperName | NullName
  # debugln(&"Target")
  result = p.chr(chNull).map(nn => Target(kind: tgNullName))
  if result.isSome:
    return

  result = p.superName().map(sn => Target(kind: tgSuperName, superName: sn))
  if result.isSome:
    return

### char/byte and ranges

proc chr(p: var Parser, ch: Char): Option[char] =
  # debugln(&"chr")
  result = p.byt(ch.byte).map(b => b.char)

proc byt(p: var Parser, `byte`: byte): Option[byte] =
  # debugln(&"byt")
  if p.peekByte().filter(b => b == `byte`).isSome:
    result = p.readByte()

proc charRange(p: var Parser, start: Char, `end`: Char): Option[char] =
  # debugln(&"charRange")
  result = p.byteRange(start.byte, `end`.byte).map(b => b.char)

proc byteRange(p: var Parser, start: byte, `end`: byte): Option[byte] =
  # debugln(&"byteRange")
  if p.peekByte().filter(b => b in start .. `end`).isSome:
    result = p.readByte()



### matching

proc matchOpCodeByte(p: var Parser, opCode: OpCodeByte): bool =
  # debugln(&"matchOpCodeByte")
  result = p.matchByte(opCode.byte)

proc matchOpCodeWord(p: var Parser, opCode: OpCodeWord): bool =
  # debugln(&"matchOpCodeWord")
  result = p.peekWord().filter(w => w == opCode.uint16).isSome
  if result:
      discard p.readWord()

proc matchPrefix(p: var Parser, prefix: Prefix): bool =
  # debugln(&"matchPrefix")
  result = p.matchByte(prefix.byte)

proc matchChar(p: var Parser, ch: Char): bool =
  # debugln(&"matchChar")
  result = p.matchByte(ch.byte)

proc matchByte(p: var Parser, `byte`: byte): bool =
  # debugln(&"matchByte")
  result = p.peekByte().filter(b => b == `byte`).isSome
  if result:
      discard p.readByte()

### peek and read

proc peekByte(p: var Parser): Option[byte] {.inline.} =
  if p.ctx.loc < p.ctx.len:
    result = option p.ctx.chunk[p.ctx.loc]

proc peekWord(p: var Parser): Option[uint16] {.inline.} =
  if p.ctx.loc + 1 < p.ctx.len:
    result = option (p.ctx.chunk[p.ctx.loc].uint16 or (p.ctx.chunk[p.ctx.loc + 1].uint16 shl 8))

proc readByte(p: var Parser): Option[byte] {.inline.} =
  result = p.peekByte()
  if result.isSome:
    inc p.ctx.loc
    # debugln(&"readByte, curr: {p.ctx.chunk[p.ctx.loc - 1]:02x}, next: {p.ctx.chunk[p.ctx.loc]:02x}")

proc readWord(p: var Parser): Option[uint16] {.inline.} =
  result = p.peekWord()
  if result.isSome:
    inc p.ctx.loc
    # debugln(&"readByte, curr: {p.ctx.chunk[p.ctx.loc - 1]:02x}, next: {p.ctx.chunk[p.ctx.loc]:02x}")
    inc p.ctx.loc
    # debugln(&"readByte, curr: {p.ctx.chunk[p.ctx.loc - 1]:02x}, next: {p.ctx.chunk[p.ctx.loc]:02x}")

proc readDWord(p: var Parser): Option[uint32] {.inline.} =
  let lo = p.readWord()
  if lo.isSome:
    let hi = p.readWord()
    if hi.isSome:
      result = option (lo.get.uint32 or (hi.get.uint32 shl 16))

proc readBuffer(p: var Parser, len: int): Option[seq[byte]] {.inline.} =
  if p.ctx.loc + len <= p.ctx.len:
    result = option toOpenArray(p.ctx.chunk, p.ctx.loc, p.ctx.loc + len - 1).toSeq
    inc p.ctx.loc, len

proc readBuffer(p: var Parser): Option[seq[byte]] {.inline.} =
  result = p.readBuffer(p.ctx.len - p.ctx.loc)
