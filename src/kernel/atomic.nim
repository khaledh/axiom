proc cmpxchg*(toChange: var bool, oldValue: bool, newValue: bool): bool {.inline.} =
  asm """
    lock cmpxchg %0, %3
    : "+m"(*`toChange`), "=a"(`result`)
    : "a"(`oldValue`), "r"(`newValue`)
    : "memory"
  """
