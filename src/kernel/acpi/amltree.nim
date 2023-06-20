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
privateAccess(DefIndex)
privateAccess(DefDerefOf)
privateAccess(DefIncrement)
privateAccess(DefShiftLeft)
privateAccess(MethodInvocation)

privateAccess(ResourceDescriptor)
privateAccess(AddressSpaceFlags)
privateAccess(MemorySpecificFlags)
privateAccess(DWordAddrSpaceDesc)

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
proc visit(defIndex: DefIndex)
proc visit(defDerefOf: DefDerefOf)
proc visit(defIncrement: DefIncrement)
proc visit(defShiftLeft: DefShiftLeft)
proc visit(methodInvocation: MethodInvocation)

proc visit(resourceDesc: ResourceDescriptor)
proc visit(dwordAddrSpace: DWordAddrSpaceDesc)


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

var indlvl = 0

template indent(body: untyped) =
  inc indlvl, 2
  body
  dec indlvl, 2

proc indwrite(str: string) =
  write " ".repeat(indlvl)
  write str

proc indwriteln(str: string) =
  indwrite(str)
  writeln("")

proc print*(termList: TermList) =
  visit(termList)

proc visit(termList: TermList) =
  for termObj in termList:
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
  indwrite(&"Name ({defName.name}, ")
  visit(defName.obj)
  writeln(")")

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
  indwriteln(&"Scope ({defScope.name}) {{")
  indent:
    for termObj in defScope.terms:
      visit(termObj)
  indwriteln("}")

## NamedObj kinds
##   DefBankField | DefCreateBitField | DefCreateByteField | DefCreateDWordField | DefCreateField
## | DefCreateQWordField | DefCreateWordField | DefDataRegion | DefExternal | DefOpRegion
## | DefPowerRes | DefThermalZone

proc visit(defCreateDWordField: DefCreateDWordField) =
  indwrite(&"CreateDWordField (")
  visit(defCreateDWordField.srcBuffer)
  write(", ")
  visit(defCreateDWordField.byteIndex)
  writeln(&", {defCreateDWordField.name})")

proc visit(defDevice: DefDevice) =
  indwriteln(&"Device ({defDevice.name}) {{")
  indent:
    for termObj in defDevice.body:
      visit(termObj)
  indwriteln("}")

proc visit(defMutex: DefMutex) =
  indwriteln(&"Mutex ({defMutex.name}, {defMutex.syncLevel})")

proc visit(defOpRegion: DefOpRegion) =
  indwrite(&"OperationRegion ({defOpRegion.name}, {defOpRegion.space}, ")
  visit(defOpRegion.offset)
  write(", ")
  visit(defOpRegion.len)
  writeln(")")

proc visit(defField: DefField) =
  indwrite(&"Field ({defField.regionName}, ")
  write(&"{defField.flags.accessType}, ")
  write(&"{defField.flags.lockRule}, ")
  writeln(&"{defField.flags.updateRule}) {{")
  indent:
    for element in defField.elements:
      visit(element)
  indwriteln("}")

proc visit(fieldElement: FieldElement) =
  case fieldElement.kind:
  of feNamedField:
    indwriteln(&"{fieldElement.namedField.name}, {fieldElement.namedField.bits},")
  of feReservedField:
    indwriteln(&"Offset (0x{fieldElement.reservedField.bits:x}),")

proc visit(defMethod: DefMethod) =
  indwrite(&"Method ({defMethod.name}")
  if defMethod.flags.argCount > 0:
    write(&", {defMethod.flags.argCount}")
  if defMethod.flags.syncLevel > 0:
    write(&", {defMethod.flags.syncLevel}")
  writeln(") {")
  indent:
    for termObj in defMethod.terms:
      visit(termObj)
  indwriteln("}")

## TermArg kinds
##   ExpressionOpcode | DataObject | ArgObj | LocalObj | NamedString

proc visit(dataObject: DataObject) =
  case dataObject.kind:
  of doComputationalData:
    visit(dataObject.compData)

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

proc visit(defAcquire: DefAcquire) =
  indwrite(&"Acquire (")
  visit(defAcquire.mutex)
  writeln(&")")

proc visit(defAnd: DefAnd) =
  write(&"And (")
  visit(defAnd.operand1)
  write(&", ")
  visit(defAnd.operand2)
  if defAnd.target.kind != tgNullName:
    write(&", ")
    visit(defAnd.target)
  write(&")")

proc visit(defBuffer: DefBuffer) =
    case defBuffer.kind:
    of bpBytes:
      let uuid = toUuid(defBuffer.bytes)
      if uuid.isSome:
        write(&"\"{uuid.get}\"")
      else:
        write(&"Buffer (")
        for i, b in defBuffer.bytes:
          write(&"{b:02x}")
          if i < defBuffer.bytes.high:
            write(" ")
        write(&")")

    of bpResourceDesc:
      visit(defBuffer.resourceDesc)

proc visit(defToHexString: DefToHexString) =
  indwrite(&"ToHexString (")
  visit(defToHexString.operand)
  write(&", ")
  visit(defToHexString.target)
  writeln(&")")

proc visit(defToBuffer: DefToBuffer) =
  indwrite(&"ToBuffer (")
  visit(defToBuffer.operand)
  write(&", ")
  visit(defToBuffer.target)
  writeln(&")")

proc visit(defSubtract: DefSubtract) =
  indwrite(&"Subtract (")
  visit(defSubtract.operand1)
  write(&", ")
  visit(defSubtract.operand2)
  write(&", ")
  visit(defSubtract.target)
  writeln(&")")

proc visit(defSizeOf: DefSizeOf) =
  write(&"SizeOf (")
  visit(defSizeOf.name)
  write(&")")

proc visit(defStore: DefStore) =
  indwrite(&"Store (")
  visit(defStore.src)
  write(&", ")
  visit(defStore.dst)
  writeln(&")")

proc visit(defLEqual: DefLEqual) =
  write(&"LEqual (")
  visit(defLEqual.operand1)
  write(&", ")
  visit(defLEqual.operand2)
  write(&")")

proc visit(defLLess: DefLLess) =
  write(&"LLess (")
  visit(defLLess.operand1)
  write(&", ")
  visit(defLLess.operand2)
  write(&")")

proc visit(defLNot: DefLNot) =
  write(&"LNot (")
  visit(defLNot.operand)
  write(&")")

proc visit(defLOr: DefLOr) =
  write(&"LOr (")
  visit(defLOr.operand1)
  write(&", ")
  visit(defLOr.operand2)
  write(&")")

proc visit(defOr: DefOr) =
  write(&"Or (")
  visit(defOr.operand1)
  write(&", ")
  visit(defOr.operand2)
  if defOr.target.kind != tgNullName:
    write(&", ")
    visit(defOr.target)
  write(&")")

proc visit(defIndex: DefIndex) =
  write(&"Index (")
  visit(defIndex.src)
  write(&", ")
  visit(defIndex.idx)
  if defIndex.dst.kind != tgNullName:
    write(&", ")
    visit(defIndex.dst)
  write(&")")

proc visit(defDerefOf: DefDerefOf) =
  write(&"DerefOf (")
  visit(defDerefOf.src)
  write(&")")

proc visit(defIncrement: DefIncrement) =
  indwrite(&"Increment (")
  visit(defIncrement.addend)
  writeln(&")")

proc visit(defShiftLeft: DefShiftLeft) =
  write(&"ShiftLeft (")
  visit(defShiftLeft.operand)
  write(&", ")
  visit(defShiftLeft.count)
  if defShiftLeft.target.kind != tgNullName:
    write(&", ")
    visit(defShiftLeft.target)
  write(&")")

proc visit(methodInvocation: MethodInvocation) =
  write(&"{methodInvocation.name} (")
  for (i, arg) in methodInvocation.args.pairs:
    visit(arg)
    if i < methodInvocation.args.high:
      write(&", ")
  write(&")")

## Resource Descriptors

proc visit(resourceDesc: ResourceDescriptor) =
  writeln("ResourceTemplate ()")
  indwriteln("{")
  indent:
    case resourceDesc.kind:
    of rdReserved: discard
    of rdDWordAddressSpace:
      visit(resourceDesc.dwordAddrSpace)
  indwrite("}")

proc visit(dwordAddrSpace: DWordAddrSpaceDesc) =
  # resType        : ResourceType
  # addrSpaceFlags : AddressSpaceFlags
  # memFlags       : MemorySpecificFlags
  # granularity:                  uint32
  # minAddr:                      uint32
  # maxAddr:                      uint32
  # translationOffset:            uint32
  # addressLength:                uint32
  indwriteln("DWordSpace (")
  indent:
    indwriteln(&"  {dwordAddrSpace.resType: 20} # (_RT ) ResourceType")
    indwriteln(&", {dwordAddrSpace.addrSpaceFlags.decodeType: 20} # (_DEC) Decode")
    indwriteln(&", {dwordAddrSpace.addrSpaceFlags.minFixed: 20} # (_MIF) MinType")
    indwriteln(&", {dwordAddrSpace.addrSpaceFlags.maxFixed: 20} # (_MAF) MaxType")
    indwriteln(&", {dwordAddrSpace.memFlags.readWrite: 20} # (_TSF._RW ) Memory: Write Status")
    indwriteln(&", {dwordAddrSpace.memFlags.memAttrs: 20} # (_TSF._MEM) Memory: Cacheability")
    indwriteln(&", {dwordAddrSpace.memFlags.memType: 20} # (_TSF._MTP) Memory: Type")
    indwriteln(&", {dwordAddrSpace.memFlags.memIOTrans: 20} # (_TFS._TTP) Memory: Memory to I/O Translation")
    indwriteln(&", {dwordAddrSpace.granularity: <20x} # (_GRA) AddressGranularity")
    indwriteln(&", {dwordAddrSpace.minAddr: <20x} # (_MIN) MinAddress")
    indwriteln(&", {dwordAddrSpace.maxAddr: <20x} # (_MAX) MaxAddress")
    indwriteln(&", {dwordAddrSpace.translationOffset: <20x} # (_TRA) AddressTranslation (Offset)")
    indwriteln(&", {dwordAddrSpace.addressLength: <20x} # (_LEN) AddressLength")
  indwriteln(")")

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
  indwrite("If (")
  visit(defIfElse.predicate)
  writeln(") {")
  indent:
    for termObj in defIfElse.ifBody:
      visit(termObj)
  indwriteln("}")
  if defIfElse.elseBody.isSome:
    indwriteln("Else {")
    indent:
      for termObj in defIfElse.elseBody.get:
        visit(termObj)
    indwriteln("}")

proc visit(defRelease: DefRelease) =
  indwrite("Release (")
  visit(defRelease.mutex)
  writeln(")")

proc visit(defReturn: DefReturn) =
  indwrite("Return (")
  visit(defReturn.arg)
  writeln(")")

proc visit(defWhile: DefWhile) =
  indwrite("While (")
  visit(defWhile.predicate)
  writeln(") {")
  indent:
    for termObj in defWhile.body:
      visit(termObj)
  indwriteln("}")

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
    write(&"0x{compData.byteConst:0X}")
  of cdWordConst:
    write(&"0x{compData.wordConst:0X}")
  of cdDWordConst:
    let eisaId = toEisaId(compData.dwordConst)
    if eisaId.isSome:
      write(eisaId.get)
    else:
      write(&"0x{compData.dwordConst:X}")
  of cdString:
    write(&"\"{compData.str}\"")
  of cdConstObj:
    visit(compData.constObj)
  of cdDefBuffer:
    visit(compData.defBuffer)

proc visit(constObj: ConstObj) =
  case constObj:
  of coZero:
    write("Zero")
  of coOne:
    write("One")
  of coOnes:
    write("Ones")

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
    write(termArg.name)

proc visit(argObj: ArgObj) =
  case argObj
  of aoArg0:
    write("Arg0")
  of aoArg1:
    write("Arg1")
  of aoArg2:
    write("Arg2")
  of aoArg3:
    write("Arg3")
  of aoArg4:
    write("Arg4")
  of aoArg5:
    write("Arg5")
  of aoArg6:
    write("Arg6")

proc visit(localObj: LocalObj) =
  case localObj
  of loLocal0:
    write("Local0")
  of loLocal1:
    write("Local1")
  of loLocal2:
    write("Local2")
  of loLocal3:
    write("Local3")
  of loLocal4:
    write("Local4")
  of loLocal5:
    write("Local5")
  of loLocal6:
    write("Local6")
  of loLocal7:
    write("Local7")

proc visit(target: Target) =
  if target.kind != tgNullName:
    visit(target.superName)

proc visit(superName: SuperName) =
  case superName.kind:
  of snSimpleName:
    visit(superName.simpleName)

proc visit(simpleName: SimpleName) =
  case simpleName.kind:
  of snName:
    write(simpleName.name)
  of snArg:
    visit(simpleName.arg)
  of snLocal:
    visit(simpleName.local)
