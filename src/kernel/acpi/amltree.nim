# ACPI AML tree printer
import std/importutils
import std/options
import std/strformat
import std/strutils

import aml {.all.}
import ../debug
import ../devices/console

privateAccess(TermList)
privateAccess(TermObj)
privateAccess(Obj)

privateAccess(NamespaceModifierObj)
privateAccess(DefName)
privateAccess(DefScope)

privateAccess(NamedObj)
privateAccess(DefCreateDWordField)
privateAccess(DefField)
privateAccess(DefDevice)
privateAccess(DefMutex)
privateAccess(DefOpRegion)

privateAccess(DataObject)
privateAccess(ComputationalData)
privateAccess(ConstObj)
privateAccess(DefField)
privateAccess(FieldFlags)
privateAccess(FieldElement)
privateAccess(NamedField)
privateAccess(ReservedField)
privateAccess(DefMethod)
privateAccess(MethodFlags)

privateAccess(ExpressionOpcode)
privateAccess(RefTypeOpcode)
privateAccess(DefAcquire)
privateAccess(DefAnd)
privateAccess(DefBuffer)
privateAccess(DefToHexString)
privateAccess(DefToBuffer)
privateAccess(DefSubtract)
privateAccess(DefSizeOf)
privateAccess(DefStore)
privateAccess(DefLEqual)
privateAccess(DefLLess)
privateAccess(DefLNot)
privateAccess(DefLOr)
privateAccess(DefOr)
privateAccess(PackageElement)
privateAccess(DefPackage)
privateAccess(DefIndex)
privateAccess(DefDerefOf)
privateAccess(DefIncrement)
privateAccess(DefShiftLeft)
privateAccess(MethodInvocation)

privateAccess(ResourceDescriptor)
privateAccess(AddressSpaceFlags)
privateAccess(MemorySpecificFlags)
privateAccess(DWordAddrSpaceDesc)
privateAccess(ExtendedInterruptDesc)
privateAccess(ExtendedInterruptFlags)

privateAccess(StatementOpcode)
privateAccess(DefIfElse)
privateAccess(DefRelease)
privateAccess(DefReturn)
privateAccess(DefWhile)

privateAccess(NameString)
privateAccess(SuperName)
privateAccess(SimpleName)
privateAccess(TermArg)
privateAccess(Target)


# forward declarations
proc visit(termList: TermList)
proc visit(termObj: TermObj)
proc visit(obj: Obj)

proc visit(nsModObj: NamespaceModifierObj)
proc visit(defName: DefName)
proc visit(defScope: DefScope)

proc visit(namedObj: NamedObj)
proc visit(defCreateDWordField: DefCreateDWordField)
proc visit(defField: DefField)
proc visit(defDevice: DefDevice)
proc visit(defMutex: DefMutex)
proc visit(defOpRegion: DefOpRegion)
proc visit(fieldElement: FieldElement)
proc visit(dataObject: DataObject)
proc visit(compData: ComputationalData)
proc visit(constObj: ConstObj)
proc visit(defMethod: DefMethod)

proc visit(expr: ExpressionOpcode)
proc visit(rto: RefTypeOpcode)
proc visit(defAcquire: DefAcquire)
proc visit(defAnd: DefAnd)
proc visit(defBuffer: DefBuffer)
proc visit(defToHexString: DefToHexString)
proc visit(defToBuffer: DefToBuffer)
proc visit(defSubtract: DefSubtract)
proc visit(defSizeOf: DefSizeOf)
proc visit(defStore: DefStore)
proc visit(defLEqual: DefLEqual)
proc visit(defLLess: DefLLess)
proc visit(defLNot: DefLNot)
proc visit(defLOr: DefLOr)
proc visit(defOr: DefOr)
proc visit(defPackage: DefPackage)
proc visit(defIndex: DefIndex)
proc visit(defDerefOf: DefDerefOf)
proc visit(defIncrement: DefIncrement)
proc visit(defShiftLeft: DefShiftLeft)
proc visit(methodInvocation: MethodInvocation)

proc visit(resourceDesc: ResourceDescriptor)
proc visit(dwordAddrSpace: DWordAddrSpaceDesc)
proc visit(extInterrupt: ExtendedInterruptDesc)

proc visit(stmt: StatementOpcode)
proc visit(defIfElse: DefIfElse)
proc visit(defRelease: DefRelease)
proc visit(defReturn: DefReturn)
proc visit(defWhile: DefWhile)

proc visit(argObj: ArgObj)
proc visit(localObj: LocalObj)

proc visit(termArg: TermArg)
proc visit(target: Target)
proc visit(superName: SuperName)
proc visit(simpleName: SimpleName)

proc toUuid(bytes: seq[byte]): Option[string]

var
  indlvl = 0
  isinline = @[false]

template indent(body: untyped) =
  inc indlvl, 2
  body
  dec indlvl, 2

template inline(body: untyped) =
  isinline.add true
  body
  discard isinline.pop

template noinline(body: untyped) =
  isinline.add false
  body
  discard isinline.pop

proc print(str: string) =
  write str

proc println(str: string) =
  write str
  if not isinline[^1]:
    write "\n"

proc indprint(str: string) =
  write " ".repeat(indlvl)
  write str

proc indprintln(str: string) =
  indprint(str)
  if not isinline[^1]:
    writeln ""

proc print*(termList: TermList) =
  visit(termList)

proc visit(termList: TermList) =
  for termObj in termList:
    indprint("")
    visit(termObj)

## TermList kinds
##   Nothing | <TermObj TermList>

proc visit(termObj: TermObj) =
  case termObj.kind:
  of toObject:
    visit(termObj.obj)
  of toStatement:
    visit(termObj.stmt)
  of toExpression:
    visit(termObj.expr)

## TermObj kinds
##   Object | StatementOpcode | ExpressionOpcode

proc visit(obj: Obj) =
  case obj.kind:
  of okNsModObj:
    visit(obj.nsModObj)
  of okNamedObj:
    visit(obj.namedObj)

## Object kinds
##   NameSpaceModifierObj | NamedObj

proc visit(nsModObj: NamespaceModifierObj) =
  case nsModObj.kind:
  of nmoDefName:
    visit(nsModObj.defName)
  of nmoDefScope:
    visit(nsModObj.defScope)

proc visit(defName: DefName) =
  print(&"Name ({defName.name}, ")
  inline:
    visit(defName.obj)
  println(")")

proc visit(namedObj: NamedObj) =
  case namedObj.kind:
  of noDefCreateDWordField:
    visit(namedObj.defCreateDWordField)
  of noDefDevice:
    visit(namedObj.defDevice)
  of noDefMutex:
    visit(namedObj.defMutex)
  of noDefOpRegion:
    visit(namedObj.defOpRegion)
  of noDefField:
    visit(namedObj.defField)
  of noDefMethod:
    visit(namedObj.defMethod)

## NamespaceModifierObj kinds
##   DefAlias | DefName | DefScope

proc visit(defScope: DefScope) =
  println(&"Scope ({defScope.name}) {{")
  indent:
    visit(defScope.terms)
  indprintln("}")

## NamedObj kinds
##   DefBankField | DefCreateBitField | DefCreateByteField | DefCreateDWordField | DefCreateField
## | DefCreateQWordField | DefCreateWordField | DefDataRegion | DefExternal | DefOpRegion
## | DefPowerRes | DefThermalZone

proc visit(defCreateDWordField: DefCreateDWordField) =
  print(&"CreateDWordField (")
  visit(defCreateDWordField.srcBuffer)
  print(", ")
  visit(defCreateDWordField.byteIndex)
  println(&", {defCreateDWordField.name})")

proc visit(defDevice: DefDevice) =
  println(&"Device ({defDevice.name}) {{")
  indent:
    visit(defDevice.body)
  indprintln("}")

proc visit(defMutex: DefMutex) =
  println(&"Mutex ({defMutex.name}, {defMutex.syncLevel})")

proc visit(defOpRegion: DefOpRegion) =
  print(&"OperationRegion ({defOpRegion.name}, {defOpRegion.space}, ")
  visit(defOpRegion.offset)
  print(", ")
  visit(defOpRegion.len)
  println(")")

proc visit(defField: DefField) =
  print(&"Field ({defField.regionName}, ")
  print(&"{defField.flags.accessType}, ")
  print(&"{defField.flags.lockRule}, ")
  println(&"{defField.flags.updateRule}) {{")
  indent:
    for element in defField.elements:
      indprint("")
      visit(element)
  indprintln("}")

proc visit(fieldElement: FieldElement) =
  case fieldElement.kind:
  of feNamedField:
    println(&"{fieldElement.namedField.name}, {fieldElement.namedField.bits},")
  of feReservedField:
    println(&"Offset (0x{fieldElement.reservedField.bits:x}),")

proc visit(defMethod: DefMethod) =
  print(&"Method ({defMethod.name}")
  if defMethod.flags.argCount > 0:
    print(&", {defMethod.flags.argCount}")
  if defMethod.flags.serialized:
    print(&", Serialized")
  if defMethod.flags.syncLevel > 0:
    print(&", {defMethod.flags.syncLevel}")
  println(") {")
  indent:
    visit(defMethod.terms)
  indprintln("}")

## TermArg kinds
##   ExpressionOpcode | DataObject | ArgObj | LocalObj | NamedString

proc visit(dataObject: DataObject) =
  case dataObject.kind:
  of doComputationalData:
    visit(dataObject.compData)
  of doDefPackage:
    visit(dataObject.defPackage)

proc visit(expr: ExpressionOpcode) =
  case expr.kind:
  of expAcquire:
    visit(expr.defAcquire)
  of expAnd:
    visit(expr.defAnd)
  of expBuffer:
    visit(expr.defBuffer)
  of expToHexString:
    visit(expr.defToHexString)
  of expToBuffer:
    visit(expr.defToBuffer)
  of expSubtract:
    visit(expr.defSubtract)
  of expSizeOf:
    visit(expr.defSizeOf)
  of expStore:
    visit(expr.defStore)
  of expLEqual:
    visit(expr.defLEqual)
  of expLLess:
    visit(expr.defLLess)
  of expLNot:
    visit(expr.defLNot)
  of expLOr:
    visit(expr.defLOr)
  of expOr:
    visit(expr.defOr)
  of expPackage:
    visit(expr.defPackage)
  of expIndex:
    visit(expr.defIndex)
  of expDerefOf:
    visit(expr.defDerefOf)
  of expIncrement:
    visit(expr.defIncrement)
  of expShiftLeft:
    visit(expr.defShiftLeft)
  of expMethodInvocation:
    visit(expr.call)

proc visit(rto: RefTypeOpcode) =
  case rto.kind:
  of rtoIndex:
    visit(rto.defIndex)

proc visit(defAcquire: DefAcquire) =
  print(&"Acquire (")
  visit(defAcquire.mutex)
  println(&")")

proc visit(defAnd: DefAnd) =
  print(&"And (")
  visit(defAnd.operand1)
  print(&", ")
  visit(defAnd.operand2)
  if defAnd.target.kind != tgNullName:
    print(&", ")
    visit(defAnd.target)
  println(&")")

proc visit(defBuffer: DefBuffer) =
    case defBuffer.kind:
    of bpBytes:
      let uuid = toUuid(defBuffer.bytes)
      if uuid.isSome:
        print(&"\"{uuid.get}\"")
      else:
        print(&"Buffer (")
        for i, b in defBuffer.bytes:
          print(&"{b:02x}")
          if i < defBuffer.bytes.high:
            print(" ")
        print(&")")

    of bpResourceDesc:
      visit(defBuffer.resourceDesc)

proc visit(defToHexString: DefToHexString) =
  print(&"ToHexString (")
  inline:
    visit(defToHexString.operand)
    print(&", ")
    visit(defToHexString.target)
  println(&")")

proc visit(defToBuffer: DefToBuffer) =
  print(&"ToBuffer (")
  inline:
    visit(defToBuffer.operand)
    print(&", ")
    visit(defToBuffer.target)
  println(&")")

proc visit(defSubtract: DefSubtract) =
  print(&"Subtract (")
  inline:
    visit(defSubtract.operand1)
    print(&", ")
    visit(defSubtract.operand2)
    print(&", ")
    visit(defSubtract.target)
  println(&")")

proc visit(defSizeOf: DefSizeOf) =
  print(&"SizeOf (")
  inline:
    visit(defSizeOf.name)
  println(&")")

proc visit(defStore: DefStore) =
  print(&"Store (")
  inline:
    visit(defStore.src)
    print(&", ")
    visit(defStore.dst)
  println(&")")

proc visit(defLEqual: DefLEqual) =
  print(&"LEqual (")
  inline:
    visit(defLEqual.operand1)
    print(&", ")
    visit(defLEqual.operand2)
  println(&")")

proc visit(defLLess: DefLLess) =
  print(&"LLess (")
  inline:
    visit(defLLess.operand1)
    print(&", ")
    visit(defLLess.operand2)
  println(&")")

proc visit(defLNot: DefLNot) =
  print(&"LNot (")
  inline:
    visit(defLNot.operand)
  println(&")")

proc visit(defLOr: DefLOr) =
  print(&"LOr (")
  inline:
    visit(defLOr.operand1)
    print(&", ")
    visit(defLOr.operand2)
  println(&")")

proc visit(defOr: DefOr) =
  print(&"Or (")
  inline:
    visit(defOr.operand1)
    print(&", ")
    visit(defOr.operand2)
    if defOr.target.kind != tgNullName:
      print(&", ")
      visit(defOr.target)
  println(&")")

proc visit(packageElement: PackageElement) =
  case packageElement.kind:
  of peDataObj:
    visit(packageElement.dataObj)
  of peNameString:
    print(packageElement.name)

proc visit(defPackage: DefPackage) =
  print("Package () {")
  if defPackage.elements.len > 8:
    noinline:
      println("")
      indent:
        for (i, el) in defPackage.elements.pairs:
          indprint("")
          inline:
            visit(el)
          if i < defPackage.elements.high:
            println(&",")
        println("")
      indprint("}")
  else:
    inline:
      for (i, el) in defPackage.elements.pairs:
        visit(el)
        if i < defPackage.elements.high:
          print(&", ")
    println("}")

proc visit(defIndex: DefIndex) =
  print(&"Index (")
  inline:
    visit(defIndex.src)
    print(&", ")
    visit(defIndex.idx)
    if defIndex.dst.kind != tgNullName:
      print(&", ")
      visit(defIndex.dst)
  println(&")")

proc visit(defDerefOf: DefDerefOf) =
  print(&"DerefOf (")
  inline:
    visit(defDerefOf.src)
  println(&")")

proc visit(defIncrement: DefIncrement) =
  print(&"Increment (")
  inline:
    visit(defIncrement.addend)
  println(&")")

proc visit(defShiftLeft: DefShiftLeft) =
  print(&"ShiftLeft (")
  inline:
    visit(defShiftLeft.operand)
    print(&", ")
    visit(defShiftLeft.count)
    if defShiftLeft.target.kind != tgNullName:
      print(&", ")
      visit(defShiftLeft.target)
  println(&")")

proc visit(methodInvocation: MethodInvocation) =
  print(&"{methodInvocation.name} (")
  inline:
    for (i, arg) in methodInvocation.args.pairs:
      visit(arg)
      if i < methodInvocation.args.high:
        print(&", ")
  println(&")")

## Resource Descriptors

proc visit(resourceDesc: ResourceDescriptor) =
  noinline:
    println("ResourceTemplate () {")
    indent:
      case resourceDesc.kind:
      of rdReserved: discard
      of rdDWordAddressSpace:
        indprint("")
        visit(resourceDesc.dwordAddrSpace)
      of rdExtendedInterrupt:
        indprint("")
        visit(resourceDesc.extInterrupt)
  indprintln("}")

proc visit(dwordAddrSpace: DWordAddrSpaceDesc) =
  println("DWordSpace (")
  indent:
    indprintln(&"  {dwordAddrSpace.resType: 20} # (_RT ) ResourceType")
    indprintln(&", {dwordAddrSpace.addrSpaceFlags.decodeType: 20} # (_DEC) Decode")
    indprintln(&", {dwordAddrSpace.addrSpaceFlags.minFixed: 20} # (_MIF) MinType")
    indprintln(&", {dwordAddrSpace.addrSpaceFlags.maxFixed: 20} # (_MAF) MaxType")
    indprintln(&", {dwordAddrSpace.memFlags.readWrite: 20} # (_TSF._RW ) Memory: Write Status")
    indprintln(&", {dwordAddrSpace.memFlags.memAttrs: 20} # (_TSF._MEM) Memory: Cacheability")
    indprintln(&", {dwordAddrSpace.memFlags.memType: 20} # (_TSF._MTP) Memory: Type")
    indprintln(&", {dwordAddrSpace.memFlags.memIOTrans: 20} # (_TFS._TTP) Memory: Memory to I/O Translation")
    indprintln(&", {dwordAddrSpace.granularity: <20x} # (_GRA) AddressGranularity")
    indprintln(&", {dwordAddrSpace.minAddr: <20x} # (_MIN) MinAddress")
    indprintln(&", {dwordAddrSpace.maxAddr: <20x} # (_MAX) MaxAddress")
    indprintln(&", {dwordAddrSpace.translationOffset: <20x} # (_TRA) AddressTranslation (Offset)")
    indprintln(&", {dwordAddrSpace.addressLength: <20x} # (_LEN) AddressLength")
  indprintln(")")

proc visit(extInterrupt: ExtendedInterruptDesc) =
  println("Interrupt (")
  indent:
    indprintln(&"  {extInterrupt.flags.resUsage: 20} # ResourceUsage")
    indprintln(&", {extInterrupt.flags.mode: 20} # (_HE) EdgeLevel")
    indprintln(&", {extInterrupt.flags.polarity: 20} # (_LL) ActiveLevel")
    indprintln(&", {extInterrupt.flags.sharing: 20} # (_SHR) Shared")
    indprintln(&", {extInterrupt.flags.wakeCap: 20} # (_WKC) Wake")
  indprint(&") {{")
  for (i, intNum) in extInterrupt.intNums.pairs:
    print(&"{intNum}")
    if i < extInterrupt.intNums.high:
      print(&",")
  println("}")

## StatementOpcode kinds
##   DefBreak | DefBreakPoint | DefContinue | DefFatal | DefIfElse | DefNoop | DefNotify
## | DefRelease | DefReset | DefReturn | DefSignal | DefSleep | DefStall | DefWhile

proc visit(stmt: StatementOpcode) =
  case stmt.kind:
  of stmtIfElse:
    visit(stmt.defIfElse)
  of stmtRelease:
    visit(stmt.defRelease)
  of stmtReturn:
    visit(stmt.defReturn)
  of stmtWhile:
    visit(stmt.defWhile)

proc visit(defIfElse: DefIfElse) =
  print("If (")
  inline:
    visit(defIfElse.predicate)
  println(") {")
  indent:
    visit(defIfElse.ifBody)
  indprintln("}")
  if defIfElse.elseBody.isSome:
    indprintln("Else {")
    indent:
      visit(defIfElse.elseBody.get)
    indprintln("}")

proc visit(defRelease: DefRelease) =
  print("Release (")
  visit(defRelease.mutex)
  println(")")

proc visit(defReturn: DefReturn) =
  print("Return (")
  inline:
    visit(defReturn.arg)
  println(")")

proc visit(defWhile: DefWhile) =
  print("While (")
  inline:
    visit(defWhile.predicate)
  println(") {")
  indent:
    visit(defWhile.body)
  indprintln("}")

## DataObject kinds
##   ComputationalData | DefPackage | DefVarPackage

proc toUuid(bytes: seq[byte]): Option[string] =
  const hexChars = "0123456789ABCDEF"
  # uuid format: aabbccdd-eeff-gghh-iijj-kkllmmnnoopp
  if bytes.len != 16:
    return none(string)

  var uuid = newStringOfCap(36)
  uuid.setLen(32)

  # convert seq[byte] to UUID hex string
  # 1. convert aabbccdd
  for i in 0 ..< 4:
    let b = bytes[3 - i]
    uuid[i * 2] = hexChars[b shr 4]
    uuid[i * 2 + 1] = hexChars[b and 0x0F]
  
  # 2. convert eeff
  for i in 0 ..< 2:
    let b = bytes[5 - i]
    uuid[8 + i * 2] = hexChars[b shr 4]
    uuid[8 + i * 2 + 1] = hexChars[b and 0x0F]
  
  # 3. convert gghh
  for i in 0 ..< 2:
    let b = bytes[7 - i]
    uuid[12 + i * 2] = hexChars[b shr 4]
    uuid[12 + i * 2 + 1] = hexChars[b and 0x0F]
  
  # 4. convert iijj-kkllmmnnoopp
  for i in 0 ..< 8:
    let b = bytes[8 + i]
    uuid[16 + i * 2] = hexChars[b shr 4]
    uuid[16 + i * 2 + 1] = hexChars[b and 0x0F]

  uuid.insert("-", 8)
  uuid.insert("-", 13)
  uuid.insert("-", 18)
  uuid.insert("-", 23)

  result = some(uuid)

proc toEisaId(dword: uint32): Option[string] =
  let b0 = uint8(dword shr 00) and 0xFF
  let b1 = uint8(dword shr 08) and 0xFF
  let b2 = uint8(dword shr 16) and 0xFF
  let b3 = uint8(dword shr 24) and 0xFF

  let v1: uint8 = ((b0 shr 2) and 0x1F) + 0x40
  let v2: uint8 = (((b0 and 0x03) shl 3) or ((b1 shr 5) and 0x07)) + 0x40
  let v3: uint8 = (b1 and 0x1F) + 0x40

  var p1: uint8 = (b2 shr 4) + 0x30
  var p2: uint8 = (b2 and 0x0F) + 0x30
  var p3: uint8 = (b3 shr 4) + 0x30
  var p4: uint8 = (b3 and 0x0F) + 0x30

  if p1 > '9'.uint8: p1 += 7
  if p2 > '9'.uint8: p2 += 7
  if p3 > '9'.uint8: p3 += 7
  if p4 > '9'.uint8: p4 += 7

  if v1.char in Letters and v2.char in Letters and v3.char in Letters and
    p1.char in HexDigits and p2.char in HexDigits and p3.char in HexDigits and p4.char in HexDigits:
    result = option &"\"{v1.char}{v2.char}{v3.char}{p1.char}{p2.char}{p3.char}{p4.char}\""

proc visit(compData: ComputationalData) =
  case compData.kind:
  of cdByteConst:
    print(&"0x{compData.byteConst:0X}")
  of cdWordConst:
    print(&"0x{compData.wordConst:0X}")
  of cdDWordConst:
    let eisaId = toEisaId(compData.dwordConst)
    if eisaId.isSome:
      print(eisaId.get)
    else:
      print(&"0x{compData.dwordConst:X}")
  of cdString:
    print(&"\"{compData.str}\"")
  of cdConstObj:
    visit(compData.constObj)
  of cdDefBuffer:
    visit(compData.defBuffer)

proc visit(constObj: ConstObj) =
  case constObj:
  of coZero:
    print("Zero")
  of coOne:
    print("One")
  of coOnes:
    print("Ones")

## Misc

proc visit(termArg: TermArg) =
  case termArg.kind:
  of taExpr:
    visit(termArg.expr)
  of taDataObject:
    visit(termArg.dataObj)
  of taArgObj:
    visit(termArg.argObj)
  of taLocalObj:
    visit(termArg.localObj)
  of taName:
    print(termArg.name)

proc visit(argObj: ArgObj) =
  case argObj
  of aoArg0:
    print("Arg0")
  of aoArg1:
    print("Arg1")
  of aoArg2:
    print("Arg2")
  of aoArg3:
    print("Arg3")
  of aoArg4:
    print("Arg4")
  of aoArg5:
    print("Arg5")
  of aoArg6:
    print("Arg6")

proc visit(localObj: LocalObj) =
  case localObj
  of loLocal0:
    print("Local0")
  of loLocal1:
    print("Local1")
  of loLocal2:
    print("Local2")
  of loLocal3:
    print("Local3")
  of loLocal4:
    print("Local4")
  of loLocal5:
    print("Local5")
  of loLocal6:
    print("Local6")
  of loLocal7:
    print("Local7")

proc visit(target: Target) =
  if target.kind != tgNullName:
    visit(target.superName)

proc visit(superName: SuperName) =
  case superName.kind:
  of snSimpleName:
    visit(superName.simpleName)
  of snRefTypeOpcode:
    visit(superName.refTypeOpcode)

proc visit(simpleName: SimpleName) =
  case simpleName.kind:
  of snName:
    print(simpleName.name)
  of snArg:
    visit(simpleName.arg)
  of snLocal:
    visit(simpleName.local)
