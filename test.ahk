#Requires AutoHotkey v2.0
#SingleInstance Force

; Show per-adapter network traffic every second via ToolTip.
; Stop with Ctrl+Alt+Q.

intervalMs := 1000
logPath := "C:\\Users\\YS\\Documents\\AutoHotkey\\int_repo\\AHK_Int_Red.csv"
totals := Map()

SoundBeep 1000, 120
InitDisplay("Starting network monitor...")

SetTimer ShowTraffic, intervalMs
ShowTraffic()

OnExit WriteTotals

^!q::ExitApp

ShowTraffic() {
    data := GetNetStats()
    if data.Length = 0 {
        ShowText("No data (WMI?)")
        return
    }

    AccumulateTotals(data)
    ShowLines(data)
}

GetNetStats() {
    results := []
    try {
        svc := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
        query := "SELECT Name, BytesReceivedPerSec, BytesSentPerSec FROM Win32_PerfFormattedData_Tcpip_NetworkInterface"
        for obj in svc.ExecQuery(query) {
            name := obj.Name
            ; Skip pseudo/loopback/empty names
            if (name = "")
                continue

            downBps := obj.BytesReceivedPerSec
            upBps := obj.BytesSentPerSec

            down := FormatBytes(downBps)
            up := FormatBytes(upBps)

            results.Push({ name: name, down: down, up: up, downBps: downBps, upBps: upBps, hasTraffic: (downBps > 0 || upBps > 0) })
        }
    } catch as e {
        results.Push({ name: "WMI error", down: e.Message, up: "" })
    }
    return results
}

AccumulateTotals(items) {
    global totals, intervalMs
    seconds := intervalMs / 1000.0
    for item in items {
        if !totals.Has(item.name) {
            totals[item.name] := { down: 0.0, up: 0.0 }
        }
        totals[item.name].down += item.downBps * seconds
        totals[item.name].up += item.upBps * seconds
    }
}

WriteTotals(ExitReason := "", ExitCode := 0) {
    global totals, logPath

    dir := RegExReplace(logPath, "\\[^\\]+$")
    if !DirExist(dir) {
        DirCreate(dir)
    }

    lines := []
    lines.Push("Adapter,DownBytes,UpBytes")
    for name, v in totals {
        lines.Push('"' name '",' Round(v.down) "," Round(v.up))
    }
    if FileExist(logPath) {
        FileDelete logPath
    }
    FileAppend JoinLines(lines), logPath, "UTF-8"
}

JoinLines(arr) {
    out := ""
    for i, v in arr {
        out .= (i = 1 ? "" : "`n") v
    }
    return out
}

FormatBytes(bps) {
    ; bps is bytes per second
    if (bps >= 1048576)
        return Round(bps/1048576, 2) " MB/s"
    if (bps >= 1024)
        return Round(bps/1024, 1) " KB/s"
    return bps " B/s"
}

InitDisplay(text) {
    global gGui, gLineCtrls
    gGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    gGui.BackColor := "202020"
    gGui.SetFont("s16", "Segoe UI")
    gLineCtrls := []
    gLineCtrls.Push(gGui.AddText("w520", text))
    gGui.Show("x10 y10 NoActivate")
}

ShowText(text) {
    global gLineCtrls
    RebuildLines([text])
}

ShowLines(items) {
    lines := []
    for item in items {
        if (item.hasTraffic) {
            lines.Push(item)
        }
    }

    if (lines.Length = 0) {
        ShowText("No active traffic")
        return
    }

    RebuildLines(lines)
}

RebuildLines(lines) {
    global gGui, gLineCtrls
    idx := 0
    for item in lines {
        idx += 1
        if (IsObject(item)) {
            text := item.name ": " item.down " down / " item.up " up"
            color := PickColor(item.downBps, item.upBps)
        } else {
            text := item
            color := "FFFFFF"
        }

        if (idx <= gLineCtrls.Length) {
            ctrl := gLineCtrls[idx]
            ctrl.Value := text
            ctrl.Opt("c" color)
        } else {
            ctrl := gGui.AddText("w520 c" color, text)
            gLineCtrls.Push(ctrl)
        }
    }

    ; Hide extra controls if line count shrinks.
    while (gLineCtrls.Length > idx) {
        gLineCtrls.Pop()
    }

    gGui.Show("x10 y10 NoActivate")
}

PickColor(downBps, upBps) {
    maxBps := (downBps > upBps) ? downBps : upBps
    if (maxBps >= 1048576)
        return "FF6B6B"  ; >= 1 MB/s
    if (maxBps >= 102400)
        return "FFD166"  ; >= 100 KB/s
    if (maxBps >= 10240)
        return "9BE7FF"  ; >= 10 KB/s
    return "F2F2F2"      ; low traffic
}
