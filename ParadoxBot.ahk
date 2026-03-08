#Requires AutoHotkey v2.0
#Include OCR.ahk
#SingleInstance Force
#Warn All, Off
; КРИТИЧЕСКИЙ ФИКС №2: Работаем только с клиентской областью окна
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"


; ==============================================================================
; 🛠️ СЕКЦИЯ 1: ГЛОБАЛЬНЫЕ КОНСТАНТЫ И НАСТРОЙКИ (ЦЕМЕНТ)
; ==============================================================================

; Координаты взаимодействия с NPC
Global P_CreateX1  := 35,   P_CreateY1  := 336
Global P_CreateX2  := 97,   P_CreateY2  := 335
Global P_CreateX3  := 134,  P_CreateY3  := 332

; Точки выбора Актов
Global P_Act1_X1   := 382,  P_Act1_Y1   := 268
Global P_Act2_X1   := 388,  P_Act2_Y1   := 317
Global P_Act3_X1   := 385,  P_Act3_Y1   := 381

; Кнопки запуска (Start и подтверждение)
Global P_StartX1   := 43,   P_StartY1   := 514
Global P_FinalX1   := 553,  P_FinalY1   := 552

; Цвета режимов
Global ColorRaid   := 0x4D3341
Global ColorLegend := 0xFFD700  
Global ColorSiege  := 0xFF4500   

; Глобальные состояния
Global IsRunning   := false
Global CurrentLoc  := "Unknown"
Global SelectedMap := "Raid"
Global SelectedAct := "Act 3"
Global RobloxHwnd  := 0
Global LobbyCooldown := 0  ; Переменная-заглушка
global UnknownTimer := 0
global UnknownTimer := 0
Global UnitsPlaced := false  ; По умолчанию юниты НЕ расставлены

Global UnitPos     := [{x: 497, y: 199}, {x: 323, y: 264}, {x: 619, y: 500}, {x: 633, y: 268}, {x: 364, y: 482}, {x: 400, y: 400}]

class Config {
    static TG_TOKEN   := "7992090276:AAGEGuKRO1RLEp--LYzjxWtLE7Rf84DSt2A" 
    static TG_CHATID  := "1756517044"
    static SUPA_URL   := "https://bwarsgulwnkdeccndvwd.supabase.co" 
    static SUPA_KEY   := "sb_publishable_TppOnCNsZZHMKUnOCBdB2w_0WXAyjyC"
    static SUPA_TABLE := "farm_setting" 
    static GameW      := 800
    static GameH      := 600
    static OffsetX    := 40 
    static OffsetY    := 80 
}

; ==============================================================================
; 🎨 СЕКЦИЯ 2: ГЛАВНЫЙ ИНТЕРФЕЙС PARADOX SYSTEM
; ==============================================================================
MainGui := Gui("+Resize -MaximizeBox", "PARADOX SYSTEM [ULTIMATE V6.0]")
MainGui.BackColor := "0d1117"

MainGui.SetFont("s18 w700 c66a3ff", "Segoe UI")
MainGui.Add("Text", "x25 y20 w600", "⚡ PARADOX SYSTEM ULTIMATE")

MainGui.SetFont("s10", "Segoe UI")
MainGui.Add("GroupBox", "x20 y60 w840 h640 cGray", " 🟢 ROBLOX STREAM VIEW ") 
MainGui.Add("Text", "x40 y85 w800 h600 Background000000", "")

; Кнопки управления
MainGui.SetFont("s12 w600 cWhite")
BtnStart := MainGui.Add("Button", "x880 y85 w200 h65", "🚀 START (F4)")
BtnStart.OnEvent("Click", (*) => ToggleFarm())

MainGui.SetFont("s10 w600 c66a3ff")
BtnUnits := MainGui.Add("Button", "x880 y165 w200 h50", "🤖 НАСТРОЙКА ЮНИТОВ")
BtnUnits.OnEvent("Click", (*) => UnitsGui.Show("Center"))

; Настройки режима
MainGui.Add("Text", "x880 y230 w200 c66a3ff", "📍 ТЕКУЩАЯ КАРТА:")
ChoiceMap := MainGui.Add("DropDownList", "x880 y255 w200 Choose1", ["Raid", "Legend Portals", "Siege"])
; Убрали Global внутри скобок:
ChoiceMap.OnEvent("Change", (ctrl, *) => (SelectedMap := ctrl.Text, Log("Карта: " ctrl.Text)))

MainGui.Add("Text", "x880 y295 w200 c66a3ff", "🎭 ТЕКУЩИЙ АКТ:")
ChoiceAct := MainGui.Add("DropDownList", "x880 y320 w200 Choose3", ["Act 1", "Act 2", "Act 3"])
; Убрали Global внутри скобок:
ChoiceAct.OnEvent("Change", (ctrl, *) => (SelectedAct := ctrl.Text, Log("Акт: " ctrl.Text)))

; Лог-бокс
MainGui.SetFont("s9 w400 cGray")
MainGui.Add("Text", "x880 y365 w200", "ПОСЛЕДНИЕ СОБЫТИЯ:")
Global LogBox := MainGui.Add("Edit", "x880 y390 w200 h300 ReadOnly Background000000 c00FF00")

MainGui.OnEvent("Close", CloseApp)
MainGui.Show("w1120 h750 Center")

; ==============================================================================
; 🤖 СЕКЦИЯ 3: ОКНО НАСТРОЙКИ ПАРАМЕТРОВ ЮНИТОВ
; ==============================================================================
UnitsGui := Gui("+AlwaysOnTop", "PARADOX - UNIT CONFIGURATION")
UnitsGui.BackColor := "0d1117"
UnitsGui.SetFont("s10 w700 c66a3ff", "Segoe UI")
UnitsGui.Add("Text", "x20 y15 w400", "⚙️ НАСТРОЙКА ПАРАМЕТРОВ СЛОТОВ (1-6)")

Global EditNames := [], EditLimits := [], EditPriorities := [], CheckFirst := [], EditX := [], EditY := [], UnitsData := []

UnitsGui.SetFont("s8 w600 cGray")
UnitsGui.Add("Text", "x20 y55 w120", "ИМЯ")
UnitsGui.Add("Text", "x160 y55 w50", "ЛИМИТ")
UnitsGui.Add("Text", "x235 y55 w65", "ПРИОР.")
UnitsGui.Add("Text", "x335 y55 w25", "1ST")
UnitsGui.Add("Text", "x370 y55 w40", "X")
UnitsGui.Add("Text", "x425 y55 w40", "Y")

Loop 6 {
    YY := 55 + (A_Index * 35)
    UnitsGui.SetFont("s9 w400 cWhite")
    EditNames.Push(UnitsGui.Add("Edit", "x20 y" . YY . " w125 h26 Background161b22", "Unit " . A_Index))
    EditLimits.Push(UnitsGui.Add("Edit", "x160 y" . YY . " w50 h26 Background161b22", "4"))
    EditPriorities.Push(UnitsGui.Add("Edit", "x235 y" . YY . " w65 h26 Background161b22", A_Index))
    CheckFirst.Push(UnitsGui.Add("CheckBox", "x335 y" . YY . " w22 h26", ""))
    
    defX := (A_Index <= UnitPos.Length) ? UnitPos[A_Index].x : 400
    defY := (A_Index <= UnitPos.Length) ? UnitPos[A_Index].y : 300
    EditX.Push(UnitsGui.Add("Edit", "x370 y" . YY . " w50 h26 Background161b22", defX))
    EditY.Push(UnitsGui.Add("Edit", "x425 y" . YY . " w50 h26 Background161b22", defY))
    
    UnitsData.Push({Name: "", Limit: 4, Priority: A_Index, IsFirst: 0, x: defX, y: defY})
}

BtnSaveUnits := UnitsGui.Add("Button", "x20 y325 w460 h45", "💾 СОХРАНИТЬ КОНФИГУРАЦИЮ")
BtnSaveUnits.OnEvent("Click", SaveUnitsAndClose)

SaveUnitsAndClose(*) {
    global UnitsData
    Loop 6 {
        UnitsData[A_Index].Name := EditNames[A_Index].Value
        UnitsData[A_Index].Limit := Number(EditLimits[A_Index].Value)
        UnitsData[A_Index].Priority := Number(EditPriorities[A_Index].Value)
        UnitsData[A_Index].IsFirst := CheckFirst[A_Index].Value
        UnitsData[A_Index].x := Number(EditX[A_Index].Value)
        UnitsData[A_Index].y := Number(EditY[A_Index].Value)
    }
    UnitsGui.Hide()
    Log("✅ Координаты и настройки обновлены!")
}

; ==============================================================================
; ⚙️ СЕКЦИЯ 4: ВСПОМОГАТЕЛЬНЫЙ ФУНКЦИОНАЛ (API & UTILS)
; ==============================================================================
Log(msg) {
    timestamp := FormatTime(, "HH:mm:ss")
    LogBox.Value := "[" . timestamp . "] " . msg . "`r`n" . LogBox.Value
}

StopAutomation() {
    global IsRunning
    IsRunning := false
    SetTimer(FarmLoop, 0)
    Log("🛑 Автоматизация остановлена.")
}
; =========================
; 🎯 Расстановка юнитов
; =========================

; ==============================================================================
; 🛠️ ПОЛНЫЕ ФУНКЦИИ ДЛЯ ПОДСЧЕТА И ПОИСКА КНОПОК UPGRADE (800x600)
; ==============================================================================

GetAllAutoUpgradePositions() {
    positions := []
    currY := 0

    while (currY < 580) {

        startX := 0

        while ImageSearch(&fx, &fy,
            startX, currY,
            800, currY + 30,
            "*120 images/unit_check.png")
        {
            isNew := true
            for p in positions {
                if (Abs(p.x - fx) < 30 && Abs(p.y - fy) < 30) {
                    isNew := false
                    break
                }
            }

            if (isNew) {
                positions.Push({x: fx+20, y: fy+10})
            }

            startX := fx + 35
        }

        currY += 25
    }

    return positions
}

CountAutoUpgrades() {
    arr := GetAllAutoUpgradePositions()
    return arr.Length
}



; Твой настырный клик: наводится, шевелит мышкой и жмет 3 раза
StubbornClick(targetX, targetY) {
    MouseMove(targetX, targetY, 5)
    Sleep(200)
    Loop 3 {
        ; Микродвижение (jitter) на 2 пикселя, чтобы игра "увидела" мышь
        MouseMove(targetX + (A_Index-1)*2, targetY + (A_Index-1)*2, 2)
        Click("Down"), Sleep(150), Click("Up")
        Sleep(200)
    }
}

SmartClick(ImgName, variation := 130) {
    Loop 3 {
        MouseMove(780, 20, 0) 
        Sleep(500) 

        if ImageSearch(&CX, &CY, 0, 0, 800, 600, "*" . variation . " images/" . ImgName) {
            targetX := CX + 25
            targetY := CY + 20
            
            Log("🎯 Навожусь на " ImgName)
            MouseMove(targetX, targetY, 5) 
            Sleep(250) 

            Click("Down"), Sleep(150), Click("Up")
            
            MouseMove(780, 20, 0) 
            
            ; --- ВАЖНО: Ждем дольше, пока анимация кнопки ЗАКОНЧИТСЯ ---
            Log("⏳ Жду исчезновения " ImgName "...")
            Sleep(2000) 

            ; Проверяем исчезновение с БОЛЕЕ СТРОГИМ допуском (чтобы не видеть полупрозрачный след)
            if !ImageSearch(&PX, &PY, 0, 0, 800, 600, "*80 images/" . ImgName) {
                Log("✅ " ImgName " успешно нажата и исчезла.")
                return true
            }
            Log("⚠️ " ImgName " всё еще на экране. Пробую снова...")
        } else {
            return false
        }
    }
    return false
}




 if SmartClick("create_match.png") {
                    Sleep(1500)
                    
                    ; 1. Жмем КАРТУ, пока не увидим кнопки Актов (или просто жмем надежно)
                    StaticClick("map_select.png")
                    Sleep(1500)

                    ; 2. Жмем АКТ 3, пока не появится кнопка CONFIRM
                    Log("🎭 Пытаюсь выбрать Акт 3...")
                    Loop 5 {
                        StaticClick("act3_button.png")
                        Sleep(1500)
                        ; Если увидели кнопку подтверждения — значит Акт выбрался!
                        if ImageSearch(&CX, &CY, 0, 0, 800, 600, "*160 images/confirm_settings.png")
                            break
                        Log("⚠️ Акт 3 не выбрался, жму еще раз...")
                    }

                    ; 3. Жмем CONFIRM, пока не появится FINAL START
                    Log("⚙️ Подтверждаю настройки...")
                    Loop 5 {
                        FlashyClick("confirm_settings.png")
                        Sleep(1500)
                        ; Если появилась финальная кнопка — идем дальше
                        if ImageSearch(&CX, &CY, 0, 0, 800, 600, "*160 images/final_start.png")
                            break
                        Log("⚠️ Confirm не сработал, повтор...")
                    }

                    ; 4. Жмем FINAL START, пока он не исчезнет (уход в загрузку)
                    Log("🚀 Финальный старт...")
                    Loop 5 {
                        if !ImageSearch(&CX, &CY, 0, 0, 800, 600, "*160 images/final_start.png")
                            break
                        FlashyClick("final_start.png")
                        Sleep(2000)
                    }

                    Log("🏁 ВСЁ! Мы в игре.")
                    CurrentLoc := "Loading"
                }




WaitForImage(ImgName, timeout := 30000) {
    Log("⏳ Ожидание: " ImgName)
    start := A_TickCount
    Loop {
        if (!IsRunning) 
            return false
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*50 images/" . ImgName)
            return true
        if (A_TickCount - start > timeout) 
            return false
        Sleep(1000)
    }
}

; Функция для кнопок, которые ОСТАЮТСЯ на экране после клика
; Клик для кнопок, которые не исчезают (Area, Map, Units)
StaticClick(ImgName, variation := 130) {
    MouseMove(780, 20, 0)
    Sleep(400) 
    if ImageSearch(&CX, &CY, 0, 0, 800, 600, "*" . variation . " images/" . ImgName) {
        targetX := CX + 25
        targetY := CY + 20
        MouseMove(targetX, targetY, 5)
        Sleep(250)
        Click("Down"), Sleep(150), Click("Up")
        MouseMove(780, 20, 0)
        Sleep(1200)
        return true
    }
    return false
}

GetUnitsCount() {
    global RobloxHwnd
    ; Твои базовые координаты надписи (из F3)
    baseX := 960
    baseY := 280
    
    ; Ищем цифры от 0 до 6 (или до 8, если нужно)
    Loop 7 {
        currentDigit := A_Index - 1 ; Цикл даст 0, 1, 2, 3, 4, 5, 6
        
        ; Ищем картинку цифры в области надписи
        if ImageSearch(&foundX, &foundY, baseX-40, baseY-30, baseX+100, baseY+60, "*130 images/digit_" currentDigit ".png") {
            Log("🔢 Нашел цифру: " currentDigit)
            return currentDigit
        }
    }
    
    Log("⚠️ Цифра не найдена, считаю что 0")
    return 0
}



FlashyClick(ImgName) {

    Log("✨ Ловлю анимированную кнопку: " ImgName)
    start := A_TickCount

    ; Ищем только центральную область экрана (где confirm обычно находится)
    SearchLeft := A_ScreenWidth * 0.2
    SearchRight := A_ScreenWidth * 0.8
    SearchTop := A_ScreenHeight * 0.4
    SearchBottom := A_ScreenHeight * 0.9

    Loop {

        ; ✅ Очень большой допуск для анимации
        if ImageSearch(&CX, &CY,
            SearchLeft, SearchTop,
            SearchRight, SearchBottom,
            "*220 " A_ScriptDir "\images\" ImgName) {

            targetX := CX + 100
            targetY := CY + 40

            MouseMove(targetX, targetY, 4)
            Sleep(200)

            ; кликаем несколько раз чтобы точно прошло
            Click()
            Sleep(150)
            Click()

            Log("✅ Кнопка поймана и нажата.")
            return true
        }

        if (A_TickCount - start > 7000) {
            Log("❌ Не удалось поймать кнопку.")
            return false
        }

        Sleep(150)
    }
}



WaitForColor(x, y, color, timeout := 30000) {
    start := A_TickCount
    Loop {
        if (!IsRunning)
             return false
        if PixelSearch(&PX, &PY, x-10, y-10, x+10, y+10, color, 35)
            return true
        if (A_TickCount - start > timeout) 
            return false
        Sleep(1000)
    }
}

MultiClickArea(x, y, x2:=0, y2:=0, x3:=0, y3:=0) {
    points := [[x,y]]
    if (x2 != 0) points.Push([x2,y2])
    if (x3 != 0) points.Push([x3,y3])
    for pt in points {
        if (!IsRunning) 
            break
        MouseMove(pt[1], pt[2], 0)
        Loop 3 {
            Click(pt[1], pt[2])
            Sleep(150)
        }
    }
}

UpdateSupabase(isActive, mode) {
    if (Config.SUPA_URL == "")
         return
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        url := Config.SUPA_URL "/rest/v1/" Config.SUPA_TABLE "?id=eq.1"
        req.Open("PATCH", url, true)
        req.SetRequestHeader("apikey", Config.SUPA_KEY)
        req.SetRequestHeader("Content-Type", "application/json")
        payload := '{"is_active": ' (isActive ? "true" : "false") ', "mode": "' mode '"}'
        req.Send(payload)
    } catch Error as err {
        Log("📡 SupaErr: " err.Message)
    }
}

; Функция для автоматического определения ширины и высоты картинки
ImageGetSize(file, &w, &h) {
    if !FileExist(file) {
        w := 0, h := 0
        return false
    }
    try {
        wia := ComObject("WIA.ImageFile")
        wia.LoadFile(file)
        w := wia.Width
        h := wia.Height
        return true
    } catch {
        w := 100, h := 50 ; Значения по умолчанию
        return false
    }
}

ToggleFarm() {
    global IsRunning, RobloxHwnd
    if (!RobloxHwnd) {
        MsgBox("Ошибка: Окно Roblox не привязано! Нажмите F1.")
        return
    }
    IsRunning := !IsRunning
    BtnStart.Text := IsRunning ? "⏹ STOP (F4)" : "🚀 START (F4)"
    if (IsRunning) {
        Log("🚀 ЗАПУСК ЦИКЛА АВТОМАТИЗАЦИИ")
        SetTimer(FarmLoop, 1000)
    } else {
        Log("🛑 ПРИНУДИТЕЛЬНАЯ ОСТАНОВКА")
        SetTimer(FarmLoop, 0)
        Send("{w up}{a up}")
    }
}

; Превращает координаты окна в координаты экрана для OCR
ClientToScreenCoords(&x, &y) {
    global RobloxHwnd
    static pt := Buffer(8)
    NumPut("Int", x, pt, 0)
    NumPut("Int", y, pt, 4)
    ; Используем именно твой сохраненный хендл окна Roblox
    DllCall("ClientToScreen", "Ptr", RobloxHwnd, "Ptr", pt)
    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
}

; ==============================================================================
; 🚀 СЕКЦИЯ 5: ЕДИНЫЙ ДВИЖОК АВТОМАТИЗАЦИИ (FARM ENGINE)
; ==============================================================================

; ==============================================================================
; 🚀 ОБНОВЛЕННЫЙ ДВИЖОК АВТОМАТИЗАЦИИ (БЕЗ ЗАВИСАНИЙ)
; ==============================================================================

CheckLocation() {
    global Config
    w := 850
    h := 650
    
    ; Функция для сокращения пути к картинкам
    Img(name) => A_ScriptDir "\images\" name

    ; 1. Сначала YES (Если бой начался)
    if ImageSearch(&x, &y, 0, 0, w, h, "*160 " Img("yes_start.png"))
        return "InGame"

    ; 2. Потом Загрузка
    if ImageSearch(&x, &y, 0, 0, w, h, "*180 " Img("loading_icon.png"))
    || ImageSearch(&x, &y, 0, 0, w, h, "*180 " Img("pre_loading.png"))
        return "Loading"

    ; 3. В самом конце Лобби
    if ImageSearch(&x, &y, 0, 0, w, h, "*160 " Img("area_icon.png"))
        return "Lobby"

    return "Unknown"
}

FarmLoop() {
    global IsRunning, CurrentLoc, RobloxHwnd, Config, UnknownTimer, UnitsPlaced

    if (!IsRunning || !RobloxHwnd)
        return

    ; 1. СНАЧАЛА получаем значение локации!
    Loc := CheckLocation()

    ; Фокусируем окно
    if !WinActive("ahk_id " RobloxHwnd) {
        WinActivate("ahk_id " RobloxHwnd)
        Sleep(300)
    }

    ; Теперь проверяем переход из загрузки (чтобы не было ошибки "Unset")
    if (CurrentLoc = "Loading" && Loc != "Loading") {
        Log("📡 Вышли из загрузки, жду стабилизации 2 сек...")
        Sleep(2000)
        ; После сна перепроверяем локацию, вдруг она сменилась
        Loc := CheckLocation()
    }

    Log("📍 Текущая локация: " Loc)

    ; ==============================================================================
    ; 🌑 UNKNOWN (Если ничего не нашли)
    ; ==============================================================================
    if (Loc = "Unknown") {
        if (!UnknownTimer) UnknownTimer := A_TickCount
        
        ; Если мы в режиме Loading, то Unknown — это нормально (черный экран)
        if (CurrentLoc = "Loading") {
            Log("⏳ Черный экран загрузки... ждем.")
        } else if (A_TickCount - UnknownTimer > 20000) {
            Log("⚠️ Слишком долго Unknown. Перезапуск...")
            StopAutomation()
            return
        }
        
        SetTimer(FarmLoop, -1000) ; Перезапуск через 1 сек
        return
    }
    UnknownTimer := 0

    ; ==============================================================================
    ; ⏳ LOADING (Процесс загрузки)
    ; ==============================================================================
    if (Loc = "Loading") {
        CurrentLoc := "Loading"
        Log("⏳ Статус: Загрузка. Ждем появления Yes_start...")
        
        SetTimer(FarmLoop, -1000) ; Перезапуск через 1 сек
        return
    }

    ; ==============================================================================
    ; 🏠 LOBBY (Действия в лобби)
    ; ==============================================================================
        if (Loc = "Lobby") {
        if (CurrentLoc != "Lobby") {
            CurrentLoc := "Lobby"
            UnitsPlaced := false  ; <--- ОБЯЗАТЕЛЬНО СБРОСИТЬ ТУТ!
            Log("🏠 Статус: В лобби. Сброс флага юнитов.")
            UpdateSupabase(true, "Lobby")
        }
        ; ... остальной код лобби


        ; Проверка: открыто ли меню?
        if !ImageSearch(&RX, &RY, 0, 0, 800, 600, "*160 " A_ScriptDir "\images\raid_icon.png") {
            Log("💠 Меню закрыто. Жму Area...")
            StaticClick("area_icon.png")
            Sleep(2000)
            SetTimer(FarmLoop, -500)
            return
        }

        Log("💠 Вхожу в портал...")
        StaticClick("raid_icon.png"), Sleep(800)
        
        Log("🏃 Бег к порталу (15 сек)...")
        Send("{w down}")
        loop 150 {
            if !IsRunning {
                Send("{w up}")
                return
            }
            Sleep(100)
        }
        Send("{w up}"), Sleep(2000)

        ; --- ЦЕПОЧКА ВХОДА ---
        Log("🔘 Create Match")
        MultiClickArea(99,344, 101,346, 97,342), Sleep(3000)

        Log("🔘 Map Select")
        MultiClickArea(211,258, 213,260, 209,256), Sleep(2000)

        Log("🎭 Act 3")
        MultiClickArea(384,396, 386,398, 382,394), Sleep(2000)

        Log("⚙️ Confirm Settings")
        MultiClickArea(554,570, 556,572, 552,568), Sleep(2500)

        Log("🚀 FINAL START!")
        MultiClickArea(72,519, 74,521, 70,517)

        Log("🏁 Кнопка нажата! Перехожу в режим ожидания загрузки.")
        CurrentLoc := "Loading"
        SetTimer(FarmLoop, -3000) ; Даем 3 сек паузы и запускаем цикл заново
        return
    }

    
    ; ==============================================================================
; 🎮 IN GAME: КАМЕРА + УМНАЯ РАССТАНОВКА + AUTO UPGRADE
; ==============================================================================
if (Loc = "InGame") {
    if (CurrentLoc != "InGame") {
        CurrentLoc := "InGame"
        Log("🎮 Статус: В игре! Настраиваю обзор...")
        
        ; --- 1. ОЖИВЛЕНИЕ ПЕРСОНАЖА ---
        Send("{w down}"), Sleep(600), Send("{w up}")
        Sleep(300)

        ; --- 2. НАСТРОЙКА КАМЕРЫ (ВИД СВЕРХУ) ---
        Log("🎥 Наклон камеры вниз...")
        Loop 5 {
            Send("{WheelDown}"), Sleep(100)
        }
        
        MouseMove(400, 300, 0) 
        Sleep(200), Send("{RButton down}"), Sleep(200)
        ; Mouse_event для плавного и точного разворота
        DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", -500, "UInt", 0, "UPtr", 0)
        Sleep(500), Send("{RButton up}")
        Log("✅ Камера готова.")

        ; --- 3. ПОДГОТОВКА (EXTREME MODE) ---
        Log("⌨️ Активация Extreme Mode (F)...")
        Send("{f down}"), Sleep(200), Send("{f up}") 
        Sleep(1500) 
        
        if ImageSearch(&fx, &fy, 0, 0, 800, 600, "*130 " A_ScriptDir "\images\yes_start.png") {
            Click(fx + 15, fy + 10)
            Log("✅ Старт подтвержден.")
            Sleep(2000)
        }
    }

    ; --- 4. УМНАЯ РАССТАНОВКА (С КОНТРОЛЕМ БАЛАНСА) ---
    if (UnitsPlaced = false) {
        Log("🛠️ Начало расстановки юнитов...")

        ; Сортировка по приоритету (Bubble Sort)
        SortedUnits := []
        for item in UnitsData
            SortedUnits.Push(item)
        
        Loop SortedUnits.Length {
            i := A_Index
            Loop SortedUnits.Length - i {
                j := A_Index
                if (SortedUnits[j].Priority > SortedUnits[j+1].Priority) {
                    temp := SortedUnits[j], SortedUnits[j] := SortedUnits[j+1], SortedUnits[j+1] := temp
                }
            }
        }

        for unit in SortedUnits {
            if (!IsRunning)
                 break
            if (unit.Limit <= 0) 
                continue

            currentCount := 0
            Log("📍 Слот " unit.Priority " [" unit.Name "] | Цель: " unit.Limit)

            while (currentCount < unit.Limit) {
                if (!IsRunning) 
                    break
                
                Before := CountAutoUpgrades()
                
                Send("{" unit.Priority " down}"), Sleep(150), Send("{" unit.Priority " up}")
                Sleep(400)
                Click(unit.x, unit.y)
                Sleep(1200)

                if (CountAutoUpgrades() > Before) {
                    currentCount++
                    Log("✅ Поставлен: " currentCount "/" unit.Limit)
                } else {
                    Log("💰 Ожидание средств на " unit.Name "...")
                    waitStart := A_TickCount
                    moneyFound := false
                    
                    Loop {
                        if (!IsRunning || A_TickCount - waitStart > 25000)
                             break 
                        
                        if (Mod(A_Index, 4) = 0) { 
                            Send("{" unit.Priority "}"), Sleep(200), Click(unit.x, unit.y)
                        }
                        
                        if (CountAutoUpgrades() > Before) {
                            currentCount++, moneyFound := true
                            Log("✅ Юнит дожат!")
                            break
                        }
                        Sleep(800)
                    }
                    if (!moneyFound)
                         break 
                }
            }
        }

        ; --- 5. АКТИВАЦИЯ AUTO UPGRADE ---
        Log("⚡ Включаю Auto Upgrade для всех слотов...")
        for index, unit in SortedUnits {
            Loop unit.Limit {
                Send("{" unit.Priority "}")
                Sleep(450)
                if ImageSearch(&fx, &fy, 0, 0, 800, 600, "*120 images/unit_check.png") {
                    Click(fx + 20, fy + 10)
                    Sleep(300)
                }
            }
        }

        UnitsPlaced := true 
        Log("🏁 Деплой завершен. Режим фарма активен!")
    }

    SetTimer(FarmLoop, -5000)
    return
}
}
; ==============================================================================
; ⌨️ СЕКЦИЯ 6: ГОРЯЧИЕ КЛАВИШИ И УПРАВЛЕНИЕ
; ==============================================================================

F1:: {
    global RobloxHwnd, Config

    RobloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !RobloxHwnd {
        Log("❌ Roblox не найден!")
        return
    }

    WinSetStyle("-0xC00000", "ahk_id " RobloxHwnd)
    WinMove(100, 100, 800, 600, "ahk_id " RobloxHwnd)

    WinGetClientPos(&cX, &cY, &cW, &cH, "ahk_id " RobloxHwnd)
    Config.GameW := cW
    Config.GameH := cH

    WinActivate("ahk_id " RobloxHwnd)

    Log("✅ Размер клиента: " cW "x" cH)
}

F2:: {
    global RobloxHwnd
    if (RobloxHwnd) {
        WinSetStyle("+0xC00000", "ahk_id " RobloxHwnd)
        Log("🆓 Roblox освобожден.")
        RobloxHwnd := 0
    }
}

F3:: {
    MouseGetPos(&mX, &mY)
    color := PixelGetColor(mX, mY)
    Log("📍 X" mX " Y" mY " | Цвет: " color)
}

F6:: {
    if ImageSearch(&x,&y,0,0,800,600,"*120 images/area_icon.png")
        MsgBox("Нашёл Area")
    else
        MsgBox("НЕ нашёл")
}

F9:: {
    ImgPath := A_ScriptDir "\images\unit_check.png"
    
    if !FileExist(ImgPath) {
        MsgBox("❌ Ошибка: Файл unit_check.png не найден в папке images!")
        return
    }

    Log("🔍 Тестирую поиск Auto Upgrade...")
    
    ; Ищем картинку по всему экрану (Screen coordinates)
    if ImageSearch(&uX, &uY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*145 " . ImgPath) {
        ; Рисуем временную рамку там, где бот нашел кнопку
        ToolTip("🎯 НАШЕЛ ТУТ!", uX, uY)
        Log("✅ УСПЕХ! Нашел на X:" uX " Y:" uY)
        
        ; Пробуем кликнуть (проверка связи)
        MouseMove(uX + 10, uY + 5, 5)
        
        MsgBox("Бот УВИДЕЛ кнопку!`nКоординаты: " uX ", " uY "`n`nСейчас мышь навелась на нее.")
        ToolTip()
    } else {
        MsgBox("❌ НЕ ВИЖУ кнопку!`n`nСоветы:`n1. Открой Unit Manager в игре вручную.`n2. Убедись, что окно Roblox не перекрыто.`n3. Попробуй переделать скриншот unit_check.png (сделай его поменьше).")
        Log("⚠️ Поиск не дал результатов.")
    }
}



F4::ToggleFarm()
F10::Reload()
Esc::CloseApp()

CloseApp(*) {
    if (RobloxHwnd) WinSetStyle("+0xC00000", "ahk_id " RobloxHwnd)
    ExitApp()
}