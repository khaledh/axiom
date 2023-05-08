proc cmpxchg*(toChange: var bool, oldValue: bool, newValue: bool): bool {.inline.} =
  asm """
    lock ; cmpxchg %0, %2
    : "+m"(*`toChange`), "+a"(`oldValue`)
    : "r"(`newValue`)
    : "memory"
  """
  result = oldValue
