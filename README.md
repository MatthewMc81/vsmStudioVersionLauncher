# VSM Studio Version Launcher

An interactive PowerShell launcher for switching between VSM Studio versions. Instead of manually killing processes, extracting zips, and relaunching, run this script and pick the version you want.

---

## What it does

1. Reads all version zips from `D:\VSM\vsmStudio\Versions\`
2. Displays an interactive menu grouped by subfolder (B18XX, B20XX, etc.)
3. On selection:
   - Kills the running `vsmStudio.exe` process if one is found
   - Extracts the selected zip to `D:\VSM\vsmStudio\`, overwriting existing files
   - Launches `vsmStudio.exe` from `D:\VSM\vsmStudio\`
4. Stays open after launching — re-select and re-launch without restarting the script

---

## Requirements

- Windows with PowerShell 5.1 or later
- No external dependencies — everything uses APIs that ship with Windows
- Administrator rights (the script auto-elevates via UAC prompt if needed)

---

## How to run

Right-click `Launch-VSMStudio.ps1` → **Run with PowerShell**

Or from a terminal:
```powershell
.\Launch-VSMStudio.ps1
```

If not already running as Administrator, a UAC prompt will appear and the script will relaunch itself elevated automatically.

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

The script expects this layout under `D:\VSM\vsmStudio\Versions\`:

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

To point the script at different paths, edit the three variables at the top of `Launch-VSMStudio.ps1`.

---

## Error handling

| Situation | Behaviour |
|---|---|
| `vsmStudio.exe` is not running | Kill step is skipped silently |
| Process kill fails (access denied) | Extraction is aborted; message shown with instructions to run as Administrator |
| Extraction fails | Error shown; returns to menu |
| `vsmStudio.exe` missing after extraction | Error shown; returns to menu |
| Versions folder not found | Script exits with error message |
| No zips found | Script exits with error message |
