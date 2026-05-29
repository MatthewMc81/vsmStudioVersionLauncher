# VSM Studio Version Launcher

An interactive PowerShell launcher for switching between VSM Studio versions. Instead of manually killing processes, extracting zips, and relaunching, run this script and pick the version you want.

---

## What it does

1. Reads all version zips from `D:\VSM\vsmStudio\Versions\`
2. Displays an interactive menu grouped by subfolder (B18XX, B20XX, etc.)
3. On selection:
   - Kills the running `vsmStudio.exe` process if one is found (requires admin)
   - Extracts the selected zip to `D:\VSM\vsmStudio\`, overwriting existing files
   - Launches `vsmStudio.exe` from `D:\VSM\vsmStudio\`
4. Stays open after launching — re-select and re-launch without restarting the script

---

## Requirements

- Windows with PowerShell 5.1 or later (built into Windows 10 and 11)
- No external dependencies — everything uses APIs that ship with Windows
- Administrator rights are optional — see [Admin rights](#admin-rights) below

---

## How to run

**Recommended:** Double-click `Launch-VSMStudio.exe`

The EXE handles execution policy internally and works with a plain double-click on any Windows machine.

**Alternatives:**
- Double-click `Launch-VSMStudio.bat` (handles execution policy, falls back if EXE is unavailable)
- Right-click `Launch-VSMStudio.ps1` → **Run with PowerShell** (requires execution policy to allow scripts)
- From a terminal: `.\Launch-VSMStudio.ps1`

---

## Admin rights

When the launcher starts without Administrator rights, it shows a prompt:

```
  [1]  Re-launch as Administrator  (UAC prompt)
  [2]  Continue without admin
  [3]  Exit
```

| Mode | Can extract & launch | Can kill running vsmStudio.exe |
|---|---|---|
| Administrator | Yes | Yes |
| No admin | Yes (if vsmStudio is not running) | No |

The current mode is shown in the menu header as **[Admin]** (green) or **[No Admin]** (yellow).

If you try to launch a version while vsmStudio is running without admin rights, the launcher will warn you and ask whether to continue before attempting extraction.

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

The launcher expects this layout under `D:\VSM\vsmStudio\Versions\`:

```
Versions\
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

- Subfolders are shown as group headers, sorted alphabetically
- Zips within each folder are sorted alphabetically
- Root-level zips (not in any subfolder) are grouped under **Ungrouped**
- All zips are shown, including hash-suffixed duplicates

---

## Hardcoded paths

| Variable | Value |
|---|---|
| Versions source | `D:\VSM\vsmStudio\Versions\` |
| Install target | `D:\VSM\vsmStudio\` |
| Executable | `vsmStudio.exe` |

To point the launcher at different paths, edit the three variables at the top of `Launch-VSMStudio.ps1` and rebuild the EXE.

---

## Error handling

| Situation | Behaviour |
|---|---|
| `vsmStudio.exe` is not running | Kill step is skipped silently |
| Running without admin and vsmStudio is open | Warning shown with Y/N prompt before attempting extraction |
| Process kill fails | Extraction is aborted; message shown |
| File locked during extraction | Identifies the locking application by name and PID; prompts user to close it |
| Extraction fails | Error shown; returns to menu |
| `vsmStudio.exe` missing after extraction | Error shown; returns to menu |
| Unhandled error at startup | Error, line, and stack trace shown; window stays open until a key is pressed |
| Versions folder not found | Exits with error message |
| No zips found | Exits with error message |

---

## Rebuilding the EXE

After editing `Launch-VSMStudio.ps1`, rebuild the EXE with:

```powershell
# One-time module install (if not already installed)
Install-Module -Name ps2exe -Scope CurrentUser

# Rebuild
Invoke-ps2exe -inputFile  .\Launch-VSMStudio.ps1 `
              -outputFile .\Launch-VSMStudio.exe `
              -title       'VSM Studio Version Launcher' `
              -description 'Interactive launcher for switching VSM Studio versions' `
              -company     'VSM' `
              -version     '2.3.0.0' `
              -noConsole:$false
```

---

## Files

| File | Purpose |
|---|---|
| `Launch-VSMStudio.exe` | **Primary launcher** — double-click to run |
| `Launch-VSMStudio.ps1` | Source script — edit this to make changes |
| `Launch-VSMStudio.bat` | Fallback launcher — runs the `.ps1` with execution policy bypass |
| `PRD.md` | Original product requirements document |
