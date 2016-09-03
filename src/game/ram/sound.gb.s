SECTION "SoundRam",WRAM0[$CF00]; must be aligned at 256 bytes for soundChannelState


; Ram Buffers (must all be aligned)--------------------------------------------
soundTracksData:                DS 6 * 8; 6 tracks a 8 bytes

TrackFlags                      EQU $00; 7:Playing 6:Looping 5:Unused
TrackTempo                      EQU $00; 4-0:Tempo
TrackActiveChannel              EQU $01; 7-5:Channel
TrackTickCount                  EQU $01; 4-0:TickCount
TrackPatternPointer             EQU $02
TrackIndexPointer               EQU $04
TrackDataPointer                EQU $06


; Sound Channel State (not the register state) --------------------------------
soundChannelsData:
Channel1FlagsFreqHi:            DB
Channel1FreqLo:                 DB
Channel1Sweep:                  DB
Channel1LengthDuty:             DB
Channel1Envelope:               DB

Channel2FlagsFreqHi:            DB
Channel2FreqLo:                 DB
Channel2LengthDuty:             DB
Channel2Envelope:               DB
Channel3LastSampleIndex:        DB

Channel3FlagsFreqHi:            DB
Channel3FreqLo:                 DB
Channel3Length:                 DB
Channel3OutputLevel:            DB
Channel3SampleIndex:            DB

Channel4Flags:                  DB
Channel4FreqLo:                 DB
Channel4Length:                 DB
Channel4Envelope:               DB
Channel4Polynomial:             DB


; Sound Engine State ----------------------------------------------------------
soundEnabled:                   DB

