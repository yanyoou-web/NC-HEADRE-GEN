Option Explicit

Const APP_NAME = "NC-HEADRE-GEN"
Const HTML_FILE_NAME = "index.html"
Const REQUIRED_WIDTH = 624
Const REQUIRED_HEIGHT = 980
Const LAUNCHER_VERSION = "2026.07.23.3"

Dim appTitle
Dim shell
Dim fso
Dim appFolder
Dim preferredAppFolder
Dim desktopAppFolder
Dim targetAppFolder
Dim htmlPath
Dim fileUrl
Dim edgePath
Dim edgeUserDataFolder
Dim logFolder
Dim logPath
Dim lockPath
Dim hasLaunchLock
Dim waitCount
Dim launchResult
Dim launchCommand
Dim launchErrorNumber
Dim launchErrorDescription
Dim launchedWindowFound

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

logFolder = fso.BuildPath( _
    shell.ExpandEnvironmentStrings("%LOCALAPPDATA%"), APP_NAME)
logPath = fso.BuildPath(logFolder, "launcher.log")

appTitle = "NC" & _
    ChrW(&H30D8) & ChrW(&H30C3) & ChrW(&H30C0) & ChrW(&H30FC) & _
    ChrW(&H30B8) & ChrW(&H30A7) & ChrW(&H30CD) & ChrW(&H30EC) & _
    ChrW(&H30FC) & ChrW(&H30BF) & ChrW(&H30FC)

Function UnicodeText(ByVal hexValues)
    Dim values
    Dim value
    Dim result

    values = Split(hexValues, " ")
    result = ""

    For Each value In values
        result = result & ChrW(CLng("&H" & value))
    Next

    UnicodeText = result
End Function

Function QuoteArgument(ByVal value)
    QuoteArgument = Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function

Function PercentByte(ByVal value)
    PercentByte = "%" & Right("0" & Hex(value), 2)
End Function

Function EncodeUrlPath(ByVal value)
    Dim result
    Dim position
    Dim character
    Dim codePoint
    Dim lowCode

    result = ""
    position = 1

    Do While position <= Len(value)
        character = Mid(value, position, 1)
        codePoint = AscW(character)
        If codePoint < 0 Then
            codePoint = codePoint + 65536
        End If

        If codePoint >= 55296 And codePoint <= 56319 And _
            position < Len(value) Then

            lowCode = AscW(Mid(value, position + 1, 1))
            If lowCode < 0 Then
                lowCode = lowCode + 65536
            End If

            If lowCode >= 56320 And lowCode <= 57343 Then
                codePoint = 65536 + _
                    (codePoint - 55296) * 1024 + _
                    (lowCode - 56320)
                position = position + 1
            End If
        End If

        If (codePoint >= 48 And codePoint <= 57) Or _
            (codePoint >= 65 And codePoint <= 90) Or _
            (codePoint >= 97 And codePoint <= 122) Or _
            codePoint = 45 Or codePoint = 46 Or codePoint = 47 Or _
            codePoint = 58 Or codePoint = 95 Or codePoint = 126 Then

            result = result & Chr(codePoint)
        ElseIf codePoint <= 127 Then
            result = result & PercentByte(codePoint)
        ElseIf codePoint <= 2047 Then
            result = result & _
                PercentByte(192 + Int(codePoint / 64)) & _
                PercentByte(128 + (codePoint Mod 64))
        ElseIf codePoint <= 65535 Then
            result = result & _
                PercentByte(224 + Int(codePoint / 4096)) & _
                PercentByte(128 + (Int(codePoint / 64) Mod 64)) & _
                PercentByte(128 + (codePoint Mod 64))
        Else
            result = result & _
                PercentByte(240 + Int(codePoint / 262144)) & _
                PercentByte(128 + (Int(codePoint / 4096) Mod 64)) & _
                PercentByte(128 + (Int(codePoint / 64) Mod 64)) & _
                PercentByte(128 + (codePoint Mod 64))
        End If

        position = position + 1
    Loop

    EncodeUrlPath = result
End Function

Sub AddScriptLine(ByRef scriptText, ByVal lineText)
    scriptText = scriptText & lineText & vbCrLf
End Sub

Sub WriteLauncherLog(ByVal message)
    Dim logFile

    On Error Resume Next
    If Not fso.FolderExists(logFolder) Then
        fso.CreateFolder logFolder
    End If

    Set logFile = fso.OpenTextFile(logPath, 8, True, -1)
    If Err.Number = 0 Then
        logFile.WriteLine _
            Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & _
            Right("0" & Day(Now), 2) & " " & _
            Right("0" & Hour(Now), 2) & ":" & _
            Right("0" & Minute(Now), 2) & ":" & _
            Right("0" & Second(Now), 2) & " " & message
        logFile.Close
    End If
    On Error GoTo 0
End Sub

Function FindEdgePath()
    Dim candidate

    FindEdgePath = ""

    candidate = shell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & _
        "\Microsoft\Edge\Application\msedge.exe"
    If fso.FileExists(candidate) Then
        FindEdgePath = candidate
        Exit Function
    End If

    candidate = shell.ExpandEnvironmentStrings("%ProgramFiles%") & _
        "\Microsoft\Edge\Application\msedge.exe"
    If fso.FileExists(candidate) Then
        FindEdgePath = candidate
        Exit Function
    End If

    candidate = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & _
        "\Microsoft\Edge\Application\msedge.exe"
    If fso.FileExists(candidate) Then
        FindEdgePath = candidate
    End If
End Function

Function RestoreAndPositionEdgeWindow(ByVal windowTitle, ByVal useCursorMonitor)
    Dim tempFolder
    Dim tempPsPath
    Dim psFile
    Dim psScript
    Dim powerShellPath
    Dim command
    Dim exitCode

    RestoreAndPositionEdgeWindow = False
    tempFolder = shell.ExpandEnvironmentStrings("%TEMP%")
    tempPsPath = fso.BuildPath(tempFolder, fso.GetTempName & ".ps1")
    powerShellPath = shell.ExpandEnvironmentStrings( _
        "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")

    psScript = ""
    AddScriptLine psScript, "param("
    AddScriptLine psScript, "    [string]$WindowTitle,"
    AddScriptLine psScript, "    [int]$UseCursorMonitor,"
    AddScriptLine psScript, "    [int]$RequiredWidth,"
    AddScriptLine psScript, "    [int]$RequiredHeight"
    AddScriptLine psScript, ")"
    AddScriptLine psScript, "$ErrorActionPreference = 'Stop'"
    AddScriptLine psScript, "$process = Get-Process msedge -ErrorAction SilentlyContinue |"
    AddScriptLine psScript, "    Where-Object {"
    AddScriptLine psScript, "        $_.MainWindowTitle.StartsWith("
    AddScriptLine psScript, "            $WindowTitle,"
    AddScriptLine psScript, "            [System.StringComparison]::OrdinalIgnoreCase"
    AddScriptLine psScript, "        )"
    AddScriptLine psScript, "    } | Select-Object -First 1"
    AddScriptLine psScript, "if ($null -eq $process) { exit 1 }"
    AddScriptLine psScript, "$process.Refresh()"
    AddScriptLine psScript, "$windowHandle = $process.MainWindowHandle"
    AddScriptLine psScript, "if ($windowHandle -eq [System.IntPtr]::Zero) { exit 1 }"
    AddScriptLine psScript, "$memberDefinition = @'"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool SetProcessDpiAwarenessContext(System.IntPtr value);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool IsIconic(System.IntPtr hWnd);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool IsZoomed(System.IntPtr hWnd);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool ShowWindowAsync(System.IntPtr hWnd, int command);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool SetForegroundWindow(System.IntPtr hWnd);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool BringWindowToTop(System.IntPtr hWnd);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.StructLayout("
    AddScriptLine psScript, "    System.Runtime.InteropServices.LayoutKind.Sequential)]"
    AddScriptLine psScript, "public struct POINT { public int X; public int Y; }"
    AddScriptLine psScript, "[System.Runtime.InteropServices.StructLayout("
    AddScriptLine psScript, "    System.Runtime.InteropServices.LayoutKind.Sequential)]"
    AddScriptLine psScript, "public struct RECT {"
    AddScriptLine psScript, "    public int Left; public int Top; public int Right; public int Bottom;"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "[System.Runtime.InteropServices.StructLayout("
    AddScriptLine psScript, "    System.Runtime.InteropServices.LayoutKind.Sequential)]"
    AddScriptLine psScript, "public struct MONITORINFO {"
    AddScriptLine psScript, "    public int cbSize; public RECT rcMonitor; public RECT rcWork;"
    AddScriptLine psScript, "    public int dwFlags;"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "[System.Runtime.InteropServices.StructLayout("
    AddScriptLine psScript, "    System.Runtime.InteropServices.LayoutKind.Sequential)]"
    AddScriptLine psScript, "public struct WINDOWPLACEMENT {"
    AddScriptLine psScript, "    public int length; public int flags; public int showCmd;"
    AddScriptLine psScript, "    public POINT ptMinPosition; public POINT ptMaxPosition;"
    AddScriptLine psScript, "    public RECT rcNormalPosition;"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern System.IntPtr MonitorFromWindow("
    AddScriptLine psScript, "    System.IntPtr hWnd, uint flags);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern System.IntPtr MonitorFromPoint("
    AddScriptLine psScript, "    POINT point, uint flags);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool GetCursorPos(out POINT point);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"","
    AddScriptLine psScript, "    CharSet=System.Runtime.InteropServices.CharSet.Auto)]"
    AddScriptLine psScript, "public static extern bool GetMonitorInfo("
    AddScriptLine psScript, "    System.IntPtr monitor, ref MONITORINFO info);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern uint GetDpiForWindow(System.IntPtr hWnd);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool SetWindowPos("
    AddScriptLine psScript, "    System.IntPtr hWnd, System.IntPtr insertAfter,"
    AddScriptLine psScript, "    int x, int y, int width, int height, uint flags);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool GetWindowPlacement("
    AddScriptLine psScript, "    System.IntPtr hWnd, ref WINDOWPLACEMENT placement);"
    AddScriptLine psScript, "[System.Runtime.InteropServices.DllImport(""user32.dll"")]"
    AddScriptLine psScript, "public static extern bool SetWindowPlacement("
    AddScriptLine psScript, "    System.IntPtr hWnd, ref WINDOWPLACEMENT placement);"
    AddScriptLine psScript, "'@"
    AddScriptLine psScript, "Add-Type -Name NativeMethods -Namespace NcLauncher -MemberDefinition $memberDefinition"
    AddScriptLine psScript, "try {"
    AddScriptLine psScript, "    [void][NcLauncher.NativeMethods]::SetProcessDpiAwarenessContext("
    AddScriptLine psScript, "        [System.IntPtr](-4))"
    AddScriptLine psScript, "} catch { }"
    AddScriptLine psScript, "$isMinimized = [NcLauncher.NativeMethods]::IsIconic($windowHandle)"
    AddScriptLine psScript, "$isMaximized = [NcLauncher.NativeMethods]::IsZoomed($windowHandle)"
    AddScriptLine psScript, "$nearestMonitor = 2"
    AddScriptLine psScript, "if ($UseCursorMonitor -eq 1) {"
    AddScriptLine psScript, "    $cursor = New-Object 'NcLauncher.NativeMethods+POINT'"
    AddScriptLine psScript, "    if ([NcLauncher.NativeMethods]::GetCursorPos([ref]$cursor)) {"
    AddScriptLine psScript, "        $monitor = [NcLauncher.NativeMethods]::MonitorFromPoint("
    AddScriptLine psScript, "            $cursor, $nearestMonitor)"
    AddScriptLine psScript, "    } else {"
    AddScriptLine psScript, "        $monitor = [NcLauncher.NativeMethods]::MonitorFromWindow("
    AddScriptLine psScript, "            $windowHandle, $nearestMonitor)"
    AddScriptLine psScript, "    }"
    AddScriptLine psScript, "} else {"
    AddScriptLine psScript, "    $monitor = [NcLauncher.NativeMethods]::MonitorFromWindow("
    AddScriptLine psScript, "        $windowHandle, $nearestMonitor)"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "$monitorInfo = New-Object 'NcLauncher.NativeMethods+MONITORINFO'"
    AddScriptLine psScript, "$monitorInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($monitorInfo)"
    AddScriptLine psScript, "if (-not [NcLauncher.NativeMethods]::GetMonitorInfo("
    AddScriptLine psScript, "    $monitor, [ref]$monitorInfo)) { exit 2 }"
    AddScriptLine psScript, "$workWidth = $monitorInfo.rcWork.Right - $monitorInfo.rcWork.Left"
    AddScriptLine psScript, "$workHeight = $monitorInfo.rcWork.Bottom - $monitorInfo.rcWork.Top"
    AddScriptLine psScript, "$dpi = [NcLauncher.NativeMethods]::GetDpiForWindow($windowHandle)"
    AddScriptLine psScript, "if ($dpi -le 0) { $dpi = 96 }"
    AddScriptLine psScript, "$scaledWidth = [int][Math]::Round($RequiredWidth * $dpi / 96)"
    AddScriptLine psScript, "$scaledHeight = [int][Math]::Round($RequiredHeight * $dpi / 96)"
    AddScriptLine psScript, "$targetWidth = [Math]::Min("
    AddScriptLine psScript, "    $scaledWidth, [int][Math]::Floor($workWidth * 0.90))"
    AddScriptLine psScript, "$targetHeight = [Math]::Min("
    AddScriptLine psScript, "    $scaledHeight, [int][Math]::Floor($workHeight * 0.90))"
    AddScriptLine psScript, "$centerX = $monitorInfo.rcWork.Left + [int](($workWidth - $targetWidth) / 2)"
    AddScriptLine psScript, "$centerY = $monitorInfo.rcWork.Top + [int](($workHeight - $targetHeight) / 2)"
    AddScriptLine psScript, "if ($isMinimized) {"
    AddScriptLine psScript, "    $placement = New-Object 'NcLauncher.NativeMethods+WINDOWPLACEMENT'"
    AddScriptLine psScript, "    $placement.length = [System.Runtime.InteropServices.Marshal]::SizeOf($placement)"
    AddScriptLine psScript, "    if ([NcLauncher.NativeMethods]::GetWindowPlacement("
    AddScriptLine psScript, "        $windowHandle, [ref]$placement)) {"
    AddScriptLine psScript, "        $normalPosition = New-Object 'NcLauncher.NativeMethods+RECT'"
    AddScriptLine psScript, "        $normalPosition.Left = $centerX"
    AddScriptLine psScript, "        $normalPosition.Top = $centerY"
    AddScriptLine psScript, "        $normalPosition.Right = $centerX + $targetWidth"
    AddScriptLine psScript, "        $normalPosition.Bottom = $centerY + $targetHeight"
    AddScriptLine psScript, "        $placement.rcNormalPosition = $normalPosition"
    AddScriptLine psScript, "        $placement.showCmd = 2"
    AddScriptLine psScript, "        [void][NcLauncher.NativeMethods]::SetWindowPlacement("
    AddScriptLine psScript, "            $windowHandle, [ref]$placement)"
    AddScriptLine psScript, "        [void][NcLauncher.NativeMethods]::ShowWindowAsync($windowHandle, 9)"
    AddScriptLine psScript, "    } else {"
    AddScriptLine psScript, "        [void][NcLauncher.NativeMethods]::ShowWindowAsync($windowHandle, 9)"
    AddScriptLine psScript, "        Start-Sleep -Milliseconds 120"
    AddScriptLine psScript, "        [void][NcLauncher.NativeMethods]::SetWindowPos("
    AddScriptLine psScript, "            $windowHandle, [System.IntPtr]::Zero,"
    AddScriptLine psScript, "            $centerX, $centerY, $targetWidth, $targetHeight, 68)"
    AddScriptLine psScript, "    }"
    AddScriptLine psScript, "} else {"
    AddScriptLine psScript, "    if ($isMaximized) {"
    AddScriptLine psScript, "        [void][NcLauncher.NativeMethods]::ShowWindowAsync($windowHandle, 9)"
    AddScriptLine psScript, "        Start-Sleep -Milliseconds 120"
    AddScriptLine psScript, "    }"
    AddScriptLine psScript, "    [void][NcLauncher.NativeMethods]::SetWindowPos("
    AddScriptLine psScript, "        $windowHandle, [System.IntPtr]::Zero,"
    AddScriptLine psScript, "        $centerX, $centerY, $targetWidth, $targetHeight, 68)"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "[void][NcLauncher.NativeMethods]::BringWindowToTop($windowHandle)"
    AddScriptLine psScript, "[void][NcLauncher.NativeMethods]::SetForegroundWindow($windowHandle)"
    AddScriptLine psScript, "exit 0"

    On Error Resume Next
    Set psFile = fso.CreateTextFile(tempPsPath, True, False)

    If Err.Number = 0 Then
        psFile.Write psScript
        psFile.Close

        command = QuoteArgument(powerShellPath) & _
            " -NoProfile -NonInteractive -ExecutionPolicy Bypass" & _
            " -WindowStyle Hidden -File " & QuoteArgument(tempPsPath) & _
            " " & QuoteArgument(windowTitle) & _
            " " & CStr(Abs(CInt(useCursorMonitor))) & _
            " " & CStr(REQUIRED_WIDTH) & _
            " " & CStr(REQUIRED_HEIGHT)

        Err.Clear
        exitCode = shell.Run(command, 0, True)
        If Err.Number = 0 And exitCode = 0 Then
            RestoreAndPositionEdgeWindow = True
        End If
    End If

    Err.Clear
    If fso.FileExists(tempPsPath) Then
        fso.DeleteFile tempPsPath, True
    End If
    On Error GoTo 0
End Function

Function AcquireLaunchLock(ByVal folderPath)
    Dim lockFolder

    AcquireLaunchLock = False
    On Error Resume Next

    If fso.FolderExists(folderPath) Then
        Set lockFolder = fso.GetFolder(folderPath)
        If DateDiff("s", lockFolder.DateCreated, Now) > 20 Then
            fso.DeleteFolder folderPath, True
        End If
    End If

    Err.Clear
    fso.CreateFolder folderPath
    If Err.Number = 0 Then
        AcquireLaunchLock = True
    End If

    On Error GoTo 0
End Function

Sub ReleaseLaunchLock(ByVal folderPath)
    On Error Resume Next
    If fso.FolderExists(folderPath) Then
        fso.DeleteFolder folderPath, True
    End If
    On Error GoTo 0
End Sub

Sub ShowNasError(ByVal targetPath)
    Dim message

    message = _
        UnicodeText( _
            "4E 41 53 4E0A 306E 48 54 4D 4C 30D5 30A1 30A4 30EB " & _
            "3092 78BA 8A8D 3067 304D 306A 3044 305F 3081 3001 " & _
            "4E 43 2D 48 45 41 44 52 45 2D 47 45 4E 3092 8D77 " & _
            "52D5 3067 304D 307E 305B 3093 3002") & vbCrLf & vbCrLf & _
        UnicodeText( _
            "30CD 30C3 30C8 30EF 30FC 30AF 63A5 7D9A 3068 4E 41 " & _
            "53 3078 306E 30A2 30AF 30BB 30B9 3092 78BA 8A8D " & _
            "3057 3066 304B 3089 3001 3082 3046 4E00 5EA6 304A " & _
            "8A66 3057 304F 3060 3055 3044 3002") & vbCrLf & vbCrLf & _
        UnicodeText("78BA 8A8D 5148 FF1A") & targetPath

    MsgBox message, vbExclamation, APP_NAME
End Sub

Sub ShowEdgeNotFound()
    Dim message

    message = _
        UnicodeText( _
            "4D 69 63 72 6F 73 6F 66 74 20 45 64 67 65 304C " & _
            "898B 3064 304B 308A 307E 305B 3093 3067 3057 305F 3002") & _
        vbCrLf & vbCrLf & _
        UnicodeText( _
            "45 64 67 65 304C 5229 7528 3067 304D 308B 72B6 614B " & _
            "304B 78BA 8A8D 3057 3066 304F 3060 3055 3044 3002")

    MsgBox message, vbExclamation, APP_NAME
End Sub

Sub ShowWindowNotFound()
    Dim message

    message = _
        UnicodeText( _
            "4E 43 2D 48 45 41 44 52 45 2D 47 45 4E 306E 753B " & _
            "9762 3092 78BA 8A8D 3067 304D 307E 305B 3093 3067 " & _
            "3057 305F 3002") & vbCrLf & vbCrLf & _
        UnicodeText( _
            "5C11 3057 5F85 3063 3066 304B 3089 3001 3082 3046 " & _
            "4E00 5EA6 304A 8A66 3057 304F 3060 3055 3044 3002")

    MsgBox message, vbExclamation, APP_NAME
End Sub

appFolder = fso.GetParentFolderName(WScript.ScriptFullName)
preferredAppFolder = fso.BuildPath( _
    shell.SpecialFolders("MyDocuments"), UnicodeText("5C71 7530"))
preferredAppFolder = fso.BuildPath( _
    preferredAppFolder, APP_NAME)
desktopAppFolder = fso.BuildPath( _
    shell.SpecialFolders("Desktop"), APP_NAME)

targetAppFolder = preferredAppFolder
htmlPath = fso.GetAbsolutePathName( _
    fso.BuildPath(targetAppFolder, HTML_FILE_NAME))

If Not fso.FileExists(htmlPath) Then
    targetAppFolder = desktopAppFolder
    htmlPath = fso.GetAbsolutePathName( _
        fso.BuildPath(targetAppFolder, HTML_FILE_NAME))
End If

If Not fso.FileExists(htmlPath) Then
    targetAppFolder = appFolder
    htmlPath = fso.GetAbsolutePathName( _
        fso.BuildPath(targetAppFolder, HTML_FILE_NAME))
End If

WriteLauncherLog _
    "START version=" & LAUNCHER_VERSION & _
    " script=" & WScript.ScriptFullName & _
    " html=" & htmlPath

If Not fso.FileExists(htmlPath) Then
    WriteLauncherLog "ERROR html-not-found"
    ShowNasError htmlPath
    WScript.Quit 1
End If

edgePath = FindEdgePath()
If Len(edgePath) = 0 Then
    WriteLauncherLog "ERROR edge-not-found"
    ShowEdgeNotFound
    WScript.Quit 1
End If
WriteLauncherLog "EDGE path=" & edgePath

edgeUserDataFolder = fso.BuildPath( _
    shell.ExpandEnvironmentStrings("%LOCALAPPDATA%"), APP_NAME)
edgeUserDataFolder = fso.BuildPath(edgeUserDataFolder, "EdgeProfile")

If RestoreAndPositionEdgeWindow(appTitle, False) Then
    shell.AppActivate appTitle
    WScript.Quit 0
End If

lockPath = fso.BuildPath( _
    shell.ExpandEnvironmentStrings("%TEMP%"), _
    "NC-HEADRE-GEN-launch.lock")
hasLaunchLock = AcquireLaunchLock(lockPath)

If Not hasLaunchLock Then
    For waitCount = 1 To 40
        WScript.Sleep 250
        If Not fso.FolderExists(lockPath) Then
            Exit For
        End If
    Next

    If RestoreAndPositionEdgeWindow(appTitle, False) Then
        shell.AppActivate appTitle
        WScript.Quit 0
    End If

    hasLaunchLock = AcquireLaunchLock(lockPath)
    If Not hasLaunchLock Then
        WScript.Quit 0
    End If
End If

If RestoreAndPositionEdgeWindow(appTitle, False) Then
    ReleaseLaunchLock lockPath
    shell.AppActivate appTitle
    WScript.Quit 0
End If

If Left(htmlPath, 2) = "\\" Then
    fileUrl = "file:" & EncodeUrlPath(Replace(htmlPath, "\", "/"))
Else
    fileUrl = "file:///" & EncodeUrlPath(Replace(htmlPath, "\", "/"))
End If
WriteLauncherLog "FILE URL=" & fileUrl

On Error Resume Next
Err.Clear
launchCommand = _
    QuoteArgument(edgePath) & _
    " --start-minimized" & _
    " --user-data-dir=" & QuoteArgument(edgeUserDataFolder) & _
    " --no-first-run --no-default-browser-check" & _
    " --disable-background-mode" & _
    " --app=" & QuoteArgument(fileUrl)
WriteLauncherLog "LAUNCH command=" & launchCommand
launchResult = shell.Run( _
    launchCommand, _
    1, _
    False)
launchErrorNumber = Err.Number
launchErrorDescription = Err.Description

If launchErrorNumber <> 0 Then
    WriteLauncherLog _
        "ERROR launch number=" & CStr(launchErrorNumber) & _
        " description=" & launchErrorDescription
    On Error GoTo 0
    ReleaseLaunchLock lockPath
    ShowWindowNotFound
    WScript.Quit 1
End If
On Error GoTo 0

launchedWindowFound = False
For waitCount = 1 To 6
    WScript.Sleep 1500
    launchedWindowFound = RestoreAndPositionEdgeWindow(appTitle, True)
    If launchedWindowFound Then
        Exit For
    End If
Next

ReleaseLaunchLock lockPath

If launchedWindowFound Then
    WriteLauncherLog "SUCCESS window-found"
    shell.AppActivate appTitle
    WScript.Quit 0
End If

WriteLauncherLog "ERROR window-not-found"
ShowWindowNotFound
WScript.Quit 1
