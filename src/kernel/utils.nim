proc compare*(a, b: string): int =
  for i in 0 ..< min(a.len, b.len):
    if a[i] != b[i]:
      return a[i].int - b[i].int
  return a.len - b.len
