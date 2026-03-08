#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"
CoordMode "Pixel", "Client"

F3:: {
    MouseGetPos &x, &y
    color := PixelGetColor(x, y)
    A_Clipboard := "X: " . x . ", Y: " . y . " Color: " . color
    MsgBox("Координаты скопированы!`n" . "X: " . x . " Y: " . y . "`nЦвет: " . color)
}

Esc::ExitApp