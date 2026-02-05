#Requires AutoHotkey v2.0
#SingleInstance Force

; 1) Ctrl+Alt+1：開記事本並輸入內容
^!1:: {
    Run "notepad.exe"
    WinWaitActive "ahk_exe notepad.exe", , 2
    Send "這是 AHK 自動化輸入`n第二行"
}

; 2) Ctrl+Alt+2：自動複製當前選取文字並彈出
^!2:: {
    A_Clipboard := ""           ; 清空剪貼簿
    Send "^c"
    if ClipWait(1)
        MsgBox "你複製的是:`n" A_Clipboard
    else
        MsgBox "複製失敗（可能沒有選取文字）"
}

; 3) Ctrl+Alt+3：把滑鼠移到螢幕中央並點一下
^!3:: {
    CoordMode "Mouse", "Screen"
    MouseMove A_ScreenWidth/2, A_ScreenHeight/2, 10
    Click
}
