import uefitypes
import ../kernel/debug
import ../kernel/devices/console
import ../kernel/main
import ../lib/[libc, malloc]


proc printError(msg: string) {.gcsafe.} =
  debugln("printError: ", msg)
  # writeln(msg)

proc handleUnhandledException(e: ref Exception) {.tags: [], raises: [].} =
  debugln("Unhandled Exception: ", e.msg)
  printError(e.msg)

errorMessageWriter = printError
unhandledExceptionHook = handleUnhandledException

proc NimMain() {.cdecl, importc.}

proc efiMain*(imageHandle: EfiHandle, systemTable: ptr EfiSystemTable): uint {.exportc.} =
  NimMain()

  var sysTable = systemTable

  debug.init(sysTable.conOut)

  discard sysTable.conOut.setMode(sysTable.conOut, 2)

  # discard sysTable.conOut.clearScreen(systemTable.conOut)
  # discard sysTable.conOut.enableCursor(systemTable.conOut, true)
  # discard sysTable.conOut.enableCursor(systemTable.conOut, false)

  # when false:

  # let GOP_GUID = parseGuid("9042a9de-23dc-4a38-fb96-7aded080516a")
  # var igop: pointer
  # discard sysTable.bootServices.locateProtocol(unsafeAddr GOP_GUID, nil, addr igop)
  # var gop = cast[ptr EfiGraphicsOutputProtocol](igop)
  # showGop(gop)

  # discard gop.setMode(gop, 14)  # 1280x1024
  # var fb = initFramebuffer(gop.mode.frameBufferBase, width=1280, height=1024)

  main.init(sysTable)
