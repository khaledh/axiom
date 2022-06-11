import std/strformat

import console
import cpu
import idt
import lapic


const
  kbdUs = [
    '\0', '\x1B', '1',  '2',  '3',  '4',  '5',  '6',  # 00-07
    '7',  '8',    '9',  '0',  '-',  '=',  '\b', '\t', # 08-0f
    'q',  'w',    'e',  'r',  't',  'y',  'u',  'i',  # 10-17
    'o',  'p',    '[',  ']',  '\n', '\0', 'a',  's',  # 18-1f
    'd',  'f',    'g',  'h',  'j',  'k',  'l',  ';',  # 20-27
    '\'', '`',    '\0', '\\', 'z',  'x',  'c',  'v',  # 28-2f
    'b',  'n',    'm',  ',',  '.',  '/',  '\0', '*',  # 30-37
    '\0', ' ',    '\0', '\0', '\0', '\0', '\0', '\0', # 38-3f
    '\0', '\0',   '\0', '\0', '\0', '\0', '\0', '7',  # 40-47
    '8',  '9',    '-',  '4',  '5',  '6',  '+',  '1',  # 48-4f
    '2',  '3',    '0',  '.',  '\0', '\0', '\0', '\0', # 50-57
    '\0',                                             # 58-5f
  ]
  kbdUsShift = [
    '\0', '\x1B', '!',  '@',  '#',  '$',  '%',  '^',  # 00-07
    '&',  '*',  '(',  ')',    '_',  '+',  '\b', '\t', # 08-0f
    'Q',  'W',  'E',  'R',    'T',  'Y',  'U',  'I',  # 10-17
    'O',  'P',  '{',  '}',    '\n', '\0', 'A',  'S',  # 18-1f
    'D',  'F',  'G',  'H',    'J',  'K',  'L',  ':',  # 20-27
    '"',  '~',  '\0', '|',    'Z',  'X',  'C',  'V',  # 28-2f
    'B',  'N',  'M',  '<',    '>',  '?'
  ]

type
  KeyEventType* = enum
    KeyDown
    KeyUp
  KeyEvent* = object
    eventType*: KeyEventType
    ch*: char
    shift*: bool
    ctrl*: bool
    alt*: bool
  KeyEventHandler* = proc (evt: KeyEvent)


var
  shift, ctrl, alt = false
  handleKeyEvent: KeyEventHandler

{.push stackTrace:off.}
proc kbdInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".}=

  var scanCode = portIn8(0x60)

  if (scanCode and 0x80) == 0:
    # key press down
    case scanCode
      of 0x2a, 0x36: shift = true
      of 0x1d: ctrl = true
      of 0x38: alt = true
      else:
        var ch: char = '\0'
        if shift and scanCode < kbdUsShift.len:
          ch = kbdUsShift[scanCode]
        elif scanCode < kbdUs.len:
          ch = kbdUs[scanCode]
        handleKeyEvent(KeyEvent(
          eventType: KeyDown,
          ch: ch,
          shift: shift,
          ctrl: ctrl,
          alt: alt,
        ))

  else:
    # key release
    scanCode = scanCode and (not 0x80'u8)
    case scanCode
      of 0x2a, 0x36: shift = false
      of 0x1d: ctrl = false
      of 0x38: alt = false
      else:
        var ch: char = '\0'
        if shift and scanCode < kbdUsShift.len:
          ch = kbdUsShift[scanCode]
        elif scanCode < kbdUs.len:
          ch = kbdUs[scanCode]
        handleKeyEvent(KeyEvent(
          eventType: KeyUp,
          ch: ch,
          shift: shift,
          ctrl: ctrl,
          alt: alt,
        ))

  lapic.eoi()
{.pop.}

proc initKeyboard*(handler: KeyEventHandler) =
  handleKeyEvent = handler
  # writeln("  Setting keyboard interrupt handler (0x21)")
  setInterruptHandler(0x21, kbdInterruptHandler)
