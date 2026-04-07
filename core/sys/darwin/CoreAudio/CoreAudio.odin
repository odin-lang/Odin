#+build darwin
package CoreAudio

import    "core:c"
import CF "core:sys/darwin/CoreFoundation"

foreign import lib "system:CoreAudio.framework"

AUTH_OPEN_NOAUTHFD :: 1

k_NoError                                                       :: 0
k_UnimplementedError                                            :: -4
k_FileNotFoundError                                             :: -43
k_FilePermissionError                                           :: -54
k_TooManyFilesOpenError                                         :: -42
k_BadFilePathError                                              :: 561017960
k_ParamError                                                    :: -50
k_MemFullError                                                  :: -108
kFormatLinearPCM                                                :: 1819304813
kFormatAC3                                                      :: 1633889587
kFormat60958AC3                                                 :: 1667326771
kFormatAppleIMA4                                                :: 1768775988
kFormatMPEG4AAC                                                 :: 1633772320
kFormatMPEG4CELP                                                :: 1667591280
kFormatMPEG4HVXC                                                :: 1752594531
kFormatMPEG4TwinVQ                                              :: 1953986161
kFormatMACE3                                                    :: 1296122675
kFormatMACE6                                                    :: 1296122678
kFormatULaw                                                     :: 1970037111
kFormatALaw                                                     :: 1634492791
kFormatQDesign                                                  :: 1363430723
kFormatQDesign2                                                 :: 1363430706
kFormatQUALCOMM                                                 :: 1365470320
kFormatMPEGLayer1                                               :: 778924081
kFormatMPEGLayer2                                               :: 778924082
kFormatMPEGLayer3                                               :: 778924083
kFormatTimeCode                                                 :: 1953066341
kFormatMIDIStream                                               :: 1835623529
kFormatParameterValueStream                                     :: 1634760307
kFormatAppleLossless                                            :: 1634492771
kFormatMPEG4AAC_HE                                              :: 1633772392
kFormatMPEG4AAC_LD                                              :: 1633772396
kFormatMPEG4AAC_ELD                                             :: 1633772389
kFormatMPEG4AAC_ELD_SBR                                         :: 1633772390
kFormatMPEG4AAC_ELD_V2                                          :: 1633772391
kFormatMPEG4AAC_HE_V2                                           :: 1633772400
kFormatMPEG4AAC_Spatial                                         :: 1633772403
kFormatMPEGD_USAC                                               :: 1970495843
kFormatAMR                                                      :: 1935764850
kFormatAMR_WB                                                   :: 1935767394
kFormatAudible                                                  :: 1096107074
kFormatiLBC                                                     :: 1768710755
kFormatDVIIntelIMA                                              :: 1836253201
kFormatMicrosoftGSM                                             :: 1836253233
kFormatAES3                                                     :: 1634038579
kFormatEnhancedAC3                                              :: 1700998451
kFormatFLAC                                                     :: 1718378851
kFormatOpus                                                     :: 1869641075
kFormatAPAC                                                     :: 1634754915
kFormatFlagIsFloat                                              :: 1
kFormatFlagIsBigEndian                                          :: 2
kFormatFlagIsSignedInteger                                      :: 4
kFormatFlagIsPacked                                             :: 8
kFormatFlagIsAlignedHigh                                        :: 16
kFormatFlagIsNonInterleaved                                     :: 32
kFormatFlagIsNonMixable                                         :: 64
kFormatFlagsAreAllClear                                         :: 2147483648
kFormatFlagsNativeEndian                                        :: 0
kFormatFlagsCanonical                                           :: 9
kFormatFlagsAudioUnitCanonical                                  :: 41
kFormatFlagsNativeFloatPacked                                   :: 9
kChannelLabel_Unknown                                           :: 4294967295
kChannelLabel_Unused                                            :: 0
kChannelLabel_UseCoordinates                                    :: 100
kChannelLabel_Left                                              :: 1
kChannelLabel_Right                                             :: 2
kChannelLabel_Center                                            :: 3
kChannelLabel_LFEScreen                                         :: 4
kChannelLabel_LeftSurround                                      :: 5
kChannelLabel_RightSurround                                     :: 6
kChannelLabel_LeftCenter                                        :: 7
kChannelLabel_RightCenter                                       :: 8
kChannelLabel_CenterSurround                                    :: 9
kChannelLabel_LeftSurroundDirect                                :: 10
kChannelLabel_RightSurroundDirect                               :: 11
kChannelLabel_TopCenterSurround                                 :: 12
kChannelLabel_VerticalHeightLeft                                :: 13
kChannelLabel_VerticalHeightCenter                              :: 14
kChannelLabel_VerticalHeightRight                               :: 15
kChannelLabel_TopBackLeft                                       :: 16
kChannelLabel_TopBackCenter                                     :: 17
kChannelLabel_TopBackRight                                      :: 18
kChannelLabel_RearSurroundLeft                                  :: 33
kChannelLabel_RearSurroundRight                                 :: 34
kChannelLabel_LeftWide                                          :: 35
kChannelLabel_RightWide                                         :: 36
kChannelLabel_LFE2                                              :: 37
kChannelLabel_LeftTotal                                         :: 38
kChannelLabel_RightTotal                                        :: 39
kChannelLabel_HearingImpaired                                   :: 40
kChannelLabel_Narration                                         :: 41
kChannelLabel_Mono                                              :: 42
kChannelLabel_DialogCentricMix                                  :: 43
kChannelLabel_CenterSurroundDirect                              :: 44
kChannelLabel_Haptic                                            :: 45
kChannelLabel_LeftTopFront                                      :: 13
kChannelLabel_CenterTopFront                                    :: 14
kChannelLabel_RightTopFront                                     :: 15
kChannelLabel_LeftTopMiddle                                     :: 49
kChannelLabel_CenterTopMiddle                                   :: 12
kChannelLabel_RightTopMiddle                                    :: 51
kChannelLabel_LeftTopRear                                       :: 52
kChannelLabel_CenterTopRear                                     :: 53
kChannelLabel_RightTopRear                                      :: 54
kChannelLabel_LeftSideSurround                                  :: 55
kChannelLabel_RightSideSurround                                 :: 56
kChannelLabel_LeftBottom                                        :: 57
kChannelLabel_RightBottom                                       :: 58
kChannelLabel_CenterBottom                                      :: 59
kChannelLabel_LeftTopSurround                                   :: 60
kChannelLabel_RightTopSurround                                  :: 61
kChannelLabel_LFE3                                              :: 62
kChannelLabel_LeftBackSurround                                  :: 63
kChannelLabel_RightBackSurround                                 :: 64
kChannelLabel_LeftEdgeOfScreen                                  :: 65
kChannelLabel_RightEdgeOfScreen                                 :: 66
kChannelLabel_Ambisonic_W                                       :: 200
kChannelLabel_Ambisonic_X                                       :: 201
kChannelLabel_Ambisonic_Y                                       :: 202
kChannelLabel_Ambisonic_Z                                       :: 203
kChannelLabel_MS_Mid                                            :: 204
kChannelLabel_MS_Side                                           :: 205
kChannelLabel_XY_X                                              :: 206
kChannelLabel_XY_Y                                              :: 207
kChannelLabel_BinauralLeft                                      :: 208
kChannelLabel_BinauralRight                                     :: 209
kChannelLabel_HeadphonesLeft                                    :: 301
kChannelLabel_HeadphonesRight                                   :: 302
kChannelLabel_ClickTrack                                        :: 304
kChannelLabel_ForeignLanguage                                   :: 305
kChannelLabel_Discrete                                          :: 400
kChannelLabel_Discrete_0                                        :: 65536
kChannelLabel_Discrete_1                                        :: 65537
kChannelLabel_Discrete_2                                        :: 65538
kChannelLabel_Discrete_3                                        :: 65539
kChannelLabel_Discrete_4                                        :: 65540
kChannelLabel_Discrete_5                                        :: 65541
kChannelLabel_Discrete_6                                        :: 65542
kChannelLabel_Discrete_7                                        :: 65543
kChannelLabel_Discrete_8                                        :: 65544
kChannelLabel_Discrete_9                                        :: 65545
kChannelLabel_Discrete_10                                       :: 65546
kChannelLabel_Discrete_11                                       :: 65547
kChannelLabel_Discrete_12                                       :: 65548
kChannelLabel_Discrete_13                                       :: 65549
kChannelLabel_Discrete_14                                       :: 65550
kChannelLabel_Discrete_15                                       :: 65551
kChannelLabel_Discrete_65535                                    :: 131071
kChannelLabel_HOA_ACN                                           :: 500
kChannelLabel_HOA_ACN_0                                         :: 131072
kChannelLabel_HOA_ACN_1                                         :: 131073
kChannelLabel_HOA_ACN_2                                         :: 131074
kChannelLabel_HOA_ACN_3                                         :: 131075
kChannelLabel_HOA_ACN_4                                         :: 131076
kChannelLabel_HOA_ACN_5                                         :: 131077
kChannelLabel_HOA_ACN_6                                         :: 131078
kChannelLabel_HOA_ACN_7                                         :: 131079
kChannelLabel_HOA_ACN_8                                         :: 131080
kChannelLabel_HOA_ACN_9                                         :: 131081
kChannelLabel_HOA_ACN_10                                        :: 131082
kChannelLabel_HOA_ACN_11                                        :: 131083
kChannelLabel_HOA_ACN_12                                        :: 131084
kChannelLabel_HOA_ACN_13                                        :: 131085
kChannelLabel_HOA_ACN_14                                        :: 131086
kChannelLabel_HOA_ACN_15                                        :: 131087
kChannelLabel_HOA_ACN_65024                                     :: 196096
kChannelLabel_HOA_SN3D                                          :: 131072
kChannelLabel_HOA_N3D                                           :: 196608
kChannelLabel_Object                                            :: 262144
kChannelLabel_BeginReserved                                     :: 4026531840
kChannelLabel_EndReserved                                       :: 4294967294
kChannelLayoutTag_UseChannelDescriptions                        :: 0
kChannelLayoutTag_UseChannelBitmap                              :: 65536
kChannelLayoutTag_Mono                                          :: 6553601
kChannelLayoutTag_Stereo                                        :: 6619138
kChannelLayoutTag_StereoHeadphones                              :: 6684674
kChannelLayoutTag_MatrixStereo                                  :: 6750210
kChannelLayoutTag_MidSide                                       :: 6815746
kChannelLayoutTag_XY                                            :: 6881282
kChannelLayoutTag_Binaural                                      :: 6946818
kChannelLayoutTag_Ambisonic_B_Format                            :: 7012356
kChannelLayoutTag_Quadraphonic                                  :: 7077892
kChannelLayoutTag_Pentagonal                                    :: 7143429
kChannelLayoutTag_Hexagonal                                     :: 7208966
kChannelLayoutTag_Octagonal                                     :: 7274504
kChannelLayoutTag_Cube                                          :: 7340040
kChannelLayoutTag_MPEG_1_0                                      :: 6553601
kChannelLayoutTag_MPEG_2_0                                      :: 6619138
kChannelLayoutTag_MPEG_3_0_A                                    :: 7405571
kChannelLayoutTag_MPEG_3_0_B                                    :: 7471107
kChannelLayoutTag_MPEG_4_0_A                                    :: 7536644
kChannelLayoutTag_MPEG_4_0_B                                    :: 7602180
kChannelLayoutTag_MPEG_5_0_A                                    :: 7667717
kChannelLayoutTag_MPEG_5_0_B                                    :: 7733253
kChannelLayoutTag_MPEG_5_0_C                                    :: 7798789
kChannelLayoutTag_MPEG_5_0_D                                    :: 7864325
kChannelLayoutTag_MPEG_5_1_A                                    :: 7929862
kChannelLayoutTag_MPEG_5_1_B                                    :: 7995398
kChannelLayoutTag_MPEG_5_1_C                                    :: 8060934
kChannelLayoutTag_MPEG_5_1_D                                    :: 8126470
kChannelLayoutTag_MPEG_6_1_A                                    :: 8192007
kChannelLayoutTag_MPEG_7_1_A                                    :: 8257544
kChannelLayoutTag_MPEG_7_1_B                                    :: 8323080
kChannelLayoutTag_MPEG_7_1_C                                    :: 8388616
kChannelLayoutTag_Emagic_Default_7_1                            :: 8454152
kChannelLayoutTag_SMPTE_DTV                                     :: 8519688
kChannelLayoutTag_ITU_1_0                                       :: 6553601
kChannelLayoutTag_ITU_2_0                                       :: 6619138
kChannelLayoutTag_ITU_2_1                                       :: 8585219
kChannelLayoutTag_ITU_2_2                                       :: 8650756
kChannelLayoutTag_ITU_3_0                                       :: 7405571
kChannelLayoutTag_ITU_3_1                                       :: 7536644
kChannelLayoutTag_ITU_3_2                                       :: 7667717
kChannelLayoutTag_ITU_3_2_1                                     :: 7929862
kChannelLayoutTag_ITU_3_4_1                                     :: 8388616
kChannelLayoutTag_DVD_0                                         :: 6553601
kChannelLayoutTag_DVD_1                                         :: 6619138
kChannelLayoutTag_DVD_2                                         :: 8585219
kChannelLayoutTag_DVD_3                                         :: 8650756
kChannelLayoutTag_DVD_4                                         :: 8716291
kChannelLayoutTag_DVD_5                                         :: 8781828
kChannelLayoutTag_DVD_6                                         :: 8847365
kChannelLayoutTag_DVD_7                                         :: 7405571
kChannelLayoutTag_DVD_8                                         :: 7536644
kChannelLayoutTag_DVD_9                                         :: 7667717
kChannelLayoutTag_DVD_10                                        :: 8912900
kChannelLayoutTag_DVD_11                                        :: 8978437
kChannelLayoutTag_DVD_12                                        :: 7929862
kChannelLayoutTag_DVD_13                                        :: 7536644
kChannelLayoutTag_DVD_14                                        :: 7667717
kChannelLayoutTag_DVD_15                                        :: 8912900
kChannelLayoutTag_DVD_16                                        :: 8978437
kChannelLayoutTag_DVD_17                                        :: 7929862
kChannelLayoutTag_DVD_18                                        :: 9043973
kChannelLayoutTag_DVD_19                                        :: 7733253
kChannelLayoutTag_DVD_20                                        :: 7995398
kChannelLayoutTag_AudioUnit_4                                   :: 7077892
kChannelLayoutTag_AudioUnit_5                                   :: 7143429
kChannelLayoutTag_AudioUnit_6                                   :: 7208966
kChannelLayoutTag_AudioUnit_8                                   :: 7274504
kChannelLayoutTag_AudioUnit_5_0                                 :: 7733253
kChannelLayoutTag_AudioUnit_6_0                                 :: 9109510
kChannelLayoutTag_AudioUnit_7_0                                 :: 9175047
kChannelLayoutTag_AudioUnit_7_0_Front                           :: 9699335
kChannelLayoutTag_AudioUnit_5_1                                 :: 7929862
kChannelLayoutTag_AudioUnit_6_1                                 :: 8192007
kChannelLayoutTag_AudioUnit_7_1                                 :: 8388616
kChannelLayoutTag_AudioUnit_7_1_Front                           :: 8257544
kChannelLayoutTag_AAC_3_0                                       :: 7471107
kChannelLayoutTag_AAC_Quadraphonic                              :: 7077892
kChannelLayoutTag_AAC_4_0                                       :: 7602180
kChannelLayoutTag_AAC_5_0                                       :: 7864325
kChannelLayoutTag_AAC_5_1                                       :: 8126470
kChannelLayoutTag_AAC_6_0                                       :: 9240582
kChannelLayoutTag_AAC_6_1                                       :: 9306119
kChannelLayoutTag_AAC_7_0                                       :: 9371655
kChannelLayoutTag_AAC_7_1                                       :: 8323080
kChannelLayoutTag_AAC_7_1_B                                     :: 11993096
kChannelLayoutTag_AAC_7_1_C                                     :: 12058632
kChannelLayoutTag_AAC_Octagonal                                 :: 9437192
kChannelLayoutTag_TMH_10_2_std                                  :: 9502736
kChannelLayoutTag_TMH_10_2_full                                 :: 9568277
kChannelLayoutTag_AC3_1_0_1                                     :: 9764866
kChannelLayoutTag_AC3_3_0                                       :: 9830403
kChannelLayoutTag_AC3_3_1                                       :: 9895940
kChannelLayoutTag_AC3_3_0_1                                     :: 9961476
kChannelLayoutTag_AC3_2_1_1                                     :: 10027012
kChannelLayoutTag_AC3_3_1_1                                     :: 10092549
kChannelLayoutTag_EAC_6_0_A                                     :: 10158086
kChannelLayoutTag_EAC_7_0_A                                     :: 10223623
kChannelLayoutTag_EAC3_6_1_A                                    :: 10289159
kChannelLayoutTag_EAC3_6_1_B                                    :: 10354695
kChannelLayoutTag_EAC3_6_1_C                                    :: 10420231
kChannelLayoutTag_EAC3_7_1_A                                    :: 10485768
kChannelLayoutTag_EAC3_7_1_B                                    :: 10551304
kChannelLayoutTag_EAC3_7_1_C                                    :: 10616840
kChannelLayoutTag_EAC3_7_1_D                                    :: 10682376
kChannelLayoutTag_EAC3_7_1_E                                    :: 10747912
kChannelLayoutTag_EAC3_7_1_F                                    :: 10813448
kChannelLayoutTag_EAC3_7_1_G                                    :: 10878984
kChannelLayoutTag_EAC3_7_1_H                                    :: 10944520
kChannelLayoutTag_DTS_3_1                                       :: 11010052
kChannelLayoutTag_DTS_4_1                                       :: 11075589
kChannelLayoutTag_DTS_6_0_A                                     :: 11141126
kChannelLayoutTag_DTS_6_0_B                                     :: 11206662
kChannelLayoutTag_DTS_6_0_C                                     :: 11272198
kChannelLayoutTag_DTS_6_1_A                                     :: 11337735
kChannelLayoutTag_DTS_6_1_B                                     :: 11403271
kChannelLayoutTag_DTS_6_1_C                                     :: 11468807
kChannelLayoutTag_DTS_7_0                                       :: 11534343
kChannelLayoutTag_DTS_7_1                                       :: 11599880
kChannelLayoutTag_DTS_8_0_A                                     :: 11665416
kChannelLayoutTag_DTS_8_0_B                                     :: 11730952
kChannelLayoutTag_DTS_8_1_A                                     :: 11796489
kChannelLayoutTag_DTS_8_1_B                                     :: 11862025
kChannelLayoutTag_DTS_6_1_D                                     :: 11927559
kChannelLayoutTag_WAVE_2_1                                      :: 8716291
kChannelLayoutTag_WAVE_3_0                                      :: 7405571
kChannelLayoutTag_WAVE_4_0_A                                    :: 8650756
kChannelLayoutTag_WAVE_4_0_B                                    :: 12124164
kChannelLayoutTag_WAVE_5_0_A                                    :: 7667717
kChannelLayoutTag_WAVE_5_0_B                                    :: 12189701
kChannelLayoutTag_WAVE_5_1_A                                    :: 7929862
kChannelLayoutTag_WAVE_5_1_B                                    :: 12255238
kChannelLayoutTag_WAVE_6_1                                      :: 12320775
kChannelLayoutTag_WAVE_7_1                                      :: 12386312
kChannelLayoutTag_HOA_ACN_SN3D                                  :: 12451840
kChannelLayoutTag_HOA_ACN_N3D                                   :: 12517376
kChannelLayoutTag_Atmos_5_1_2                                   :: 12713992
kChannelLayoutTag_Atmos_5_1_4                                   :: 12779530
kChannelLayoutTag_Atmos_7_1_2                                   :: 12845066
kChannelLayoutTag_Atmos_7_1_4                                   :: 12582924
kChannelLayoutTag_Atmos_9_1_6                                   :: 12648464
kChannelLayoutTag_Logic_Mono                                    :: 6553601
kChannelLayoutTag_Logic_Stereo                                  :: 6619138
kChannelLayoutTag_Logic_Quadraphonic                            :: 7077892
kChannelLayoutTag_Logic_4_0_A                                   :: 7536644
kChannelLayoutTag_Logic_4_0_B                                   :: 7602180
kChannelLayoutTag_Logic_4_0_C                                   :: 12910596
kChannelLayoutTag_Logic_5_0_A                                   :: 7667717
kChannelLayoutTag_Logic_5_0_B                                   :: 7733253
kChannelLayoutTag_Logic_5_0_C                                   :: 7798789
kChannelLayoutTag_Logic_5_0_D                                   :: 7864325
kChannelLayoutTag_Logic_5_1_A                                   :: 7929862
kChannelLayoutTag_Logic_5_1_B                                   :: 7995398
kChannelLayoutTag_Logic_5_1_C                                   :: 8060934
kChannelLayoutTag_Logic_5_1_D                                   :: 8126470
kChannelLayoutTag_Logic_6_0_A                                   :: 9240582
kChannelLayoutTag_Logic_6_0_B                                   :: 12976134
kChannelLayoutTag_Logic_6_0_C                                   :: 9109510
kChannelLayoutTag_Logic_6_1_A                                   :: 9306119
kChannelLayoutTag_Logic_6_1_B                                   :: 13041671
kChannelLayoutTag_Logic_6_1_C                                   :: 8192007
kChannelLayoutTag_Logic_6_1_D                                   :: 13107207
kChannelLayoutTag_Logic_7_1_A                                   :: 8388616
kChannelLayoutTag_Logic_7_1_B                                   :: 13172744
kChannelLayoutTag_Logic_7_1_C                                   :: 8388616
kChannelLayoutTag_Logic_7_1_SDDS_A                              :: 8257544
kChannelLayoutTag_Logic_7_1_SDDS_B                              :: 8323080
kChannelLayoutTag_Logic_7_1_SDDS_C                              :: 8454152
kChannelLayoutTag_Logic_Atmos_5_1_2                             :: 12713992
kChannelLayoutTag_Logic_Atmos_5_1_4                             :: 12779530
kChannelLayoutTag_Logic_Atmos_7_1_2                             :: 12845066
kChannelLayoutTag_Logic_Atmos_7_1_4_A                           :: 12582924
kChannelLayoutTag_Logic_Atmos_7_1_4_B                           :: 13238284
kChannelLayoutTag_Logic_Atmos_7_1_6                             :: 13303822
kChannelLayoutTag_DiscreteInOrder                               :: 9633792
kChannelLayoutTag_CICP_1                                        :: 6553601
kChannelLayoutTag_CICP_2                                        :: 6619138
kChannelLayoutTag_CICP_3                                        :: 7405571
kChannelLayoutTag_CICP_4                                        :: 7536644
kChannelLayoutTag_CICP_5                                        :: 7667717
kChannelLayoutTag_CICP_6                                        :: 7929862
kChannelLayoutTag_CICP_7                                        :: 8323080
kChannelLayoutTag_CICP_9                                        :: 8585219
kChannelLayoutTag_CICP_10                                       :: 8650756
kChannelLayoutTag_CICP_11                                       :: 8192007
kChannelLayoutTag_CICP_12                                       :: 8388616
kChannelLayoutTag_CICP_13                                       :: 13369368
kChannelLayoutTag_CICP_14                                       :: 13434888
kChannelLayoutTag_CICP_15                                       :: 13500428
kChannelLayoutTag_CICP_16                                       :: 13565962
kChannelLayoutTag_CICP_17                                       :: 13631500
kChannelLayoutTag_CICP_18                                       :: 13697038
kChannelLayoutTag_CICP_19                                       :: 13762572
kChannelLayoutTag_CICP_20                                       :: 13828110
kChannelLayoutTag_Ogg_3_0                                       :: 9830403
kChannelLayoutTag_Ogg_4_0                                       :: 12124164
kChannelLayoutTag_Ogg_5_0                                       :: 13893637
kChannelLayoutTag_Ogg_5_1                                       :: 13959174
kChannelLayoutTag_Ogg_6_1                                       :: 14024711
kChannelLayoutTag_Ogg_7_1                                       :: 14090248
kChannelLayoutTag_MPEG_5_0_E                                    :: 14155781
kChannelLayoutTag_MPEG_5_1_E                                    :: 14221318
kChannelLayoutTag_MPEG_6_1_B                                    :: 14286855
kChannelLayoutTag_MPEG_7_1_D                                    :: 14352392
kChannelLayoutTag_BeginReserved                                 :: 4026531840
kChannelLayoutTag_EndReserved                                   :: 4294901759
kChannelLayoutTag_Unknown                                       :: 4294901760
kHardwareNoError                                                :: 0
kHardwareNotRunningError                                        :: 1937010544
kHardwareUnspecifiedError                                       :: 2003329396
kHardwareUnknownPropertyError                                   :: 2003332927
kHardwareBadPropertySizeError                                   :: 561211770
kHardwareIllegalOperationError                                  :: 1852797029
kHardwareBadObjectError                                         :: 560947818
kHardwareBadDeviceError                                         :: 560227702
kHardwareBadStreamError                                         :: 561214578
kHardwareUnsupportedOperationError                              :: 1970171760
kHardwareNotReadyError                                          :: 1852990585
kDeviceUnsupportedFormatError                                   :: 560226676
kDevicePermissionsError                                         :: 560492391
kObjectUnknown                                                  :: 0
kObjectPropertyScopeGlobal                                      :: 1735159650
kObjectPropertyScopeInput                                       :: 1768845428
kObjectPropertyScopeOutput                                      :: 1869968496
kObjectPropertyScopePlayThrough                                 :: 1886679669
kObjectPropertyElementMain                                      :: 0
kObjectPropertyElementMaster                                    :: 0
kObjectPropertySelectorWildcard                                 :: 707406378
kObjectPropertyScopeWildcard                                    :: 707406378
kObjectPropertyElementWildcard                                  :: 4294967295
kObjectClassIDWildcard                                          :: 707406378
kObjectClassID                                                  :: 1634689642
kObjectPropertyBaseClass                                        :: 1650682995
kObjectPropertyClass                                            :: 1668047219
kObjectPropertyOwner                                            :: 1937007734
kObjectPropertyName                                             :: 1819173229
kObjectPropertyModelName                                        :: 1819111268
kObjectPropertyManufacturer                                     :: 1819107691
kObjectPropertyElementName                                      :: 1818454126
kObjectPropertyElementCategoryName                              :: 1818452846
kObjectPropertyElementNumberName                                :: 1818455662
kObjectPropertyOwnedObjects                                     :: 1870098020
kObjectPropertyIdentify                                         :: 1768187246
kObjectPropertySerialNumber                                     :: 1936618861
kObjectPropertyFirmwareVersion                                  :: 1719105134
kPlugInClassID                                                  :: 1634757735
kPlugInPropertyBundleID                                         :: 1885956452
kPlugInPropertyDeviceList                                       :: 1684370979
kPlugInPropertyTranslateUIDToDevice                             :: 1969841252
kPlugInPropertyBoxList                                          :: 1651472419
kPlugInPropertyTranslateUIDToBox                                :: 1969841250
kPlugInPropertyClockDeviceList                                  :: 1668049699
kPlugInPropertyTranslateUIDToClockDevice                        :: 1969841251
kTransportManagerClassID                                        :: 1953656941
kTransportManagerPropertyEndPointList                           :: 1701733411
kTransportManagerPropertyTranslateUIDToEndPoint                 :: 1969841253
kTransportManagerPropertyTransportType                          :: 1953653102
kBoxClassID                                                     :: 1633841016
kBoxPropertyBoxUID                                              :: 1651861860
kBoxPropertyTransportType                                       :: 1953653102
kBoxPropertyHasAudio                                            :: 1651007861
kBoxPropertyHasVideo                                            :: 1651013225
kBoxPropertyHasMIDI                                             :: 1651010921
kBoxPropertyIsProtected                                         :: 1651536495
kBoxPropertyAcquired                                            :: 1652060014
kBoxPropertyAcquisitionFailed                                   :: 1652060006
kBoxPropertyDeviceList                                          :: 1650751011
kBoxPropertyClockDeviceList                                     :: 1650682915
kDeviceClassID                                                  :: 1633969526
kDeviceTransportTypeUnknown                                     :: 0
kDeviceTransportTypeBuiltIn                                     :: 1651274862
kDeviceTransportTypeAggregate                                   :: 1735554416
kDeviceTransportTypeVirtual                                     :: 1986622068
kDeviceTransportTypePCI                                         :: 1885563168
kDeviceTransportTypeUSB                                         :: 1970496032
kDeviceTransportTypeFireWire                                    :: 825440564
kDeviceTransportTypeBluetooth                                   :: 1651275109
kDeviceTransportTypeBluetoothLE                                 :: 1651271009
kDeviceTransportTypeHDMI                                        :: 1751412073
kDeviceTransportTypeDisplayPort                                 :: 1685090932
kDeviceTransportTypeAirPlay                                     :: 1634300528
kDeviceTransportTypeAVB                                         :: 1700886114
kDeviceTransportTypeThunderbolt                                 :: 1953002862
kDeviceTransportTypeContinuityCaptureWired                      :: 1667463012
kDeviceTransportTypeContinuityCaptureWireless                   :: 1667463020
kDeviceTransportTypeContinuityCapture                           :: 1667457392
kDevicePropertyConfigurationApplication                         :: 1667330160
kDevicePropertyDeviceUID                                        :: 1969841184
kDevicePropertyModelUID                                         :: 1836411236
kDevicePropertyTransportType                                    :: 1953653102
kDevicePropertyRelatedDevices                                   :: 1634429294
kDevicePropertyClockDomain                                      :: 1668049764
kDevicePropertyDeviceIsAlive                                    :: 1818850926
kDevicePropertyDeviceIsRunning                                  :: 1735354734
kDevicePropertyDeviceCanBeDefaultDevice                         :: 1684434036
kDevicePropertyDeviceCanBeDefaultSystemDevice                   :: 1936092276
kDevicePropertyLatency                                          :: 1819569763
kDevicePropertyStreams                                          :: 1937009955
kObjectPropertyControlList                                      :: 1668575852
kDevicePropertySafetyOffset                                     :: 1935763060
kDevicePropertyNominalSampleRate                                :: 1853059700
kDevicePropertyAvailableNominalSampleRates                      :: 1853059619
kDevicePropertyIcon                                             :: 1768124270
kDevicePropertyIsHidden                                         :: 1751737454
kDevicePropertyPreferredChannelsForStereo                       :: 1684236338
kDevicePropertyPreferredChannelLayout                           :: 1936879204
kClockDeviceClassID                                             :: 1633905771
kClockDevicePropertyDeviceUID                                   :: 1668639076
kClockDevicePropertyTransportType                               :: 1953653102
kClockDevicePropertyClockDomain                                 :: 1668049764
kClockDevicePropertyDeviceIsAlive                               :: 1818850926
kClockDevicePropertyDeviceIsRunning                             :: 1735354734
kClockDevicePropertyLatency                                     :: 1819569763
kClockDevicePropertyControlList                                 :: 1668575852
kClockDevicePropertyNominalSampleRate                           :: 1853059700
kClockDevicePropertyAvailableNominalSampleRates                 :: 1853059619
kEndPointDeviceClassID                                          :: 1701078390
kEndPointDevicePropertyComposition                              :: 1633906541
kEndPointDevicePropertyEndPointList                             :: 1634169456
kEndPointDevicePropertyIsPrivate                                :: 1886546294
kEndPointClassID                                                :: 1701733488
kStreamClassID                                                  :: 1634956402
kStreamTerminalTypeUnknown                                      :: 0
kStreamTerminalTypeLine                                         :: 1818848869
kStreamTerminalTypeDigitalAudioInterface                        :: 1936745574
kStreamTerminalTypeSpeaker                                      :: 1936747378
kStreamTerminalTypeHeadphones                                   :: 1751412840
kStreamTerminalTypeLFESpeaker                                   :: 1818649971
kStreamTerminalTypeReceiverSpeaker                              :: 1920168043
kStreamTerminalTypeMicrophone                                   :: 1835623282
kStreamTerminalTypeHeadsetMicrophone                            :: 1752000867
kStreamTerminalTypeReceiverMicrophone                           :: 1919773027
kStreamTerminalTypeTTY                                          :: 1953790303
kStreamTerminalTypeHDMI                                         :: 1751412073
kStreamTerminalTypeDisplayPort                                  :: 1685090932
kStreamPropertyIsActive                                         :: 1935762292
kStreamPropertyDirection                                        :: 1935960434
kStreamPropertyTerminalType                                     :: 1952805485
kStreamPropertyStartingChannel                                  :: 1935894638
kStreamPropertyLatency                                          :: 1819569763
kStreamPropertyVirtualFormat                                    :: 1936092532
kStreamPropertyAvailableVirtualFormats                          :: 1936092513
kStreamPropertyPhysicalFormat                                   :: 1885762592
kStreamPropertyAvailablePhysicalFormats                         :: 1885762657
kControlClassID                                                 :: 1633907820
kControlPropertyScope                                           :: 1668506480
kControlPropertyElement                                         :: 1667591277
kSliderControlClassID                                           :: 1936483442
kSliderControlPropertyValue                                     :: 1935962742
kSliderControlPropertyRange                                     :: 1935962738
kLevelControlClassID                                            :: 1818588780
kVolumeControlClassID                                           :: 1986817381
kLFEVolumeControlClassID                                        :: 1937072758
kLevelControlPropertyScalarValue                                :: 1818456950
kLevelControlPropertyDecibelValue                               :: 1818453110
kLevelControlPropertyDecibelRange                               :: 1818453106
kLevelControlPropertyConvertScalarToDecibels                    :: 1818456932
kLevelControlPropertyConvertDecibelsToScalar                    :: 1818453107
kBooleanControlClassID                                          :: 1953458028
kMuteControlClassID                                             :: 1836414053
kSoloControlClassID                                             :: 1936682095
kJackControlClassID                                             :: 1784767339
kLFEMuteControlClassID                                          :: 1937072749
kPhantomPowerControlClassID                                     :: 1885888878
kPhaseInvertControlClassID                                      :: 1885893481
kClipLightControlClassID                                        :: 1668049264
kTalkbackControlClassID                                         :: 1952541794
kListenbackControlClassID                                       :: 1819504226
kBooleanControlPropertyValue                                    :: 1650685548
kSelectorControlClassID                                         :: 1936483188
kDataSourceControlClassID                                       :: 1685287523
kDataDestinationControlClassID                                  :: 1684370292
kClockSourceControlClassID                                      :: 1668047723
kLineLevelControlClassID                                        :: 1852601964
kHighPassFilterControlClassID                                   :: 1751740518
kSelectorControlPropertyCurrentItem                             :: 1935893353
kSelectorControlPropertyAvailableItems                          :: 1935892841
kSelectorControlPropertyItemName                                :: 1935894894
kSelectorControlPropertyItemKind                                :: 1668049771
kSelectorControlItemKindSpacer                                  :: 1936745330
kClockSourceItemKindInternal                                    :: 1768846368
kStereoPanControlClassID                                        :: 1936744814
kStereoPanControlPropertyValue                                  :: 1936745334
kStereoPanControlPropertyPanningChannels                        :: 1936745315
kObjectSystemObject                                             :: 1
kObjectPropertyCreator                                          :: 1869638759
kObjectPropertyListenerAdded                                    :: 1818850145
kObjectPropertyListenerRemoved                                  :: 1818850162
kSystemObjectClassID                                            :: 1634957683
kHardwarePropertyDevices                                        :: 1684370979
kHardwarePropertyDefaultInputDevice                             :: 1682533920
kHardwarePropertyDefaultOutputDevice                            :: 1682929012
kHardwarePropertyDefaultSystemOutputDevice                      :: 1934587252
kHardwarePropertyTranslateUIDToDevice                           :: 1969841252
kHardwarePropertyMixStereoToMono                                :: 1937010031
kHardwarePropertyPlugInList                                     :: 1886152483
kHardwarePropertyTranslateBundleIDToPlugIn                      :: 1651074160
kHardwarePropertyTransportManagerList                           :: 1953326883
kHardwarePropertyTranslateBundleIDToTransportManager            :: 1953325673
kHardwarePropertyBoxList                                        :: 1651472419
kHardwarePropertyTranslateUIDToBox                              :: 1969841250
kHardwarePropertyClockDeviceList                                :: 1668049699
kHardwarePropertyTranslateUIDToClockDevice                      :: 1969841251
kHardwarePropertyProcessIsMain                                  :: 1835100526
kHardwarePropertyIsInitingOrExiting                             :: 1768845172
kHardwarePropertyUserIDChanged                                  :: 1702193508
kHardwarePropertyProcessInputMute                               :: 1886218606
kHardwarePropertyProcessIsAudible                               :: 1886221684
kHardwarePropertySleepingIsAllowed                              :: 1936483696
kHardwarePropertyUnloadingIsAllowed                             :: 1970170980
kHardwarePropertyHogModeIsAllowed                               :: 1752131442
kHardwarePropertyUserSessionIsActiveOrHeadless                  :: 1970496882
kHardwarePropertyServiceRestarted                               :: 1936880500
kHardwarePropertyPowerHint                                      :: 1886353256
kHardwarePropertyProcessObjectList                              :: 1886548771
kHardwarePropertyTranslatePIDToProcessObject                    :: 1768174192
kHardwarePropertyTapList                                        :: 1953526563
kHardwarePropertyTranslateUIDToTap                              :: 1969841268
kPlugInCreateAggregateDevice                                    :: 1667327847
kPlugInDestroyAggregateDevice                                   :: 1684105063
kTransportManagerCreateEndPointDevice                           :: 1667523958
kTransportManagerDestroyEndPointDevice                          :: 1684301174
kDeviceStartTimeIsInputFlag                                     :: 1
kDeviceStartTimeDontConsultDeviceFlag                           :: 2
kDeviceStartTimeDontConsultHALFlag                              :: 4
kDevicePropertyPlugIn                                           :: 1886156135
kDevicePropertyDeviceHasChanged                                 :: 1684629094
kDevicePropertyDeviceIsRunningSomewhere                         :: 1735356005
kDeviceProcessorOverload                                        :: 1870030194
kDevicePropertyIOStoppedAbnormally                              :: 1937010788
kDevicePropertyHogMode                                          :: 1869180523
kDevicePropertyBufferFrameSize                                  :: 1718839674
kDevicePropertyBufferFrameSizeRange                             :: 1718843939
kDevicePropertyUsesVariableBufferFrameSizes                     :: 1986425722
kDevicePropertyIOCycleUsage                                     :: 1852012899
kDevicePropertyStreamConfiguration                              :: 1936482681
kDevicePropertyIOProcStreamUsage                                :: 1937077093
kDevicePropertyActualSampleRate                                 :: 1634955892
kDevicePropertyClockDevice                                      :: 1634755428
kDevicePropertyIOThreadOSWorkgroup                              :: 1869838183
kDevicePropertyProcessMute                                      :: 1634758765
kDevicePropertyJackIsConnected                                  :: 1784767339
kDevicePropertyVolumeScalar                                     :: 1987013741
kDevicePropertyVolumeDecibels                                   :: 1987013732
kDevicePropertyVolumeRangeDecibels                              :: 1986290211
kDevicePropertyVolumeScalarToDecibels                           :: 1983013986
kDevicePropertyVolumeDecibelsToScalar                           :: 1684157046
kDevicePropertyStereoPan                                        :: 1936744814
kDevicePropertyStereoPanChannels                                :: 1936748067
kDevicePropertyMute                                             :: 1836414053
kDevicePropertySolo                                             :: 1936682095
kDevicePropertyPhantomPower                                     :: 1885888878
kDevicePropertyPhaseInvert                                      :: 1885893481
kDevicePropertyClipLight                                        :: 1668049264
kDevicePropertyTalkback                                         :: 1952541794
kDevicePropertyListenback                                       :: 1819504226
kDevicePropertyDataSource                                       :: 1936945763
kDevicePropertyDataSources                                      :: 1936941859
kDevicePropertyDataSourceNameForIDCFString                      :: 1819501422
kDevicePropertyDataSourceKindForID                              :: 1936941931
kDevicePropertyClockSource                                      :: 1668510307
kDevicePropertyClockSources                                     :: 1668506403
kDevicePropertyClockSourceNameForIDCFString                     :: 1818456942
kDevicePropertyClockSourceKindForID                             :: 1668506475
kDevicePropertyPlayThru                                         :: 1953002101
kDevicePropertyPlayThruSolo                                     :: 1953002099
kDevicePropertyPlayThruVolumeScalar                             :: 1836479331
kDevicePropertyPlayThruVolumeDecibels                           :: 1836475490
kDevicePropertyPlayThruVolumeRangeDecibels                      :: 1836475427
kDevicePropertyPlayThruVolumeScalarToDecibels                   :: 1836462692
kDevicePropertyPlayThruVolumeDecibelsToScalar                   :: 1836462707
kDevicePropertyPlayThruStereoPan                                :: 1836281966
kDevicePropertyPlayThruStereoPanChannels                        :: 1836281891
kDevicePropertyPlayThruDestination                              :: 1835295859
kDevicePropertyPlayThruDestinations                             :: 1835295779
kDevicePropertyPlayThruDestinationNameForIDCFString             :: 1835295843
kDevicePropertyChannelNominalLineLevel                          :: 1852601964
kDevicePropertyChannelNominalLineLevels                         :: 1852601891
kDevicePropertyChannelNominalLineLevelNameForIDCFString         :: 1818455660
kDevicePropertyHighPassFilterSetting                            :: 1751740518
kDevicePropertyHighPassFilterSettings                           :: 1751740451
kDevicePropertyHighPassFilterSettingNameForIDCFString           :: 1751740524
kDevicePropertySubVolumeScalar                                  :: 1937140845
kDevicePropertySubVolumeDecibels                                :: 1937140836
kDevicePropertySubVolumeRangeDecibels                           :: 1937138723
kDevicePropertySubVolumeScalarToDecibels                        :: 1937125988
kDevicePropertySubVolumeDecibelsToScalar                        :: 1935946358
kDevicePropertySubMute                                          :: 1936553332
kDevicePropertyVoiceActivityDetectionEnable                     :: 1983996971
kDevicePropertyVoiceActivityDetectionState                      :: 1983997011
kDevicePropertyWantsControlsRestored                            :: 1919251299
kDevicePropertyWantsStreamFormatsRestored                       :: 1919251302
kAggregateDeviceClassID                                         :: 1633773415
kAggregateDevicePropertyFullSubDeviceList                       :: 1735554416
kAggregateDevicePropertyActiveSubDeviceList                     :: 1634169456
kAggregateDevicePropertyComposition                             :: 1633906541
kAggregateDevicePropertyMainSubDevice                           :: 1634562932
kAggregateDevicePropertyClockDevice                             :: 1634755428
kAggregateDevicePropertyTapList                                 :: 1952542755
kAggregateDevicePropertySubTapList                              :: 1635017072
kAggregateDriftCompensationMinQuality                           :: 0
kAggregateDriftCompensationLowQuality                           :: 32
kAggregateDriftCompensationMediumQuality                        :: 64
kAggregateDriftCompensationHighQuality                          :: 96
kAggregateDriftCompensationMaxQuality                           :: 127
kSubDeviceClassID                                               :: 1634956642
kSubDeviceDriftCompensationMinQuality                           :: 0
kSubDeviceDriftCompensationLowQuality                           :: 32
kSubDeviceDriftCompensationMediumQuality                        :: 64
kSubDeviceDriftCompensationHighQuality                          :: 96
kSubDeviceDriftCompensationMaxQuality                           :: 127
kSubDevicePropertyExtraLatency                                  :: 2020373603
kSubDevicePropertyDriftCompensation                             :: 1685218932
kSubDevicePropertyDriftCompensationQuality                      :: 1685218929
kSubTapClassID                                                  :: 1937006960
kSubTapPropertyExtraLatency                                     :: 2020373603
kSubTapPropertyDriftCompensation                                :: 1685218932
kSubTapPropertyDriftCompensationQuality                         :: 1685218929
kProcessClassID                                                 :: 1668050548
kProcessPropertyPID                                             :: 1886415204
kProcessPropertyBundleID                                        :: 1885497700
kProcessPropertyDevices                                         :: 1885632035
kProcessPropertyIsRunning                                       :: 1885958719
kProcessPropertyIsRunningInput                                  :: 1885958761
kProcessPropertyIsRunningOutput                                 :: 1885958767
kTapClassID                                                     :: 1952672883
kTapPropertyUID                                                 :: 1953851748
kTapPropertyDescription                                         :: 1952740195
kTapPropertyFormat                                              :: 1952869748
kDevicePropertyScopeInput                                       :: 1768845428
kDevicePropertyScopeOutput                                      :: 1869968496
kDevicePropertyScopePlayThrough                                 :: 1886679669
kPropertyWildcardPropertyID                                     :: 707406378
kPropertyWildcardSection                                        :: 255
kPropertyWildcardChannel                                        :: 4294967295
kISubOwnerControlClassID                                        :: 1635017576
kLevelControlPropertyDecibelsToScalarTransferFunction           :: 1818457190
kHardwarePropertyRunLoop                                        :: 1919839344
kHardwarePropertyDeviceForUID                                   :: 1685416292
kHardwarePropertyPlugInForBundleID                              :: 1885954665
kHardwarePropertyProcessIsMaster                                :: 1835103092
kHardwarePropertyBootChimeVolumeScalar                          :: 1650620019
kHardwarePropertyBootChimeVolumeDecibels                        :: 1650620004
kHardwarePropertyBootChimeVolumeRangeDecibels                   :: 1650615331
kHardwarePropertyBootChimeVolumeScalarToDecibels                :: 1651913316
kHardwarePropertyBootChimeVolumeDecibelsToScalar                :: 1650733686
kHardwarePropertyBootChimeVolumeDecibelsToScalarTransferFunction:: 1651930214
kDeviceUnknown                                                  :: 0
kDeviceTransportTypeAutoAggregate                               :: 1718055536
kDevicePropertyVolumeDecibelsToScalarTransferFunction           :: 1986229350
kDevicePropertyPlayThruVolumeDecibelsToScalarTransferFunction   :: 1836479590
kDevicePropertyDriverShouldOwniSub                              :: 1769174370
kDevicePropertySubVolumeDecibelsToScalarTransferFunction        :: 1937142886
kDevicePropertyDeviceName                                       :: 1851878757
kDevicePropertyDeviceNameCFString                               :: 1819173229
kDevicePropertyDeviceManufacturer                               :: 1835101042
kDevicePropertyDeviceManufacturerCFString                       :: 1819107691
kDevicePropertyRegisterBufferList                               :: 1919055206
kDevicePropertyBufferSize                                       :: 1651730810
kDevicePropertyBufferSizeRange                                  :: 1651735075
kDevicePropertyChannelName                                      :: 1667788397
kDevicePropertyChannelNameCFString                              :: 1818454126
kDevicePropertyChannelCategoryName                              :: 1667460717
kDevicePropertyChannelCategoryNameCFString                      :: 1818452846
kDevicePropertyChannelNumberName                                :: 1668181613
kDevicePropertyChannelNumberNameCFString                        :: 1818455662
kDevicePropertySupportsMixing                                   :: 1835628607
kDevicePropertyStreamFormat                                     :: 1936092532
kDevicePropertyStreamFormats                                    :: 1936092451
kDevicePropertyStreamFormatSupported                            :: 1936092479
kDevicePropertyStreamFormatMatch                                :: 1936092525
kDevicePropertyDataSourceNameForID                              :: 1936941934
kDevicePropertyClockSourceNameForID                             :: 1668506478
kDevicePropertyPlayThruDestinationNameForID                     :: 1835295854
kDevicePropertyChannelNominalLineLevelNameForID                 :: 1668181110
kDevicePropertyHighPassFilterSettingNameForID                   :: 1667787120
kAggregateDevicePropertyMasterSubDevice                         :: 1634562932
kStreamUnknown                                                  :: 0
kStreamPropertyOwningDevice                                     :: 1937007734
kStreamPropertyPhysicalFormats                                  :: 1885762595
kStreamPropertyPhysicalFormatSupported                          :: 1885762623
kStreamPropertyPhysicalFormatMatch                              :: 1885762669
kBootChimeVolumeControlClassID                                  :: 1886544237
kControlPropertyVariant                                         :: 1668702578
kClockSourceControlPropertyItemKind                             :: 1668049771
kStreamAnyRate                                                  :: 0.000000

@(link_prefix="Audio", default_calling_convention="c")
foreign lib {
	ObjectShow                        :: proc(inObjectID: ObjectID) ---
	ObjectHasProperty                 :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress) -> CF.Boolean ---
	ObjectIsPropertySettable          :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, outIsSettable: ^CF.Boolean) -> CF.OSStatus ---
	ObjectGetPropertyDataSize         :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inQualifierDataSize: CF.UInt32, inQualifierData: rawptr, outDataSize: ^CF.UInt32) -> CF.OSStatus ---
	ObjectGetPropertyData             :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inQualifierDataSize: CF.UInt32, inQualifierData: rawptr, ioDataSize: ^CF.UInt32, outData: rawptr) -> CF.OSStatus ---
	ObjectSetPropertyData             :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inQualifierDataSize: CF.UInt32, inQualifierData: rawptr, inDataSize: CF.UInt32, inData: rawptr) -> CF.OSStatus ---
	ObjectAddPropertyListener         :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inListener: ObjectPropertyListenerProc, inClientData: rawptr) -> CF.OSStatus ---
	ObjectRemovePropertyListener      :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inListener: ObjectPropertyListenerProc, inClientData: rawptr) -> CF.OSStatus ---
	ObjectAddPropertyListenerBlock    :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inDispatchQueue: CF.dispatch_queue_t, inListener: ObjectPropertyListenerBlock) -> CF.OSStatus ---
	ObjectRemovePropertyListenerBlock :: proc(inObjectID: ObjectID, inAddress: ^ObjectPropertyAddress, inDispatchQueue: CF.dispatch_queue_t, inListener: ObjectPropertyListenerBlock) -> CF.OSStatus ---
	HardwareUnload                    :: proc() -> CF.OSStatus ---
	HardwareCreateAggregateDevice     :: proc(inDescription: CF.DictionaryRef, outDeviceID: ^ObjectID) -> CF.OSStatus ---
	HardwareDestroyAggregateDevice    :: proc(inDeviceID: ObjectID) -> CF.OSStatus ---
	DeviceCreateIOProcID              :: proc(inDevice: ObjectID, inProc: DeviceIOProc, inClientData: rawptr, outIOProcID: ^DeviceIOProcID) -> CF.OSStatus ---
	DeviceCreateIOProcIDWithBlock     :: proc(outIOProcID: ^DeviceIOProcID, inDevice: ObjectID, inDispatchQueue: CF.dispatch_queue_t, inIOBlock: DeviceIOBlock) -> CF.OSStatus ---
	DeviceDestroyIOProcID             :: proc(inDevice: ObjectID, inIOProcID: DeviceIOProcID) -> CF.OSStatus ---
	DeviceStart                       :: proc(inDevice: ObjectID, inProcID: DeviceIOProcID) -> CF.OSStatus ---
	DeviceStartAtTime                 :: proc(inDevice: ObjectID, inProcID: DeviceIOProcID, ioRequestedStartTime: ^TimeStamp, inFlags: CF.UInt32) -> CF.OSStatus ---
	DeviceStop                        :: proc(inDevice: ObjectID, inProcID: DeviceIOProcID) -> CF.OSStatus ---
	DeviceGetCurrentTime              :: proc(inDevice: ObjectID, outTime: ^TimeStamp) -> CF.OSStatus ---
	DeviceTranslateTime               :: proc(inDevice: ObjectID, inTime: ^TimeStamp, outTime: ^TimeStamp) -> CF.OSStatus ---
	DeviceGetNearestStartTime         :: proc(inDevice: ObjectID, ioRequestedStartTime: ^TimeStamp, inFlags: CF.UInt32) -> CF.OSStatus ---
	HardwareAddRunLoopSource          :: proc(inRunLoopSource: CF.RunLoopSourceRef) -> CF.OSStatus ---
	HardwareRemoveRunLoopSource       :: proc(inRunLoopSource: CF.RunLoopSourceRef) -> CF.OSStatus ---
	HardwareGetPropertyInfo           :: proc(inPropertyID: HardwarePropertyID, outSize: ^CF.UInt32, outWritable: ^CF.Boolean) -> CF.OSStatus ---
	HardwareGetProperty               :: proc(inPropertyID: HardwarePropertyID, ioPropertyDataSize: ^CF.UInt32, outPropertyData: rawptr) -> CF.OSStatus ---
	HardwareSetProperty               :: proc(inPropertyID: HardwarePropertyID, inPropertyDataSize: CF.UInt32, inPropertyData: rawptr) -> CF.OSStatus ---
	HardwareAddPropertyListener       :: proc(inPropertyID: HardwarePropertyID, inProc: HardwarePropertyListenerProc, inClientData: rawptr) -> CF.OSStatus ---
	HardwareRemovePropertyListener    :: proc(inPropertyID: HardwarePropertyID, inProc: HardwarePropertyListenerProc) -> CF.OSStatus ---
	DeviceAddIOProc                   :: proc(inDevice: DeviceID, inProc: DeviceIOProc, inClientData: rawptr) -> CF.OSStatus ---
	DeviceRemoveIOProc                :: proc(inDevice: DeviceID, inProc: DeviceIOProc) -> CF.OSStatus ---
	DeviceRead                        :: proc(inDevice: DeviceID, inStartTime: ^TimeStamp, outData: ^BufferList) -> CF.OSStatus ---
	DeviceGetPropertyInfo             :: proc(inDevice: DeviceID, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, outSize: ^CF.UInt32, outWritable: ^CF.Boolean) -> CF.OSStatus ---
	DeviceGetProperty                 :: proc(inDevice: DeviceID, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, ioPropertyDataSize: ^CF.UInt32, outPropertyData: rawptr) -> CF.OSStatus ---
	DeviceSetProperty                 :: proc(inDevice: DeviceID, inWhen: ^TimeStamp, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, inPropertyDataSize: CF.UInt32, inPropertyData: rawptr) -> CF.OSStatus ---
	DeviceAddPropertyListener         :: proc(inDevice: DeviceID, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, inProc: DevicePropertyListenerProc, inClientData: rawptr) -> CF.OSStatus ---
	DeviceRemovePropertyListener      :: proc(inDevice: DeviceID, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, inProc: DevicePropertyListenerProc) -> CF.OSStatus ---
	StreamGetPropertyInfo             :: proc(inStream: StreamID, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, outSize: ^CF.UInt32, outWritable: ^CF.Boolean) -> CF.OSStatus ---
	StreamGetProperty                 :: proc(inStream: StreamID, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, ioPropertyDataSize: ^CF.UInt32, outPropertyData: rawptr) -> CF.OSStatus ---
	StreamSetProperty                 :: proc(inStream: StreamID, inWhen: ^TimeStamp, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, inPropertyDataSize: CF.UInt32, inPropertyData: rawptr) -> CF.OSStatus ---
	StreamAddPropertyListener         :: proc(inStream: StreamID, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, inProc: StreamPropertyListenerProc, inClientData: rawptr) -> CF.OSStatus ---
	StreamRemovePropertyListener      :: proc(inStream: StreamID, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, inProc: StreamPropertyListenerProc) -> CF.OSStatus ---
	GetCurrentHostTime                :: proc() -> CF.UInt64 ---
	GetHostClockFrequency             :: proc() -> f64 ---
	GetHostClockMinimumTimeDelta      :: proc() -> CF.UInt32 ---
	ConvertHostTimeToNanos            :: proc(inHostTime: CF.UInt64) -> CF.UInt64 ---
	ConvertNanosToHostTime            :: proc(inNanos: CF.UInt64) -> CF.UInt64 ---
}

// AudioSampleType
SampleType :: f32

// AudioUnitSampleType
UnitSampleType :: f32

// AudioChannelLabel
ChannelLabel :: CF.UInt32

// AudioChannelLayoutTag
ChannelLayoutTag :: CF.UInt32

// AudioSessionID
SessionID :: u32

// AudioObjectID
ObjectID :: CF.UInt32

// AudioClassID
ClassID :: CF.UInt32

// AudioObjectPropertySelector
ObjectPropertySelector :: CF.UInt32

// AudioObjectPropertyScope
ObjectPropertyScope :: CF.UInt32

// AudioObjectPropertyElement
ObjectPropertyElement :: CF.UInt32

// AudioObjectPropertyListenerProc
ObjectPropertyListenerProc :: proc "c" (inObjectID: ObjectID, inNumberAddresses: CF.UInt32, inAddresses: [^]ObjectPropertyAddress, inClientData: rawptr) -> CF.OSStatus

// AudioObjectPropertyListenerBlock
ObjectPropertyListenerBlock :: ^Objc_Block(proc "c" (inNumberAddresses: CF.UInt32, inAddresses: [^]ObjectPropertyAddress))

// AudioDeviceIOProc
DeviceIOProc :: proc "c" (inDevice: ObjectID, inNow: ^TimeStamp, inInputData: ^BufferList, inInputTime: ^TimeStamp, outOutputData: ^BufferList, inOutputTime: ^TimeStamp, inClientData: rawptr) -> CF.OSStatus

// AudioDeviceIOBlock
DeviceIOBlock :: ^Objc_Block(proc "c" (inNow: ^TimeStamp, inInputData: ^BufferList, inInputTime: ^TimeStamp, outOutputData: ^BufferList, inOutputTime: ^TimeStamp))

// AudioDeviceIOProcID
DeviceIOProcID :: DeviceIOProc

// AudioHardwarePropertyID
HardwarePropertyID :: ObjectPropertySelector

// AudioHardwarePropertyListenerProc
HardwarePropertyListenerProc :: proc "c" (inPropertyID: HardwarePropertyID, inClientData: rawptr) -> CF.OSStatus

// AudioDeviceID
DeviceID :: ObjectID

// AudioDevicePropertyID
DevicePropertyID :: ObjectPropertySelector

// AudioDevicePropertyListenerProc
DevicePropertyListenerProc :: proc "c" (inDevice: DeviceID, inChannel: CF.UInt32, isInput: CF.Boolean, inPropertyID: DevicePropertyID, inClientData: rawptr) -> CF.OSStatus

// AudioStreamID
StreamID :: ObjectID

// AudioStreamPropertyListenerProc
StreamPropertyListenerProc :: proc "c" (inStream: StreamID, inChannel: CF.UInt32, inPropertyID: DevicePropertyID, inClientData: rawptr) -> CF.OSStatus

// SMPTETimeType
SMPTETimeType :: enum c.uint {
	_24       = 0,
	_25       = 1,
	_30Drop   = 2,
	_30       = 3,
	_2997     = 4,
	_2997Drop = 5,
	_60       = 6,
	_5994     = 7,
	_60Drop   = 8,
	_5994Drop = 9,
	_50       = 10,
	_2398     = 11,
}

// SMPTETimeFlags
SMPTETimeFlag :: enum c.uint {
	Valid   = 0,
	Running = 1,
}
SMPTETimeFlags :: bit_set[SMPTETimeFlag; c.uint]

// AudioTimeStampFlags
TimeStampFlag :: enum c.uint {
	SampleTimeValid    = 0,
	HostTimeValid      = 1,
	RateScalarValid    = 2,
	WordClockTimeValid = 3,
	SMPTETimeValid     = 4,
}
TimeStampFlags :: bit_set[TimeStampFlag; c.uint]

TimeStampFlags_SampleHostTimeValid :: TimeStampFlags{.SampleTimeValid, .HostTimeValid}

// AudioChannelBitmap
ChannelBitmapBit :: enum c.uint {
	Left                 = 0,
	Right                = 1,
	Center               = 2,
	LFEScreen            = 3,
	LeftSurround         = 4,
	RightSurround        = 5,
	LeftCenter           = 6,
	RightCenter          = 7,
	CenterSurround       = 8,
	LeftSurroundDirect   = 9,
	RightSurroundDirect  = 10,
	TopCenterSurround    = 11,
	VerticalHeightLeft   = 12,
	VerticalHeightCenter = 13,
	VerticalHeightRight  = 14,
	TopBackLeft          = 15,
	TopBackCenter        = 16,
	TopBackRight         = 17,
	LeftTopFront         = 12,
	CenterTopFront       = 13,
	RightTopFront        = 14,
	LeftTopMiddle        = 21,
	CenterTopMiddle      = 11,
	RightTopMiddle       = 23,
	LeftTopRear          = 24,
	CenterTopRear        = 25,
	RightTopRear         = 26,
}
ChannelBitmap :: bit_set[ChannelBitmapBit; c.uint]

// AudioChannelFlags
ChannelFlag :: enum c.uint {
	RectangularCoordinates = 0,
	SphericalCoordinates   = 1,
	Meters                 = 2,
}
ChannelFlags :: bit_set[ChannelFlag; c.uint]

// AudioChannelCoordinateIndex
ChannelCoordinateIndex :: enum c.uint {
	LeftRight = 0,
	BackFront = 1,
	DownUp    = 2,
	Azimuth   = 0,
	Elevation = 1,
	Distance  = 2,
}

// AudioHardwarePowerHint
HardwarePowerHint :: enum c.uint {
	None             = 0,
	FavorSavingPower = 1,
}

// AudioLevelControlTransferFunction
LevelControlTransferFunction :: enum c.uint {
	Linear   = 0,
	_1Over3  = 1,
	_1Over2  = 2,
	_3Over4  = 3,
	_3Over2  = 4,
	_2Over1  = 5,
	_3Over1  = 6,
	_4Over1  = 7,
	_5Over1  = 8,
	_6Over1  = 9,
	_7Over1  = 10,
	_8Over1  = 11,
	_9Over1  = 12,
	_10Over1 = 13,
	_11Over1 = 14,
	_12Over1 = 15,
}

// AudioFormatID
FormatID :: enum c.uint {
	LinearPCM            = 1819304813,
	AC3                  = 1633889587,
	_60958AC3            = 1667326771,
	AppleIMA4            = 1768775988,
	MPEG4AAC             = 1633772320,
	MPEG4CELP            = 1667591280,
	MPEG4HVXC            = 1752594531,
	MPEG4TwinVQ          = 1953986161,
	MACE3                = 1296122675,
	MACE6                = 1296122678,
	ULaw                 = 1970037111,
	ALaw                 = 1634492791,
	QDesign              = 1363430723,
	QDesign2             = 1363430706,
	QUALCOMM             = 1365470320,
	MPEGLayer1           = 778924081,
	MPEGLayer2           = 778924082,
	MPEGLayer3           = 778924083,
	TimeCode             = 1953066341,
	MIDIStream           = 1835623529,
	ParameterValueStream = 1634760307,
	AppleLossless        = 1634492771,
	MPEG4AAC_HE          = 1633772392,
	MPEG4AAC_LD          = 1633772396,
	MPEG4AAC_ELD         = 1633772389,
	MPEG4AAC_ELD_SBR     = 1633772390,
	MPEG4AAC_ELD_V2      = 1633772391,
	MPEG4AAC_HE_V2       = 1633772400,
	MPEG4AAC_Spatial     = 1633772403,
	MPEGD_USAC           = 1970495843,
	AMR                  = 1935764850,
	AMR_WB               = 1935767394,
	Audible              = 1096107074,
	iLBC                 = 1768710755,
	DVIIntelIMA          = 1836253201,
	MicrosoftGSM         = 1836253233,
	AES3                 = 1634038579,
	EnhancedAC3          = 1700998451,
	FLAC                 = 1718378851,
	Opus                 = 1869641075,
	APAC                 = 1634754915,
}

// AudioFormatFlag
FormatFlag :: enum c.uint {
	IsFloat                          = 0,
	IsBigEndian                      = 1,
	IsSignedInteger                  = 2,
	IsPacked                         = 3,
	IsAlignedHigh                    = 4,
	IsNonInterleaved                 = 5,
	IsNonMixable                     = 6,
	AreAllClear                      = 31,
	AppleLosslessFormatFlag_16BitSourceData = 0,
	AppleLosslessFormatFlag_20BitSourceData = 1,
	AppleLosslessFormatFlag_32BitSourceData = 2,
	// LinearPCMFormatFlagIsFloat = 1,
	// LinearPCMFormatFlagIsBigEndian = 2,
	// LinearPCMFormatFlagIsSignedInteger = 4,
	// LinearPCMFormatFlagIsPacked = 8,
	// LinearPCMFormatFlagIsAlignedHigh = 16,
	// LinearPCMFormatFlagIsNonInterleaved = 32,
	// LinearPCMFormatFlagIsNonMixable = 64,
	// LinearPCMFormatFlagsSampleFractionShift = 7,
	// LinearPCMFormatFlagsSampleFractionMask = 8064,
	// LinearPCMFormatFlagsAreAllClear = 2147483648,
}
FormatFlags :: bit_set[FormatFlag; c.uint]

FormatFlags_AppleLosslessFormatFlag_24BitSourceData :: FormatFlags{.AppleLosslessFormatFlag_16BitSourceData, .AppleLosslessFormatFlag_20BitSourceData}

// AudioFormatFlags
FormatFlagsPreset :: enum c.uint {
	NativeEndian      = 0,
	Canonical         = 9,
	UnitCanonical     = 41,
	NativeFloatPacked = 9,
}

// AudioValueRange
ValueRange :: struct #align(8) {
	mMinimum: f64,
	mMaximum: f64,
}

// AudioValueTranslation
ValueTranslation :: struct #align(8) {
	mInputData:      rawptr,
	mInputDataSize:  CF.UInt32,
	mOutputData:     rawptr,
	mOutputDataSize: CF.UInt32,
}

// AudioBuffer
Buffer :: struct #align(8) {
	mNumberChannels: CF.UInt32,
	mDataByteSize:   CF.UInt32,
	mData:           rawptr,
}

// AudioBufferList
BufferList :: struct #align(8) {
	mNumberBuffers: CF.UInt32,
	mBuffers:       [1]Buffer,
}

// AudioStreamBasicDescription
StreamBasicDescription :: struct #align(8) {
	mSampleRate:       f64,
	mFormatID:         FormatID,
	mFormatFlags:      FormatFlags,
	mBytesPerPacket:   CF.UInt32,
	mFramesPerPacket:  CF.UInt32,
	mBytesPerFrame:    CF.UInt32,
	mChannelsPerFrame: CF.UInt32,
	mBitsPerChannel:   CF.UInt32,
	mReserved:         CF.UInt32,
}

// AudioStreamPacketDescription
StreamPacketDescription :: struct #align(8) {
	mStartOffset:            CF.SInt64,
	mVariableFramesInPacket: CF.UInt32,
	mDataByteSize:           CF.UInt32,
}

// AudioStreamPacketDependencyDescription
StreamPacketDependencyDescription :: struct #align(4) {
	mIsIndependentlyDecodable: CF.UInt32,
	mPreRollCount:             CF.UInt32,
	mFlags:                    CF.UInt32,
	mReserved:                 CF.UInt32,
}

// SMPTETime
SMPTETime :: struct #align(4) {
	mSubframes:       CF.SInt16,
	mSubframeDivisor: CF.SInt16,
	mCounter:         CF.UInt32,
	mType:            SMPTETimeType,
	mFlags:           SMPTETimeFlags,
	mHours:           CF.SInt16,
	mMinutes:         CF.SInt16,
	mSeconds:         CF.SInt16,
	mFrames:          CF.SInt16,
}

// AudioTimeStamp
TimeStamp :: struct #align(8) {
	mSampleTime:    f64,
	mHostTime:      CF.UInt64,
	mRateScalar:    f64,
	mWordClockTime: CF.UInt64,
	mSMPTETime:     SMPTETime,
	mFlags:         TimeStampFlags,
	mReserved:      CF.UInt32,
}

// AudioClassDescription
ClassDescription :: struct #align(4) {
	mType:         CF.OSType,
	mSubType:      CF.OSType,
	mManufacturer: CF.OSType,
}

// AudioChannelDescription
ChannelDescription :: struct #align(4) {
	mChannelLabel: ChannelLabel,
	mChannelFlags: ChannelFlags,
	mCoordinates:  [3]f32,
}

// AudioChannelLayout
ChannelLayout :: struct #align(4) {
	mChannelLayoutTag:          ChannelLayoutTag,
	mChannelBitmap:             ChannelBitmap,
	mNumberChannelDescriptions: CF.UInt32,
	mChannelDescriptions:       [1]ChannelDescription,
}

// AudioFormatListItem
FormatListItem :: struct #align(8) {
	mASBD:             StreamBasicDescription,
	mChannelLayoutTag: ChannelLayoutTag,
}

// AudioObjectPropertyAddress
ObjectPropertyAddress :: struct #align(4) {
	mSelector: ObjectPropertySelector,
	mScope:    ObjectPropertyScope,
	mElement:  ObjectPropertyElement,
}

// AudioStreamRangedDescription
StreamRangedDescription :: struct #align(8) {
	mFormat:          StreamBasicDescription,
	mSampleRateRange: ValueRange,
}

// AudioHardwareIOProcStreamUsage
HardwareIOProcStreamUsage :: struct #align(8) {
	mIOProc:        rawptr,
	mNumberStreams: CF.UInt32,
	mStreamIsOn:    [1]CF.UInt32,
}

