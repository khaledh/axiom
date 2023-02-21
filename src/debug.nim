import boot/uefitypes

var conOut: ptr SimpleTextOutputInterface

proc init*(outputInterface: ptr SimpleTextOutputInterface) =
  conOut = outputInterface

proc printws*(wstr: WideCString) =
  discard conOut.outputString(conOut, wstr[0].addr)

proc print*(str: string) =
  discard conOut.outputString(conOut, (newWideCString(str).toWideCString)[0].addr)

proc println*(str: string) =
  print(str & "\r\n")
