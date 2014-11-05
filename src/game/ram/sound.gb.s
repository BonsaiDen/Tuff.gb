SECTION "SoundRam",WRAM0[$CB00]; must be aligned at 256 bytes for soundChannelState


; Ram Buffers (must all be aligned)--------------------------------------------
soundTracksData:                DS 6 * 8; 6 tracks a 8 bytes

TrackFlags                      EQU $00; 7:Playing 6:Looping 5:Unused
TrackTempo                      EQU $00; 4-0:Tempo
TrackActiveChannel              EQU $01; 7-5:Channel
TrackTickCount                  EQU $01; 4-0:TickCount
PatternPointer                  EQU $02
IndexPointer                    EQU $04
DataPointer                     EQU $06


; Sound Channel State (not the register state) --------------------------------
soundChannelsData:              DS 4 * 8; 4 channels a 8 bytes

Channel1FlagsFreqHi             EQU soundChannelsData
Channel1FreqLo                  EQU soundChannelsData + 1
Channel1Sweep                   EQU soundChannelsData + 2 
Channel1LengthDuty              EQU soundChannelsData + 3 
Channel1Envelope                EQU soundChannelsData + 4 

Channel2FlagsFreqHi             EQU soundChannelsData + 8
Channel2FreqLo                  EQU soundChannelsData + 9
Channel2LengthDuty              EQU soundChannelsData + 10
Channel2Envelope                EQU soundChannelsData + 11

Channel3FlagsFreqHi             EQU soundChannelsData + 16
Channel3FreqLo                  EQU soundChannelsData + 17
Channel3Length                  EQU soundChannelsData + 18
Channel3OutputLevel             EQU soundChannelsData + 19
Channel3SampleIndex             EQU soundChannelsData + 20

Channel4Flags                   EQU soundChannelsData + 24
Channel4FreqLo                  EQU soundChannelsData + 25
Channel4Length                  EQU soundChannelsData + 26
Channel4Envelope                EQU soundChannelsData + 27
Channel4Polynomial              EQU soundChannelsData + 28


; Sound Engine State ----------------------------------------------------------
soundEnabled:                   DB
soundWavePatternIndex:          DB

