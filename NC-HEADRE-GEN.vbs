Option Explicit

Const APP_NAME = "NC-HEADRE-GEN"
Const HTML_FILE_NAME = "index.html"
Const ICON_FILE_NAME = "appicon.png"
Const REQUIRED_WIDTH = 624
Const REQUIRED_HEIGHT = 980
Const LAUNCHER_VERSION = "2026.07.23.2"

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
Dim iconSourcePath
Dim lockPath
Dim hasLaunchLock
Dim waitCount
Dim launchResult
Dim launchCommand
Dim launchErrorNumber
Dim launchErrorDescription
Dim launchedWindowFound
Dim shortcutUpdated

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
    AddScriptLine psScript, "'@"
    AddScriptLine psScript, "Add-Type -Name NativeMethods -Namespace NcLauncher -MemberDefinition $memberDefinition"
    AddScriptLine psScript, "try {"
    AddScriptLine psScript, "    [void][NcLauncher.NativeMethods]::SetProcessDpiAwarenessContext("
    AddScriptLine psScript, "        [System.IntPtr](-4))"
    AddScriptLine psScript, "} catch { }"
    AddScriptLine psScript, "if ([NcLauncher.NativeMethods]::IsIconic($windowHandle) -or [NcLauncher.NativeMethods]::IsZoomed($windowHandle)) {"
    AddScriptLine psScript, "    [void][NcLauncher.NativeMethods]::ShowWindowAsync($windowHandle, 9)"
    AddScriptLine psScript, "    Start-Sleep -Milliseconds 120"
    AddScriptLine psScript, "}"
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
    AddScriptLine psScript, "if ($UseCursorMonitor -eq 1) {"
    AddScriptLine psScript, "    [void][NcLauncher.NativeMethods]::SetWindowPos("
    AddScriptLine psScript, "        $windowHandle, [System.IntPtr]::Zero,"
    AddScriptLine psScript, "        $monitorInfo.rcWork.Left + 8, $monitorInfo.rcWork.Top + 8,"
    AddScriptLine psScript, "        [Math]::Min(400, $workWidth), [Math]::Min(400, $workHeight), 68)"
    AddScriptLine psScript, "    Start-Sleep -Milliseconds 160"
    AddScriptLine psScript, "}"
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
    AddScriptLine psScript, "[void][NcLauncher.NativeMethods]::SetWindowPos("
    AddScriptLine psScript, "    $windowHandle, [System.IntPtr]::Zero,"
    AddScriptLine psScript, "    $centerX, $centerY, $targetWidth, $targetHeight, 68)"
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

Function CreateShortcutIcon(ByVal sourcePngPath, ByVal destinationIconPath)
    Dim tempFolder
    Dim tempPsPath
    Dim psFile
    Dim psScript
    Dim powerShellPath
    Dim command
    Dim exitCode

    CreateShortcutIcon = False
    If Not fso.FileExists(sourcePngPath) Then
        Exit Function
    End If

    tempFolder = shell.ExpandEnvironmentStrings("%TEMP%")
    tempPsPath = fso.BuildPath(tempFolder, fso.GetTempName & ".ps1")
    powerShellPath = shell.ExpandEnvironmentStrings( _
        "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")

    psScript = ""
    AddScriptLine psScript, "param([string]$SourcePng, [string]$DestinationIco)"
    AddScriptLine psScript, "$ErrorActionPreference = 'Stop'"
    AddScriptLine psScript, "Add-Type -AssemblyName System.Drawing"
    AddScriptLine psScript, "$source = $null"
    AddScriptLine psScript, "$canvas = $null"
    AddScriptLine psScript, "$graphics = $null"
    AddScriptLine psScript, "$icon = $null"
    AddScriptLine psScript, "$stream = $null"
    AddScriptLine psScript, "try {"
    AddScriptLine psScript, "    $source = [System.Drawing.Image]::FromFile($SourcePng)"
    AddScriptLine psScript, "    $canvas = New-Object System.Drawing.Bitmap 256, 256"
    AddScriptLine psScript, "    $graphics = [System.Drawing.Graphics]::FromImage($canvas)"
    AddScriptLine psScript, "    $graphics.Clear([System.Drawing.Color]::Transparent)"
    AddScriptLine psScript, "    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic"
    AddScriptLine psScript, "    $scale = [Math]::Min(256 / $source.Width, 256 / $source.Height)"
    AddScriptLine psScript, "    $width = [Math]::Max(1, [int][Math]::Round($source.Width * $scale))"
    AddScriptLine psScript, "    $height = [Math]::Max(1, [int][Math]::Round($source.Height * $scale))"
    AddScriptLine psScript, "    $x = [int][Math]::Floor((256 - $width) / 2)"
    AddScriptLine psScript, "    $y = [int][Math]::Floor((256 - $height) / 2)"
    AddScriptLine psScript, "    $graphics.DrawImage($source, $x, $y, $width, $height)"
    AddScriptLine psScript, "    $icon = [System.Drawing.Icon]::FromHandle($canvas.GetHicon())"
    AddScriptLine psScript, "    $stream = [System.IO.File]::Open("
    AddScriptLine psScript, "        $DestinationIco, [System.IO.FileMode]::Create)"
    AddScriptLine psScript, "    $icon.Save($stream)"
    AddScriptLine psScript, "} finally {"
    AddScriptLine psScript, "    if ($stream) { $stream.Dispose() }"
    AddScriptLine psScript, "    if ($icon) { $icon.Dispose() }"
    AddScriptLine psScript, "    if ($graphics) { $graphics.Dispose() }"
    AddScriptLine psScript, "    if ($canvas) { $canvas.Dispose() }"
    AddScriptLine psScript, "    if ($source) { $source.Dispose() }"
    AddScriptLine psScript, "}"
    AddScriptLine psScript, "if (Test-Path -LiteralPath $DestinationIco) { exit 0 }"
    AddScriptLine psScript, "exit 1"

    On Error Resume Next
    Set psFile = fso.CreateTextFile(tempPsPath, True, False)

    If Err.Number = 0 Then
        psFile.Write psScript
        psFile.Close

        command = QuoteArgument(powerShellPath) & _
            " -NoProfile -NonInteractive -ExecutionPolicy Bypass" & _
            " -WindowStyle Hidden -File " & QuoteArgument(tempPsPath) & _
            " " & QuoteArgument(sourcePngPath) & _
            " " & QuoteArgument(destinationIconPath)

        Err.Clear
        exitCode = shell.Run(command, 0, True)
        If Err.Number = 0 And exitCode = 0 And _
            fso.FileExists(destinationIconPath) Then
            CreateShortcutIcon = True
        End If
    End If

    Err.Clear
    If fso.FileExists(tempPsPath) Then
        fso.DeleteFile tempPsPath, True
    End If
    On Error GoTo 0
End Function

Function EnsureDesktopShortcut( _
    ByVal scriptPath, _
    ByVal workingFolder, _
    ByVal sourcePngPath, _
    ByVal edgeExecutable)

    Dim desktopFolder
    Dim shortcutPath
    Dim iconFolder
    Dim iconPath
    Dim launcher
    Dim wscriptPath

    EnsureDesktopShortcut = False
    On Error Resume Next

    desktopFolder = shell.SpecialFolders("Desktop")
    shortcutPath = fso.BuildPath(desktopFolder, APP_NAME & ".lnk")

    iconFolder = fso.BuildPath( _
        shell.ExpandEnvironmentStrings("%LOCALAPPDATA%"), APP_NAME)
    If Not fso.FolderExists(iconFolder) Then
        fso.CreateFolder iconFolder
    End If

    iconPath = fso.BuildPath(iconFolder, APP_NAME & ".ico")
    If Not fso.FileExists(iconPath) Then
        CreateShortcutIcon sourcePngPath, iconPath
    End If

    wscriptPath = fso.BuildPath( _
        shell.ExpandEnvironmentStrings("%SystemRoot%"), "System32\wscript.exe")

    Set launcher = shell.CreateShortcut(shortcutPath)
    launcher.TargetPath = wscriptPath
    launcher.Arguments = QuoteArgument(scriptPath)
    launcher.WorkingDirectory = workingFolder
    launcher.Description = UnicodeText( _
        "4E 43 2D 48 45 41 44 52 45 2D 47 45 4E 3092 5C02 7528 " & _
        "753B 9762 3067 958B 304D 307E 3059")

    If fso.FileExists(iconPath) Then
        launcher.IconLocation = iconPath & ",0"
    ElseIf fso.FileExists(edgeExecutable) Then
        launcher.IconLocation = edgeExecutable & ",0"
    End If

    Err.Clear
    launcher.Save
    If Err.Number = 0 Then
        EnsureDesktopShortcut = True
    End If
    On Error GoTo 0
End Function

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

iconSourcePath = fso.BuildPath(targetAppFolder, ICON_FILE_NAME)
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

shortcutUpdated = EnsureDesktopShortcut( _
    WScript.ScriptFullName, appFolder, iconSourcePath, edgePath)
WriteLauncherLog "SHORTCUT refreshed=" & CStr(shortcutUpdated)

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
    fileUrl = "file:" & Replace(htmlPath, "\", "/")
Else
    fileUrl = "file:///" & Replace(htmlPath, "\", "/")
End If

On Error Resume Next
Err.Clear
launchCommand = _
    QuoteArgument(edgePath) & _
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

WScript.Sleep 1500
launchedWindowFound = RestoreAndPositionEdgeWindow(appTitle, True)

If Not launchedWindowFound Then
    WScript.Sleep 2500
    launchedWindowFound = RestoreAndPositionEdgeWindow(appTitle, True)
End If

ReleaseLaunchLock lockPath

If launchedWindowFound Then
    WriteLauncherLog "SUCCESS window-found"
    shell.AppActivate appTitle
    WScript.Quit 0
End If

WriteLauncherLog "ERROR window-not-found"
ShowWindowNotFound
WScript.Quit 1
