# Launch-VSMStudio.ps1

try {  # outer catch — keeps window open on any startup or runtime error

$VersionsRoot  = 'D:\VSM\vsmStudio\Versions'
$InstallTarget = 'D:\VSM\vsmStudio'
$ExeName       = 'vsmStudio.exe'
$HEADER_ROWS   = 3

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ConsoleInput {
    const int  STD_INPUT = -10;
    const uint MOUSE_IN  = 0x0010;
    const uint QUICK_ED  = 0x0040;
    const uint EXTENDED  = 0x0080;

    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll")] static extern bool   GetConsoleMode(IntPtr h, out uint m);
    [DllImport("kernel32.dll")] static extern bool   SetConsoleMode(IntPtr h, uint m);
    [DllImport("kernel32.dll")] static extern bool   ReadConsoleInput(IntPtr h, [Out] InputRecord[] buf, uint len, out uint read);
    [DllImport("kernel32.dll")] static extern bool   FlushConsoleInputBuffer(IntPtr h);

    static IntPtr _h;
    static uint   _saved;

    public static void Init() {
        _h = GetStdHandle(STD_INPUT);
        GetConsoleMode(_h, out _saved);
        SetConsoleMode(_h, (_saved & ~QUICK_ED) | MOUSE_IN | EXTENDED);
        FlushConsoleInputBuffer(_h);
    }

    public static void Restore() { if (_h != IntPtr.Zero) SetConsoleMode(_h, _saved); }

    public static InputRecord Read() {
        var buf = new InputRecord[1]; uint n;
        do { ReadConsoleInput(_h, buf, 1, out n); } while (n == 0);
        return buf[0];
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct InputRecord {
        [FieldOffset(0)] public ushort Type;
        [FieldOffset(4)] public KeyEvent   Key;
        [FieldOffset(4)] public MouseEvent Mouse;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct KeyEvent {
        public int    Down;
        public ushort Repeat; public ushort VK;
        public ushort Scan;   public ushort Char;
        public uint   Ctrl;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MouseEvent {
        public short X; public short Y;
        public uint Button; public uint Ctrl; public uint Flags;
    }

    public const ushort T_KEY     = 0x0001;
    public const ushort T_MOUSE   = 0x0002;
    public const ushort VK_UP     = 0x0026;
    public const ushort VK_DOWN   = 0x0028;
    public const ushort VK_RETURN = 0x000D;
    public const ushort VK_ESCAPE = 0x001B;
    public const uint   BTN_LEFT  = 0x0001;
    public const uint   EF_DOUBLE = 0x0002;
    public const uint   EF_WHEEL  = 0x0004;
}

public static class RestartManager {
    [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
    static extern int RmStartSession(out uint pSessionHandle, int dwSessionFlags, string strSessionKey);
    [DllImport("rstrtmgr.dll")]
    static extern int RmEndSession(uint pSessionHandle);
    [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
    static extern int RmRegisterResources(uint pSessionHandle, uint nFiles, string[] rgsFilenames,
        uint nApplications, RM_UNIQUE_PROCESS[] rgApplications, uint nServices, string[] rgsServiceNames);
    [DllImport("rstrtmgr.dll")]
    static extern int RmGetList(uint dwSessionHandle, out uint pnProcInfoNeeded, ref uint pnProcInfo,
        RM_PROCESS_INFO[] rgAffectedApps, ref uint lpdwRebootReasons);

    [StructLayout(LayoutKind.Sequential)]
    struct RM_UNIQUE_PROCESS { public int dwProcessId; public long ProcessStartTime; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct RM_PROCESS_INFO {
        public RM_UNIQUE_PROCESS Process;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string strAppName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]  public string strServiceShortName;
        public int ApplicationType; public uint AppStatus; public int TSSessionId;
        [MarshalAs(UnmanagedType.Bool)] public bool bRestartable;
    }

    public static string[] WhoHasLocked(string path) {
        uint handle;
        if (RmStartSession(out handle, 0, Guid.NewGuid().ToString()) != 0) return new string[0];
        try {
            RmRegisterResources(handle, 1, new[] { path }, 0, null, 0, null);
            uint needed = 0, count = 0, reasons = 0;
            RmGetList(handle, out needed, ref count, null, ref reasons);
            if (needed == 0) return new string[0];
            var info = new RM_PROCESS_INFO[needed]; count = needed;
            RmGetList(handle, out needed, ref count, info, ref reasons);
            var names = new string[count];
            for (uint i = 0; i < count; i++)
                names[i] = info[i].strAppName + " (PID " + info[i].Process.dwProcessId + ")";
            return names;
        } finally { RmEndSession(handle); }
    }
}
'@

# ---- startup prompt ----

function Show-StartupPrompt {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($admin) { return $true }

    [Console]::Clear()
    Write-Host ''
    Write-Host '  VSM Studio Version Launcher' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  This session is not running as Administrator.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Without admin rights you can still browse, extract, and launch' -ForegroundColor White
    Write-Host '  versions — but you will not be able to kill a running vsmStudio.exe.' -ForegroundColor White
    Write-Host '  If vsmStudio is open when you launch a version, extraction may fail' -ForegroundColor White
    Write-Host '  because the exe file will be locked.' -ForegroundColor White
    Write-Host ''
    Write-Host '  -------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  [1]  Re-launch as Administrator  (UAC prompt)' -ForegroundColor Green
    Write-Host '  [2]  Continue without admin' -ForegroundColor White
    Write-Host '  [3]  Exit' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Press 1, 2, or 3 ...' -ForegroundColor DarkGray

    while ($true) {
        $k = [Console]::ReadKey($true)
        switch ($k.KeyChar) {
            '1' {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
                exit 0
            }
            '2' { return $false }
            '3' { exit 0 }
        }
    }
}

# ---- version enumeration ----

function Get-VersionEntries {
    $list = [System.Collections.Generic.List[PSCustomObject]]::new()

    Get-ChildItem -Path $VersionsRoot -Directory -ErrorAction SilentlyContinue |
      Sort-Object Name | ForEach-Object {
        $zips = Get-ChildItem -Path $_.FullName -Filter '*.zip' -File | Sort-Object Name
        if ($zips.Count) {
            $list.Add([PSCustomObject]@{ Type='header'; Label=$_.Name; Path=$null })
            $zips | ForEach-Object { $list.Add([PSCustomObject]@{ Type='item'; Label=$_.Name; Path=$_.FullName }) }
        }
    }

    $root = Get-ChildItem -Path $VersionsRoot -Filter '*.zip' -File | Sort-Object Name
    if ($root.Count) {
        $list.Add([PSCustomObject]@{ Type='header'; Label='Ungrouped'; Path=$null })
        $root | ForEach-Object { $list.Add([PSCustomObject]@{ Type='item'; Label=$_.Name; Path=$_.FullName }) }
    }

    return ,$list
}

function Get-SelectableIndices ($entries) {
    $idx = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt $entries.Count; $i++) {
        if ($entries[$i].Type -eq 'item') { $idx.Add($i) }
    }
    return ,$idx
}

# ---- rendering ----

function Build-RenderLines ($entries, $selectedIndex) {
    $lines = [System.Collections.Generic.List[hashtable]]::new()
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = $entries[$i]
        if ($e.Type -eq 'header') {
            if ($lines.Count) { $lines.Add(@{ text=''; kind='blank'; ei=-1 }) }
            $lines.Add(@{ text="  [ $($e.Label) ]"; kind='header'; ei=$i })
        } else {
            $sel = ($i -eq $selectedIndex)
            $lines.Add(@{
                text = "  $(if ($sel){'>'} else {' '}) $($e.Label)"
                kind = if ($sel) { 'selected' } else { 'item' }
                ei   = $i
            })
        }
    }
    return ,$lines
}

function Render-Frame ($lines, $selectedIndex, [ref]$vtRef) {
    $wTop  = [Console]::WindowTop
    $wH    = [Console]::WindowHeight
    $wW    = [Console]::WindowWidth
    $avail = $wH - $HEADER_ROWS - 1
    $p     = $wW - 1

    # Find selected render-line
    $selLine = -1
    for ($j = 0; $j -lt $lines.Count; $j++) {
        if ($lines[$j].ei -eq $selectedIndex) { $selLine = $j; break }
    }

    # Clamp viewport
    $vt = $vtRef.Value
    if ($selLine -ge 0) {
        if ($selLine -lt $vt)          { $vt = $selLine }
        if ($selLine -ge $vt + $avail) { $vt = $selLine - $avail + 1 }
    }
    if ($vt -lt 0) { $vt = 0 }
    $vtRef.Value = $vt

    [Console]::CursorVisible = $false
    [Console]::SetCursorPosition(0, $wTop)

    # Title — shows admin status on the right
    $adminBadge  = if ($IsAdmin) { '  [Admin]' } else { '  [No Admin]' }
    $titleLeft   = '  VSM Studio Version Launcher'
    $titleLine   = ($titleLeft + $adminBadge).PadRight($p)
    Write-Host $titleLeft -ForegroundColor Cyan -NoNewline
    Write-Host $adminBadge.PadRight($p - $titleLeft.Length) -ForegroundColor $(if ($IsAdmin) { 'Green' } else { 'Yellow' })

    # Hint line
    $hint = '  UP/DOWN navigate   ENTER launch   ESC quit   click=select   dbl-click=launch'
    if (-not $IsAdmin) { $hint = '  [!] No admin: cannot kill running process   ' + $hint.TrimStart() }
    if ($vt -gt 0)                       { $hint = '[^] ' + $hint }
    if (($vt + $avail) -lt $lines.Count) { $hint = $hint + ' [v]' }
    Write-Host $hint.PadRight($p) -ForegroundColor DarkGray

    # Blank separator
    Write-Host ''.PadRight($p)

    # Viewport slice
    $end   = [Math]::Min($vt + $avail - 1, $lines.Count - 1)
    $slice = if ($vt -le $end) { @($lines[$vt..$end]) } else { @() }

    foreach ($line in $slice) {
        $t = if ($line.text.Length -ge $p) { $line.text.Substring(0, $p) } else { $line.text.PadRight($p) }
        switch ($line.kind) {
            'header'   { Write-Host $t -ForegroundColor DarkYellow }
            'selected' { Write-Host $t -ForegroundColor White -BackgroundColor DarkBlue }
            default    { Write-Host $t }
        }
    }

    # Erase leftover lines from previous render
    $empty = ''.PadRight($p)
    for ($k = $slice.Count; $k -lt $avail; $k++) { Write-Host $empty }
}

function Get-HitEntryIndex ($mouseY, $lines, $vt) {
    $row = $mouseY - [Console]::WindowTop - $HEADER_ROWS
    if ($row -lt 0) { return -1 }
    $ai = $vt + $row
    if ($ai -ge $lines.Count) { return -1 }
    $l = $lines[$ai]
    if ($l.kind -eq 'item' -or $l.kind -eq 'selected') { return $l.ei }
    return -1
}

# ---- launch ----

function Invoke-Launch ($zipPath) {
    [Console]::Clear()
    [Console]::CursorVisible = $true
    Write-Host ''

    $proc = Get-Process -Name 'vsmStudio' -ErrorAction SilentlyContinue
    if ($proc) {
        if ($IsAdmin) {
            # Admin: kill the process
            Write-Host '  Stopping vsmStudio.exe...' -ForegroundColor Yellow
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                $proc.WaitForExit(5000) | Out-Null
                Write-Host '  Stopped.' -ForegroundColor Green
            } catch {
                Write-Host "  ERROR: Cannot stop vsmStudio.exe: $_" -ForegroundColor Red
                Write-Host ''
                Write-Host '  Extraction skipped. Press any key to return...'
                [ConsoleInput]::Restore()
                [Console]::ReadKey($true) | Out-Null
                [ConsoleInput]::Init()
                [Console]::CursorVisible = $false
                return
            }
        } else {
            # No admin: warn and let the user decide
            Write-Host '  vsmStudio.exe is currently running.' -ForegroundColor Yellow
            Write-Host '  Without admin rights it cannot be killed.' -ForegroundColor Yellow
            Write-Host '  Extraction may fail if the exe file is locked.' -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  Continue anyway?  [Y] Yes   [N] Cancel' -ForegroundColor White
            while ($true) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq 'Y') { Write-Host '  Continuing...'; break }
                if ($k.Key -eq 'N' -or $k.Key -eq 'Escape') {
                    Write-Host '  Cancelled.' -ForegroundColor DarkGray
                    Write-Host ''
                    Write-Host '  Press any key to return...'
                    [Console]::ReadKey($true) | Out-Null
                    [Console]::CursorVisible = $false
                    return
                }
            }
        }
    }

    $zipName = Split-Path $zipPath -Leaf
    Write-Host "  Extracting $zipName ..." -ForegroundColor Yellow
    try {
        Expand-Archive -Path $zipPath -DestinationPath $InstallTarget -Force -ErrorAction Stop
        Write-Host '  Done.' -ForegroundColor Green
    } catch {
        $errMsg = "$_"
        Write-Host "  ERROR: Extraction failed: $errMsg" -ForegroundColor Red

        # Identify which process has the file locked
        if ($errMsg -match "'(.+?)' because it is being used by another process") {
            $lockedFile = $Matches[1]
            Write-Host "  Locked file: $(Split-Path $lockedFile -Leaf)" -ForegroundColor Red
            try {
                $lockers = [RestartManager]::WhoHasLocked($lockedFile)
                if ($lockers.Count -gt 0) {
                    Write-Host "  Locked by:   $($lockers -join ', ')" -ForegroundColor Yellow
                    Write-Host '  Close the above application(s) and try again.' -ForegroundColor Yellow
                } else {
                    Write-Host '  Could not identify the locking process — close any open documents and try again.' -ForegroundColor Yellow
                }
            } catch {
                Write-Host '  Could not identify the locking process — close any open documents and try again.' -ForegroundColor Yellow
            }
        } elseif (-not $IsAdmin) {
            Write-Host '  Tip: re-launch as Administrator so vsmStudio.exe can be killed first.' -ForegroundColor DarkGray
        }

        Write-Host ''
        Write-Host '  Press any key to return...'
        [ConsoleInput]::Restore()
        [Console]::ReadKey($true) | Out-Null
        [ConsoleInput]::Init()
        [Console]::CursorVisible = $false
        return
    }

    $exe = Join-Path $InstallTarget $ExeName
    if (-not (Test-Path $exe)) {
        Write-Host "  ERROR: $ExeName not found at $exe after extraction." -ForegroundColor Red
        Write-Host ''
        Write-Host '  Press any key to return...'
        [ConsoleInput]::Restore()
        [Console]::ReadKey($true) | Out-Null
        [ConsoleInput]::Init()
        [Console]::CursorVisible = $false
        return
    }

    Write-Host "  Launching $ExeName ..." -ForegroundColor Green
    Start-Process -FilePath $exe
    Start-Sleep -Milliseconds 800
    [Console]::CursorVisible = $false
    [ConsoleInput]::Init()
}

# ---- main ----

if (-not (Test-Path $VersionsRoot)) {
    Write-Host "ERROR: Versions folder not found: $VersionsRoot" -ForegroundColor Red
    exit 1
}

# Show startup prompt — sets $IsAdmin for the rest of the session
$IsAdmin = Show-StartupPrompt

$origBufH = [Console]::BufferHeight
$origBufW = [Console]::BufferWidth
try { [Console]::BufferHeight = [Console]::WindowHeight } catch { }
try { [Console]::BufferWidth  = [Console]::WindowWidth  } catch { }

[Console]::CursorVisible = $false
[ConsoleInput]::Init()

try {
    $entries     = Get-VersionEntries
    $selectables = Get-SelectableIndices $entries

    if ($selectables.Count -eq 0) {
        [Console]::CursorVisible = $true
        Write-Host "No .zip files found under $VersionsRoot" -ForegroundColor Red
        exit 1
    }

    $selPos  = 0
    $viewTop = 0

    while ($true) {
        $selIdx = $selectables[$selPos]
        $lines  = Build-RenderLines $entries $selIdx
        $vtRef  = [ref]$viewTop
        Render-Frame $lines $selIdx $vtRef
        $viewTop = $vtRef.Value

        $evt = [ConsoleInput]::Read()

        if ($evt.Type -eq [ConsoleInput]::T_KEY) {
            if (-not $evt.Key.Down) { continue }
            $vk = $evt.Key.VK
            if ($vk -eq [ConsoleInput]::VK_UP) {
                if ($selPos -gt 0) { $selPos-- }
            } elseif ($vk -eq [ConsoleInput]::VK_DOWN) {
                if ($selPos -lt ($selectables.Count - 1)) { $selPos++ }
            } elseif ($vk -eq [ConsoleInput]::VK_RETURN) {
                Invoke-Launch $entries[$selIdx].Path
                $entries     = Get-VersionEntries
                $selectables = Get-SelectableIndices $entries
                if ($selPos -ge $selectables.Count) { $selPos = [Math]::Max(0, $selectables.Count - 1) }
            } elseif ($vk -eq [ConsoleInput]::VK_ESCAPE) {
                exit 0
            }

        } elseif ($evt.Type -eq [ConsoleInput]::T_MOUSE) {
            $m = $evt.Mouse

            if ($m.Flags -eq [ConsoleInput]::EF_WHEEL) {
                $hw    = ($m.Button -shr 16) -band 0xFFFF
                $delta = if ($hw -gt 32767) { [int]$hw - 65536 } else { [int]$hw }
                if ($delta -gt 0) { if ($selPos -gt 0) { $selPos-- } }
                else              { if ($selPos -lt ($selectables.Count - 1)) { $selPos++ } }

            } elseif ($m.Button -band [ConsoleInput]::BTN_LEFT) {
                $hitEI = Get-HitEntryIndex $m.Y $lines $viewTop
                if ($hitEI -ge 0) {
                    for ($s = 0; $s -lt $selectables.Count; $s++) {
                        if ($selectables[$s] -eq $hitEI) { $selPos = $s; break }
                    }
                    if ($m.Flags -eq [ConsoleInput]::EF_DOUBLE) {
                        Invoke-Launch $entries[$selectables[$selPos]].Path
                        $entries     = Get-VersionEntries
                        $selectables = Get-SelectableIndices $entries
                        if ($selPos -ge $selectables.Count) { $selPos = [Math]::Max(0, $selectables.Count - 1) }
                    }
                }
            }
        }
    }
} finally {
    try { [ConsoleInput]::Restore() } catch { }
    [Console]::Clear()
    [Console]::CursorVisible = $true
    try { [Console]::BufferHeight = $origBufH } catch { }
    try { [Console]::BufferWidth  = $origBufW  } catch { }
}

} catch {  # outer catch
    try { [ConsoleInput]::Restore() } catch { }
    try { [Console]::CursorVisible = $true } catch { }
    Write-Host ''
    Write-Host '  *** UNHANDLED ERROR ***' -ForegroundColor Red
    Write-Host ''
    Write-Host "  $_" -ForegroundColor Red
    Write-Host ''
    Write-Host '  Script line:' -ForegroundColor DarkGray
    Write-Host "  $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Stack trace:' -ForegroundColor DarkGray
    Write-Host "  $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Press any key to close...' -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}
