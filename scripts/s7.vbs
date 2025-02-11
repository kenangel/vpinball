'Last Updated in VBS v3.61

Option Explicit
LoadCore
Private Sub LoadCore
	On Error Resume Next
	If VPBuildVersion < 0 Or Err Then
		Dim fso : Set fso = CreateObject("Scripting.FileSystemObject") : Err.Clear
		ExecuteGlobal fso.OpenTextFile("core.vbs", 1).ReadAll    : If Err Then MsgBox "Can't open ""core.vbs""" : Exit Sub
		ExecuteGlobal fso.OpenTextFile("VPMKeys.vbs", 1).ReadAll : If Err Then MsgBox "Can't open ""vpmkeys.vbs""" : Exit Sub
	Else
		ExecuteGlobal GetTextFile("core.vbs")    : If Err Then MsgBox "Can't open ""core.vbs"""    : Exit Sub
		ExecuteGlobal GetTextFile("VPMKeys.vbs") : If Err Then MsgBox "Can't open ""vpmkeys.vbs""" : Exit Sub
	End If
End Sub

'-------------------------
' S7 Data
'-------------------------
' Flipper Solenoid
Const GameOnSolenoid = 25
' Cabinet switches
Const swAdvance      = -7
Const swUpDown       = -6
Const swCPUDiag      = -5
Const swSoundDiag    = -4
Const swTilt         =  1
Const swBallRollTilt =  2
Const swStartButton  =  3
Const swCoin3        =  4
Const swCoin2        =  5
Const swCoin1        =  6
Const swSlamTilt     =  7
Const swHSReset      =  8
Const swLRFlip       = 82
Const swLLFlip       = 84
Const swURFlip       = 83
Const swULFlip       = 81

' Help Window
vpmSystemHelp = "Williams System 7 keys:" & vbNewLine &_
  vpmKeyName(keyInsertCoin1)  & vbTab & "Insert Coin #1" & vbNewLine &_
  vpmKeyName(keyInsertCoin2)  & vbTab & "Insert Coin #2" & vbNewLine &_
  vpmKeyName(keyInsertCoin3)  & vbTab & "Insert Coin #3" & vbNewLine &_
  vpmKeyName(keySlamDoorHit)  & vbTab & "Slam Tilt"      & vbNewLine &_
  vpmKeyName(keyAdvance)      & vbTab & "Advance"        & vbNewLine &_
  vpmKeyName(keyUpDown)       & vbTab & "Up/Down"        & vbNewLine &_
  vpmKeyName(keyMasterEnter)  & vbTab & "Master Enter"   & vbNewLine &_
  vpmKeyName(keyCPUDiag)      & vbTab & "Cpu Diagnostic" & vbNewLine &_
  vpmKeyName(keySoundDiag)    & vbTab & "Sound Diagnostic"

' Dip Switch / Options Menu
Private Sub s7ShowDips
	If Not IsObject(vpmDips) Then ' First time
		Set vpmDips = New cvpmDips
		With vpmDips
			.AddForm  80, 60, "DIP Switches"
			.AddFrame 0, 0, 60, "Sound", 0,_
			   Array("DIP 1",&H00000001,"DIP 2",&H00000002)
			.AddFrame 0,45, 60,"Game", 0,_
			   Array("DIP M8",&H00000100,"DIP M7",&H00000200,"DIP M6",&H00000400,"DIP M5",&H00000800,_
			         "DIP M4",&H00001000,"DIP M3",&H00002000,"DIP M2",&H00004000,"DIP M1",32768,_
			         "DIP D8",&H00010000,"DIP D7",&H00020000,"DIP D6",&H00040000,"DIP D5",&H00080000,_
			         "DIP D4",&H00100000,"DIP D3",&H00200000,"DIP D2",&H00400000,"DIP D1",&H00800000)
		End With
	End If
	vpmDips.ViewDips
End Sub
Set vpmShowDips = GetRef("s7ShowDips")
Private vpmDips

' Keyboard handlers
Function vpmKeyDown(ByVal keycode)
	On Error Resume Next
	vpmKeyDown = True ' Assume we handle the key
	With Controller
		Select Case keycode
			Case LeftFlipperKey
				.Switch(swLLFlip) = True : vpmKeyDown = False : vpmFlips.FlipL True
				If keycode = keyStagedFlipperL Then ' as vbs will not evaluate the Case keyStagedFlipperL then, also handle it here
					vpmFlips.FlipUL True
					If cSingleLFlip Or Err Then .Switch(swULFlip) = True
				End If
			Case RightFlipperKey
				.Switch(swLRFlip) = True : vpmKeyDown = False : vpmFlips.FlipR True
				If keycode = keyStagedFlipperR Then ' as vbs will not evaluate the Case keyStagedFlipperR then, also handle it here
					vpmFlips.FlipUR True
					If cSingleRFlip Or Err Then .Switch(swURFlip) = True
				End If
			Case keyStagedFlipperL vpmFlips.FlipUL True : If cSingleLFlip Or Err Then .Switch(swULFlip) = True
			Case keyStagedFlipperR vpmFlips.FlipUR True : If cSingleRFlip Or Err Then .Switch(swURFlip) = True
			Case keyInsertCoin1  vpmTimer.AddTimer 750,"vpmTimer.PulseSw swCoin1'" : Playsound SCoin
			Case keyInsertCoin2  vpmTimer.AddTimer 750,"vpmTimer.PulseSw swCoin2'" : Playsound SCoin
			Case keyInsertCoin3  vpmTimer.AddTimer 750,"vpmTimer.PulseSw swCoin3'" : Playsound SCoin
			Case StartGameKey    .Switch(swStartButton) = True
			Case keyHiScoreReset .Switch(swHSReset)     = True
			Case keyUpDown       .Switch(swUpDown)      = Not .Switch(swUpDown)
			Case keyAdvance      .Switch(swAdvance)     = True
			Case keyCPUDiag      .Switch(swCPUDiag)     = True
			Case keySoundDiag    .Switch(swSoundDiag)   = True
			Case keyMasterEnter  .Switch(swMasterEnter) = True
			Case keySlamDoorHit  .Switch(swSlamTilt)    = True
			Case keyBangBack     vpmNudge.DoNudge   0, 6
			Case LeftTiltKey     vpmNudge.DoNudge  75, 2
			Case RightTiltKey    vpmNudge.DoNudge 285, 2
			Case CenterTiltKey   vpmNudge.DoNudge   0, 2
			Case keyVPMVolume    vpmVol
			Case Else            vpmKeyDown = False
		End Select
	End With
	On Error Goto 0
End Function

Function vpmKeyUp(ByVal keycode)
	On Error Resume Next
	vpmKeyUp = True ' Assume we handle the key
	With Controller
		Select Case keycode
			Case LeftFlipperKey
				.Switch(swLLFlip) = False : vpmKeyUp = False : vpmFlips.FlipL False
				If keycode = keyStagedFlipperL Then ' as vbs will not evaluate the Case keyStagedFlipperL then, also handle it here
					vpmFlips.FlipUL False
					If cSingleLFlip Or Err Then .Switch(swULFlip) = False
				End If
			Case RightFlipperKey
				.Switch(swLRFlip) = False : vpmKeyUp = False : vpmFlips.FlipR False
				If keycode = keyStagedFlipperR Then ' as vbs will not evaluate the Case keyStagedFlipperR then, also handle it here
					vpmFlips.FlipUR False
					If cSingleRFlip Or Err Then .Switch(swURFlip) = False
				End If
			Case keyStagedFlipperL vpmFlips.FlipUL False : If cSingleLFlip Or Err Then .Switch(swULFlip) = False
			Case keyStagedFlipperR vpmFlips.FlipUR False : If cSingleRFlip Or Err Then .Switch(swURFlip) = False
			Case StartGameKey    .Switch(swStartButton) = False
			Case keyHiScoreReset .Switch(swHSReset)     = False
			Case keyAdvance      .Switch(swAdvance)     = False
			Case keyCPUDiag      .Switch(swCPUDiag)     = False
			Case keySoundDiag    .Switch(swSoundDiag)   = False
			Case keyMasterEnter  .Switch(swMasterEnter) = False
			Case keySlamDoorHit  .Switch(swSlamTilt)    = False
			Case keyShowOpts     .Pause = True : vpmShowOptions : .Pause = False
			Case keyShowKeys     .Pause = True : vpmShowHelp : .Pause = False
			Case keyAddBall      .Pause = True : vpmAddBall  : .Pause = False
			Case keyShowDips     If IsObject(vpmShowDips) Then .Pause = True : vpmShowDips : .Pause = False
			Case keyReset        .Stop : BeginModal : .Run : vpmTimer.Reset : EndModal
			Case keyFrame        .LockDisplay = Not .LockDisplay
			Case keyDoubleSize   .DoubleSize  = Not .DoubleSize
			Case Else            vpmKeyUp = False
		End Select
	End With
	On Error Goto 0
End Function
