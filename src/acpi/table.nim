type
  TableDescriptionHeader* {.packed.} = object
    signature*: array[4, char]
    length*: uint32
    revision*: uint8
    checksum*: uint8
    oem_id*: array[6, char]
    oem_table_id*: array[8, char]
    oem_revision*: uint32
    creator_id*: array[4, uint8]
    creator_revision*: uint32
