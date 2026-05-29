# VSM Studio Version Launcher

**Current release: v2.0**

An interactive console launcher for switching between VSM Studio versions. Instead of manually killing processes, extracting zips, and relaunching, double-click the EXE and pick the version you want.

---

## How to run

**Double-click `Launch-VSMStudio.exe`** — that's it.

The EXE handles execution policy internally and works on any Windows machine with PowerShell 5.1+ (built into Windows 10 and 11).

| File | Purpose |
|---|---|
| `Launch-VSMStudio.exe` | **Primary launcher** — double-click to run |
| `Launch-VSMStudio.ps1` | Source script — edit this to make changes, then rebuild |
| `Launch-VSMStudio.bat` | Fallback — runs the `.ps1` directly if the EXE is unavailable |

---

## What it does

1. Reads all version zips from `D:\VSM\vsmStudio\Versions\`
2. Displays an interactive menu grouped by subfolder (B18XX, B20XX, etc.)
3. On selection:
   - Kills the running `vsmStudio.exe` process (requires admin)
   - Extracts the selected zip to `D:\VSM\vsmStudio\`, overwriting existing files
   - Launches `vsmStudio.exe` from `D:\VSM\vsmStudio\`
4. Stays open after launching — re-select and re-launch without restarting

---

## Admin rights

On startup, if the launcher is not running as Administrator it shows a prompt:

```
  [1]  Re-launch as Administrator  (UAC prompt)
  [2]  Continue without admin
  [3]  Exit
```

| Mode | Can extract & launch | Can kill running vsmStudio.exe |
|---|---|---|
| Administrator | Yes | Yes |
| No admin | Yes (if vsmStudio is not running) | No |

The current mode is shown in every screen as **[Admin]** (green) or **[No Admin]** (yellow) next to the version number.

If you try to launch a version while vsmStudio is running without admin rights, the launcher warns you and asks Y/N before attempting extraction.

---

## Controls

| Input | Action |
|---|---|
| `↑` / `↓` | Move selection up / down |
| `Enter` | Launch selected version |
| `Esc` | Quit |
| Left click | Highlight a version |
| Double-click | Launch a version |
| Scroll wheel | Move selection up / down |

---

## Versions folder structure

```
D:\VSM\vsmStudio\Versions\
  B18XX\
    vsmStudio-B18XX-*.zip
  B20XX\
    vsmStudio-B20XX-*.zip
  B23XX\
    vsmStudio-B2309-Patch-Release.zip
    vsmStudio-B2345-Hotfix.zip
    vsmStudio-B2345-Hotfix-2qAq0RX8.zip
  [DevelopmentBuilds]\
    ...
  vsmStudio-B2404-Release.zip     ← root-level zips appear under "Ungrouped"
  vsmStudio-B2486-Hotfix.zip
```

- Subfolders shown as group headers, sorted alphabetically
- Zips within each folder sorted alphabetically
- Root-level zips grouped under **Ungrouped**
- All zips shown including hash-suffixed duplicates

---

## Hardcoded paths

| Setting | Value |
|---|---|
| Versions source | `D:\VSM\vsmStudio\Versions\` |
| Install target | `D:\VSM\vsmStudio\` |
| Executable | `vsmStudio.exe` |

To change these, edit the variables at the top of `Launch-VSMStudio.ps1` and rebuild the EXE.

---

## Error handling

| Situation | Behaviour |
|---|---|
| vsmStudio is not running | Kill step skipped silently |
| Not admin and vsmStudio is open | Warning + Y/N prompt before extraction |
| Process kill fails | Extraction aborted, error shown |
| File locked during extraction | Locking app name and PID shown; user told what to close |
| Extraction fails | Error shown, returns to menu |
| `vsmStudio.exe` missing after extraction | Error shown, returns to menu |
| Unhandled startup error | Error, line, and stack trace shown; window stays open until keypress |
| Versions folder not found | Exits with error message |
| No zips found | Exits with error message |

---

## Rebuilding the EXE

After editing `Launch-VSMStudio.ps1`:

```powershell
# One-time module install
Install-Module -Name ps2exe -Scope CurrentUser

# Rebuild
Invoke-ps2exe -inputFile  .\Launch-VSMStudio.ps1 `
              -outputFile .\Launch-VSMStudio.exe `
              -title       'VSM Studio Version Launcher' `
              -description 'Interactive launcher for switching VSM Studio versions' `
              -company     'VSM' `
              -version     '2.0.0.0' `
              -noConsole:$false
```

---

## Changelog

### v2.0
- Optional admin prompt on startup — choose to elevate, continue without admin, or exit
- Admin / No Admin badge visible in the menu header and startup screen
- Version number shown in menu header and startup screen
- Mouse support: click to select, double-click to launch, scroll wheel to navigate
- Viewport scrolling for long version lists
- When a file is locked during extraction, identifies the locking process by name and PID
- Window stays open on any unhandled error, showing message, line, and stack trace
- Compiled to `Launch-VSMStudio.exe` — double-click to run, no execution policy setup needed
- Fixed: admin re-launch crash when running as compiled EXE

### v1.0
- Initial release
- Arrow-key navigation, grouped version list
- Kill / extract / launch flow
- Single `.ps1` file
