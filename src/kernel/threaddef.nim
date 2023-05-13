import std/strformat

const
  StackSize = 512

type
  ThreadStackArray* = array[StackSize, uint64]
  ThreadStack* = ref ThreadStackArray

  ThreadState* = enum
    tsNew
    tsReady
    tsRunning
    tsBlocked
    tsSleeping
    tsTerminated

  ThreadPriority* = -7..8

  Thread* = ref object
    rsp*: uint64
    id*: uint64
    name*: string
    prev*: Thread
    next*: Thread
    stack*: ThreadStack
    priority*: ThreadPriority
    state*: ThreadState
    sleepUntil*: uint64

  ThreadFunc* = proc () {.cdecl.}

  SwitchStack* {.packed.} = object
    r15*: uint64
    r14*: uint64
    r13*: uint64
    r12*: uint64
    r11*: uint64
    r10*: uint64
    r9*: uint64
    r8*: uint64
    rdi*: uint64
    rsi*: uint64
    rbp*: uint64
    rbx*: uint64
    rdx*: uint64
    rcx*: uint64
    rax*: uint64
    rip*: uint64

# we want heap[0] to contian the thread with highest priority
# so we invert the inequality here
proc `<`*(a, b: Thread): bool = a.priority > b.priority

proc `$`*(t: Thread): string =
  result = &"Thread({t.id}, '{t.name}', pri={t.priority}, state={t.state})"
