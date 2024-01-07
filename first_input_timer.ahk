#SingleInstance, Force
#Include <overlay_class>
#Include <Jxon>
SetWorkingDir, %A_ScriptDir%

global first_time_user := false

global currentColor := "FF0000"
global currentBGColor := "00FF00"
global stepSize := 0.5 
global running := false
global paused := false

if (!FileExist(A_ScriptDir . "\first_input_timer_settings.json"))
{
    first_time_user := true
    first_time_user_overlay := new Overlay("first_time_user_overlay", "No settings file detected. Press F3 to open settings menu.", 10, 10, 1, 25, false, "FFFFFF", true, "Black", 15)
    dimensions := first_time_user_overlay.get_dimensions()
    first_time_user_overlay.update_position((A_ScreenWidth-dimensions[1])//2, (A_ScreenHeight-dimensions[2])//2)
    first_time_user_overlay.toggle_visibility()
    first_time_user_overlay.toggle_background_visibility()
    first_time_user_overlay.background_transparency(60)
    
    Hotkey, F3, open_settings_GUI

    global start_inputs := []
    global reset_input := "F2"
    global open_settings_key := "F3"
    global timer_format := [false, true, true, true, 2]
    global text_color := "FFFFFF"
    global text_size := 25
    global text_font := "Helvetica"
    global text_position := "Bottom Right"
    global background_color := "000000"
    global background_opacity := 100
}
Else 
{
    FileRead, file_contents, % A_ScriptDir . "\first_input_timer_settings.json"
    
    ; Parse the JSON content
    settings := Jxon_Load(file_contents)

    global start_inputs := settings.startInputs
    global reset_input := settings.resetInput
    global open_settings_key := settings.openSettingsKey
    global timer_format := settings.timerFormat
    global text_color := settings.textColor
    global text_size := settings.textSize
    global text_font := settings.textFont
    global text_position := settings.textPosition
    global background_color := settings.backgroundColor
    global background_opacity := settings.backgroundOpacity

    Hotkey, % "~" open_settings_key , open_settings_GUI
    
    d2_binds := get_d2_keybinds(start_inputs)
    if (!d2_binds)
    {
        MsgBox, Cannot find Destiny 2 cvars file, program will exit
        ExitApp
    }

    for action, bind in d2_binds
        Hotkey, % "~$" bind, start_timer
    Hotkey, % "~" reset_input, stop_timer
    timer_text := "!timer" . timer_format[1] . timer_format[2] . timer_format[3] . timer_format[4] . timer_format[5]

    global input_timer_overlay := new Overlay("input_timer_overlay", timer_text, 0, 0, text_font, text_size, false, text_color, true, background_color, 15)
    
    dimensions := input_timer_overlay.get_dimensions()

    if (InStr(text_position, "Top"))
        y_pos := 15
    else
        y_pos := A_ScreenHeight-dimensions[2]
    if (InStr(text_position, "Left"))
        x_pos := 15
    else
        x_pos := A_ScreenWidth-dimensions[1]

    input_timer_overlay.update_position(x_pos, y_pos)
    input_timer_overlay.toggle_visibility()
    input_timer_overlay.toggle_background_visibility()
    input_timer_overlay.background_transparency(background_opacity)
}

; settings GUI
; ------------------------------------------------------------------ ;

    Gui, settings: +LastFound -Caption +Border +hWndSettingsGUI +Owner +AlwaysOnTop
    Gui, settingsBG: -Caption -Border +AlwaysOnTop +hWndSettingsBGGUI +ToolWindow
    Gui, settings: Color, 000001
    Gui, settingsBG: Color, 000000
    Gui, settings: Font, s11 cWhite bold, Segoe UI
    Gui, settings: Add, Text, y10 , Select which actions start the timer
    is_checked := (HasVal(start_inputs, "fire")) ? "1" : "0"
    Gui, settings: Add, Checkbox, % "x35 y50 vStartInput_fire Checked" is_checked, fire
    actions := ["melee", "melee_uncharged", "melee_charged", "grenade", "super", "light_attack", "heavy_attack", "switch_weapons", "next_weapon", "previous_weapon", "primary_weapon", "special_weapon", "heavy_weapon", "move_forward", "move_backward", "move_left", "move_right", "jump", "toggle_crouch", "hold_crouch", "toggle_sprint", "hold_sprint", "interact"]
    for _, action in actions 
    {
        is_checked := (HasVal(start_inputs, action)) ? "1" : "0"
        Gui, settings: Add, Checkbox, % "x35 vStartInput_" action " Checked" is_checked, %action%
    }

    Gui, settings: Add, Groupbox, x15 y30 w263 h695,

    Gui, settings: Add, Text, x290 y10, Stop/Reset Timer Hotkey
    Gui, settings: Font, cBlack
    Gui, settings: Add, Hotkey, w290 vResetInput, %reset_input%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Open Settings Hotkey
    Gui, settings: Font, cBlack
    Gui, settings: Add, Hotkey, w290 vOpenSettingsKey, %open_settings_key%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Timer Format
    Gui, settings: Add, Checkbox, % "vTimerFormat1 Checked" ((timer_format[1]) ? "1" : "0"), Hours
    Gui, settings: Add, Checkbox, % "vTimerFormat2 Checked" ((timer_format[2]) ? "1" : "0"), Minutes
    Gui, settings: Add, Checkbox, % "vTimerFormat3 Checked" ((timer_format[3]) ? "1" : "0"), Seconds
    Gui, settings: Add, Checkbox, % "vTimerFormat4 Checked" ((timer_format[4]) ? "1" : "0"), Milliseconds
    Gui, settings: Add, Text, , Decimal Places:
    Gui, settings: Font, cBlack
    Gui, settings: Add, Edit, vTimerFormat5 x410 y275 w100, 2
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, x290 y310, Text Color
    Gui, settings: Font, cBlack
    Gui, settings: Add, Edit, w100 vTextColor, %text_color%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Font Size
    Gui, settings: Font, cBlack
    Gui, settings: Add, Edit, w100 vTextSize, %text_size%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Timer Font
    Gui, settings: Font, cBlack
    Gui, settings: Add, Edit, w200 vTextFont, %text_font%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Timer Position
    Gui, settings: Add, DropDownList, w200 vTextPosition, % StrReplace("Top Left|Top Right|Bottom Left|Bottom Right|", text_position, text_position . "|")

    Gui, settings: Add, Text, , Background Color
    Gui, settings: Font, cBlack
    Gui, settings: Add, Edit, w100 vBackgroundColor, %background_color%
    Gui, settings: Font, cWhite

    Gui, settings: Add, Text, , Background Opacity
    Gui, settings: Add, Slider, w290 Range0-100 ToolTipBottom vBackgroundOpacity, %background_opacity%

    Gui, settings: Add, Button, x290 y695 w290 h30 gSaveSettings, Save and Apply Settings
    EnableBlur(SettingsGUI)

; ------------------------------------------------------------------ ;

if (text_color == "RGB" || text_color == "rgb" || text_color == "rainbow" || text_color == "Rainbow" || text_color == "RAINBOW" || background_color == "RGB" || background_color == "rgb" || background_color == "rainbow" || background_color == "Rainbow" || background_color == "RAINBOW")
    SetTimer, UpdateColor, 20

return

start_timer:
    if (!running && !paused)
    {
        paused := false 
        running := true 
        input_timer_overlay.toggle_timer("start")
    }
return

stop_timer:
    if (paused)
    {
        paused := false 
        input_timer_overlay.toggle_timer("stop")
    }
    if (running)
    {
        paused := true 
        running := false 
        input_timer_overlay.toggle_timer("pause")
    }
return

open_settings_GUI:
{
    first_time_user_overlay.toggle_visibility("hide")
    first_time_user_overlay.toggle_background_visibility("hide")
    Hotkey, % open_settings_key, Off
    Gui, settingsBG: Show, w595 h740, Timer Settings BG
    Winset, Transparent, 60, % "ahk_id " SettingsBGGUI
    Gui, settings: Show, w595 h740, Timer Settings
    return
}

SaveSettings:
    Gui, settingsBG: Hide
    Gui, settings: Submit  ; Retrieve values from GUI controls
    settings := {}
    settings.startInputs := []
    actions := ["fire", "melee", "melee_uncharged", "melee_charged", "grenade", "super", "light_attack", "heavy_attack", "switch_weapons", "next_weapon", "previous_weapon", "primary_weapon", "special_weapon", "heavy_weapon", "move_forward", "move_backward", "move_left", "move_right", "jump", "toggle_crouch", "hold_crouch", "toggle_sprint", "hold_sprint", "interact"]
    for _, action in actions {
        if (StartInput_%action%)
            settings.startInputs.Push(action)
    }
    settings.resetInput := ResetInput
    settings.openSettingsKey := OpenSettingsKey
    settings.timerFormat := [TimerFormat1 = "1", TimerFormat2 = "1", TimerFormat3 = "1", TimerFormat4 = "1", TimerFormat5]
    settings.textColor := TextColor
    settings.textSize := TextSize
    settings.textFont := TextFont
    settings.textPosition := TextPosition
    settings.backgroundColor := BackgroundColor
    settings.backgroundOpacity := BackgroundOpacity

    ; Convert settings to JSON format (using a function you will define)
    jsonSettings := ConvertToJSON(settings)

    ; Save JSON to a file
    FileDelete, %A_ScriptDir%\first_input_timer_settings.json
    FileAppend, %jsonSettings%, %A_ScriptDir%\first_input_timer_settings.json  ; Specify your desired file path
    reload
Return

get_d2_keybinds(k) 
{
    FileRead, f, % A_AppData "\Bungie\DestinyPC\prefs\cvars.xml"
    if ErrorLevel 
        return False
    b := {}, t := {"shift": "LShift", "control": "LCtrl", "alt": "LAlt", "menu": "AppsKey", "insert": "Ins", "delete": "Del", "pageup": "PgUp", "pagedown": "PgDn", "keypad`/": "NumpadDiv", "keypad`*": "NumpadMult", "keypad`-": "NumpadSub", "keypad`+": "NumpadAdd", "keypadenter": "NumpadEnter", "leftmousebutton": "LButton", "middlemousebutton": "MButton", "rightmousebutton": "RButton", "extramousebutton1": "XButton1", "extramousebutton2": "XButton2", "mousewheelup": "WheelUp", "mousewheeldown": "WheelDown", "escape": "Esc"}
    for _, n in k 
        RegExMatch(f, "<cvar\s+name=""`" n `"""\s+value=""([^""]+)""", m) ? b[n] := t.HasKey(k2 := StrReplace((k1 := StrSplit(m1, "!")[1]) != "unused" ? k1 : k1[2], " ", "")) ? t[k2] : k2 : b[n] := "unused"
    return b
}

UpdateColor:
    if (text_color == "RGB" || text_color == "rgb" || text_color == "rainbow" || text_color == "Rainbow" || text_color == "RAINBOW")
    {
        newColor := NextRainbowColor(currentColor, stepSize)
        input_timer_overlay.change_color(newColor)
        currentColor := newColor
    }
    
    if (background_color == "RGB" || background_color == "rgb" || background_color == "rainbow" || background_color == "Rainbow" || background_color == "RAINBOW")
    {
        newBGColor := NextRainbowColor(currentBGColor, stepSize)
        input_timer_overlay.change_background_color(newBGColor)
        currentBGColor := newBGColor
    }
return

; Function to convert RGB to HSL
RGBtoHSL(r, g, b, ByRef h, ByRef s, ByRef l) {
    r := r / 255, g := g / 255, b := b / 255
    max := Max(Max(r, g), b), min := Min(Min(r, g), b)
    l := (max + min) / 2

    if (max = min) {
        h := 0, s := 0
    } else {
        d := max - min
        s := l > 0.5 ? d / (2 - max - min) : d / (max + min)
        if (max = r)
            h := (g - b) / d + (g < b ? 6 : 0)
        else if (max = g)
            h := (b - r) / d + 2
        else
            h := (r - g) / d + 4
        h /= 6
    }
}

; Function to convert HSL to RGB
HSLtoRGB(h, s, l, ByRef r, ByRef g, ByRef b) {
    if (s = 0) {
        r := g := b := l
    } else {
        q := l < 0.5 ? l * (1 + s) : l + s - l * s
        p := 2 * l - q
        r := HueToRGB(p, q, h + 1/3)
        g := HueToRGB(p, q, h)
        b := HueToRGB(p, q, h - 1/3)
    }
    r := Round(r * 255), g := Round(g * 255), b := Round(b * 255)
}

; Helper function for HSLtoRGB
HueToRGB(p, q, t) {
    if (t < 0)
        t += 1
    if (t > 1)
        t -= 1
    if (t < 1/6)
        return p + (q - p) * 6 * t
    if (t < 1/2)
        return q
    if (t < 2/3)
        return p + (q - p) * (2/3 - t) * 6
    return p
}

; Main function to get the next color in rainbow
NextRainbowColor(hexColor, stepSize) {
    ; Convert the hex color to RGB values
    r := "0x" . SubStr(hexColor, 1, 2)
    g := "0x" . SubStr(hexColor, 3, 2)
    b := "0x" . SubStr(hexColor, 5, 2)

    ; Convert RGB to HSL
    RGBtoHSL(r, g, b, h, s, l)

    ; Increment hue by step size
    h := Mod(h + stepSize / 360, 1)

    ; Convert HSL back to RGB
    HSLtoRGB(h, s, l, r, g, b)

    ; Convert RGB back to hex and return the color
    return Format("{:02X}{:02X}{:02X}", r, g, b)
}

EnableBlur(hWnd)
{
  ;Function by qwerty12 and jNizM (found on https://autohotkey.com/boards/viewtopic.php?t=18823)

  ;WindowCompositionAttribute
  WCA_ACCENT_POLICY := 19
 
  ;AccentState
  ACCENT_DISABLED := 0,
  ACCENT_ENABLE_GRADIENT := 1,
  ACCENT_ENABLE_TRANSPARENTGRADIENT := 2,
  ACCENT_ENABLE_BLURBEHIND := 3,
  ACCENT_INVALID_STATE := 4

  accentStructSize := VarSetCapacity(AccentPolicy, 4*4, 0)
  NumPut(ACCENT_ENABLE_BLURBEHIND, AccentPolicy, 0, "UInt")
 
  padding := A_PtrSize == 8 ? 4 : 0
  VarSetCapacity(WindowCompositionAttributeData, 4 + padding + A_PtrSize + 4 + padding)
  NumPut(WCA_ACCENT_POLICY, WindowCompositionAttributeData, 0, "UInt")
  NumPut(&AccentPolicy, WindowCompositionAttributeData, 4 + padding, "Ptr")
  NumPut(accentStructSize, WindowCompositionAttributeData, 4 + padding + A_PtrSize, "UInt")
 
  DllCall("SetWindowCompositionAttribute", "Ptr", hWnd, "Ptr", &WindowCompositionAttributeData)
}

ConvertToJSON(settings) {
    json := "{"
    for key, value in settings {
        json .= """" key """:"
        if (IsObject(value)) {
            json .= "["
            for index, subValue in value {
                json .= """" subValue """"
                if (index < value.MaxIndex())
                    json .= ","
            }
            json .= "]"
        } else {
            json .= """" value """"
        }
        json .= ","
    }
    json := RTrim(json, ",")  ; Remove the last comma
    json .= "}"
    return json
}

HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}