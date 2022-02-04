type
  IdentifyDeviceData* {.packed.} = object
    r00a                   {.bitsize:  2.} : uint16            # Word 0
    incomplete*            {.bitsize:  1.} : uint16
    r00b                   {.bitsize: 12.} : uint16
    ata*                   {.bitsize:  1.} : uint16
    r01a                                   : uint16            # Word 1
    specificConfig*                        : uint16            # Word 2
    r03_09                                 : array[7, uint16]  # Words 3-9
    serialNo*                              : array[20, char]   # Words 10-19
    r20_22                                 : array[3, uint16]  # Words 20-22
    firmwareRevision*                      : array[8, char]    # Words 23-26
    modelNo*                               : array[40, char]   # Words 27-46
    multipleCount*                         : uint8             # Word 47
    multipleCount80                        : uint8
    trustedComputing*                      : uint16            # Word 48
    capLpsaer*             {.bitsize:  2.} : uint16            # Word 49
    r49a                   {.bitsize:  6.} : uint16
    capDma*                {.bitsize:  1.} : uint16
    capLba*                {.bitsize:  1.} : uint16
    capIordyDisable*       {.bitsize:  1.} : uint16
    capIordySupport*       {.bitsize:  1.} : uint16
    r49b                   {.bitsize:  1.} : uint16
    capStandbyTimerStd*    {.bitsize:  1.} : uint16
    r49c                   {.bitsize:  2.} : uint16
    capMinStandbyTimerVal* {.bitsize:  1.} : uint16            # Word 50
    r50a                   {.bitsize: 15.} : uint16
    r51_52                                 : array[2, uint16]  # Words 51-52
    r53a                   {.bitsize:  1.} : uint16            # Word 53
    words64_70Valid*       {.bitsize:  1.} : uint16
    word80Valid*           {.bitsize:  1.} : uint16
    r53b                   {.bitsize: 13.} : uint16
    r54_58                                 : array[5, uint16]  # Words 54-58
    extCmdSupport*                         : uint16            # Word 59
    totalSectors*                          : uint32            # Words 60-61
    r62                                    : uint16            # Word 62
    multiwordDma0Support*  {.bitsize:  1.} : uint16            # Word 63
    multiwordDma1Support*  {.bitsize:  1.} : uint16
    multiwordDma2Support*  {.bitsize:  1.} : uint16
    r63a                   {.bitsize:  5.} : uint16
    multiwordDma0Select*   {.bitsize:  1.} : uint16
    multiwordDma1Select*   {.bitsize:  1.} : uint16
    multiwordDma2Select*   {.bitsize:  1.} : uint16
    r63b                   {.bitsize:  5.} : uint16
    pioMode34Support*      {.bitsize:  2.} : uint16            # Word 64
    r64a                   {.bitsize: 14.} : uint16
    minMwDmaCycleTimeNs                    : uint16            # Word 65
    recMwDmaCycleTimeNs                    : uint16            # Word 66
    minPioCycleTimeNs                      : uint16            # Word 67
    minPioIordyCycleTimeNs                 : uint16            # Word 68
    zonedCap*              {.bitsize:  2.} : uint16            # Word 69
    nonVolatileWriteCache* {.bitsize:  1.} : uint16
    extSectorsSupport*     {.bitsize:  1.} : uint16
    encryptData*           {.bitsize:  1.} : uint16
    trimmedLbaZeroedData*  {.bitsize:  1.} : uint16
    opt28BitCommands*      {.bitsize:  1.} : uint16
    r69a                   {.bitsize:  1.} : uint16
    downloadMicrocodeDma*  {.bitsize:  1.} : uint16
    r69b                   {.bitsize:  1.} : uint16
    writeBufferDma*        {.bitsize:  1.} : uint16
    readBufferDma*         {.bitsize:  1.} : uint16
    r69c                   {.bitsize:  1.} : uint16
    lpsaerc                {.bitsize:  1.} : uint16
    detDataTrimmedLbaRng*  {.bitsize:  1.} : uint16
    r69d                   {.bitsize:  1.} : uint16
    r70_74                                 : array[5, uint16]  # Words 70-74
    maxQueueDepth*         {.bitsize:  4.} : uint16            # Word 75
    r75a                   {.bitsize: 12.} : uint16
    r76a                   {.bitsize:  1.} : uint16            # Word 76
    sataGen1*              {.bitsize:  1.} : uint16
    sataGen2*              {.bitsize:  1.} : uint16
    sataGen3*              {.bitsize:  1.} : uint16
    r76b                   {.bitsize:  4.} : uint16
    sataNcq*               {.bitsize:  1.} : uint16
    sataHostIpm*           {.bitsize:  1.} : uint16
    sataPhyEventCounters*  {.bitsize:  1.} : uint16
    sataNcqUnload*         {.bitsize:  1.} : uint16
    sataNcqPriority*       {.bitsize:  1.} : uint16
    sataHostAutoP2S*       {.bitsize:  1.} : uint16
    sataDeviceAutoP2S*     {.bitsize:  1.} : uint16
    sataReadLogDmaExtEquiv*{.bitsize:  1.} : uint16
    
    tmp                                    : array[3, uint16] # Words ..-79
    r80a                   {.bitsize:  5.} : uint16           # Word 80
    ata5*                  {.bitsize:  1.} : uint16
    ata6*                  {.bitsize:  1.} : uint16
    ata7*                  {.bitsize:  1.} : uint16
    ata8acs*               {.bitsize:  1.} : uint16
    acs2*                  {.bitsize:  1.} : uint16
    acs3*                  {.bitsize:  1.} : uint16
    acs4*                  {.bitsize:  1.} : uint16
    r80b                   {.bitsize:  4.} : uint16
    minorVersion*                          : uint16            # Word 81
