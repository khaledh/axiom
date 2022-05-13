import std/strformat

import cpu
import debug

const
  StackSize = 1024

type
  Stack = ref array[StackSize, uint64]

  Thread* = ref object
    rsp: uint64
    stack: Stack

  ThreadFunc* = proc () {.cdecl.}

  SwitchStack* {.packed.} = object
    r15: uint64
    r14: uint64
    r13: uint64
    r12: uint64
    r11: uint64
    r10: uint64
    r9: uint64
    r8: uint64
    rdi: uint64
    rsi: uint64
    rbp: uint64
    rbx: uint64
    rdx: uint64
    rcx: uint64
    rax: uint64
    rip: pointer

var
  threads: array[3, Thread]
  currThreadId: int

proc contextSwitch*(oldThread, newThread: Thread) {.asmNoStackFrame.} =
  asm """
    push    rax
    push    rcx
    push    rdx
    push    rbx
    push    rbp
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15

    # switch stacks
    mov     [rcx], rsp
    mov     rsp, [rdx]

    jmp resumeThread
  """

proc resumeThread*() {.asmNoStackFrame, exportc.} =
  asm """
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rbp
    pop     rbx
    pop     rdx
    pop     rcx
    pop     rax

    sti
    ret
  """

proc schedule() =
  let curr = currThreadId
  let next = (curr + 1) mod len(threads)

  currThreadId = next
  contextSwitch(threads[curr], threads[next])

proc thread1() {.cdecl.} =
  while true:
    for x in 0..<10:
      print(".")
      for i in 0..250000:
        asm "pause"
    schedule()

proc thread2() {.cdecl.} =
  while true:
    for x in 0..<10:
      print("x")
      for i in 0..250000:
        asm "pause"
    schedule()

proc thread3() {.cdecl.} =
  while true:
    for x in 0..<10:
      print("o")
      for i in 0..250000:
        asm "pause"
    schedule()

proc kernelThread(function: ThreadFunc) =
  function()
  println("Halt")
  halt()

proc initThread(function: ThreadFunc): Thread =
  result = new(Thread)
  result.stack = new(Stack)
  result.rsp = cast[uint64](result.stack) + StackSize - sizeof(SwitchStack).uint64

  var ss = cast[ptr SwitchStack](result.rsp)
  ss.r15 = 0
  ss.r14 = 0
  ss.r13 = 0
  ss.r12 = 0
  ss.r11 = 0
  ss.r10 = 0
  ss.r9  = 0
  ss.r8  = 0
  ss.rdi = 0
  ss.rsi = 0
  ss.rbp = 0
  ss.rbx = 0
  ss.rdx = 0
  ss.rcx = cast[uint64](function)
  ss.rax = 0
  ss.rip = cast[pointer](kernelThread)

proc runThread(thread: Thread) =
  asm """
    mov rsp, %0
    jmp resumeThread
    :
    :"g"(`thread->rsp`)
  """

proc initThreads*() =
  println("")
  threads[0] = initThread(thread1)
  threads[1] = initThread(thread2)
  threads[2] = initThread(thread3)

  currThreadId = 0
  runThread(threads[0])
