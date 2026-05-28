# PRD — VSM Studio Version Launcher

**Status:** Draft — pending sign-off  
**Date:** 2026-05-28  
**Author:** Matt McKay

---

## Problem

Switching between VSM Studio versions requires manually killing the running process, navigating to `D:\VSM\vsmStudio\Versions`, finding the right zip, extracting it to `D:\VSM\vsmStudio\`, and relaunching `vsmStudio.exe`. This is slow and error-prone — especially when testing multiple builds or rolling back during an incident. There is no tooling to streamline it.

---

## Success Criteria

- Launching the script presents an interactive, arrow-navigable list of all available versions drawn from `D:\VSM\vsmStudio\Versions\`
- The list reflects the actual folder structure: subfolder groups (B18XX, B20XX, etc.) with zips listed under each, plus root-level zips
- Selecting a version with Enter:
  1. Kills `vsmStudio.exe` if it is currently running
  2. Extracts the selected zip to `D:\VSM\vsmStudio\`, overwriting existing files
  3. Launches `vsmStudio.exe` from `D:\VSM\vsmStudio\`
- The script handles the case where VSM is not running (no error, skip kill step)
- Extraction errors surface with a clear message rather than silently failing
- The script is a single `.ps1` file with no external dependencies beyond what ships with Windows

---

## Scope

**In:**
- Arrow-key navigation (Up/Down) with Enter to select
- Grouped display: subfolders as section headers, zips listed beneath; root-level zips in a separate "Latest" or "Ungrouped" section
- Kill running `vsmStudio.exe` process before extraction
- Zip extraction to `D:\VSM\vsmStudio\` with overwrite
- Launch `vsmStudio.exe` after extraction
- Escape key to exit without doing anything

**Out:**
- No GUI (no WinForms, no WPF, no external TUI libraries)
- No installer or scheduled task
- No version comparison or "current version" detection
- No network/download functionality
- No rollback or backup of the existing install before overwrite

---

## Constraints

- PowerShell only — must run on any Windows machine with PowerShell 5.1+ (no PS7-only features unless confirmed available)
- Single `.ps1` file
- No elevation prompt engineering — if admin rights are needed for extraction, that's a known limitation to note, not to solve
- Target paths are hardcoded for now: `D:\VSM\vsmStudio\Versions` (source) and `D:\VSM\vsmStudio\` (target)
- Must not require `Set-ExecutionPolicy` changes beyond what the user already has configured

---

## Versions Folder Structure (Observed)

```
D:\VSM\vsmStudio\Versions\
  B18XX\          ← subfolder group
    vsmStudio-B18XX-*.zip
  B20XX\
    vsmStudio-B20XX-*.zip
  B21XX\
  B22XX\
  B23XX\
    vsmStudio-B2309-Patch-Release.zip
    vsmStudio-B2345-Hotfix.zip
    vsmStudio-B2345-Hotfix-2qAq0RX8.zip   ← duplicate with hash suffix
    ...
  [DevelopmentBuilds]\
    ...
  vsmStudio-B2404-Release.zip             ← root-level (no subfolder)
  vsmStudio-B2486-Hotfix.zip
  ...
```

Some zips appear as pairs: a "clean" name (`vsmStudio-B2345-Hotfix.zip`) and a hash-suffixed variant (`vsmStudio-B2345-Hotfix-2qAq0RX8.zip`). Handling of these is an open question (see below).

---

## Plan

1. **Scaffold the script** — stub out the main flow: enumerate versions, render menu, handle input loop, execute selection
2. **Build the version enumerator** — crawl `Versions\`, group zips by parent folder, sort subfolders and zips by name, return a flat ordered list with group labels
3. **Build the interactive menu renderer** — console-based arrow-key navigation using `[Console]::ReadKey()`, highlight selected item, render group headers as non-selectable separators
4. **Implement the selection action**
   - Check for running `vsmStudio` process → kill with `Stop-Process -Force` if found → wait for exit
   - Extract selected zip to `D:\VSM\vsmStudio\` using `Expand-Archive -Force` (overwrites)
   - Launch `D:\VSM\vsmStudio\vsmStudio.exe` with `Start-Process`
5. **Add error handling** — extraction failure, missing exe post-extract, process kill failure
6. **Test against the actual Versions folder** — verify grouping renders correctly, verify kill+extract+launch sequence end-to-end
7. **Save to `D:\Claude\vsmStudioVersionLauncher\Launch-VSMStudio.ps1`**

---

## Decisions

1. **Duplicate / hash-suffixed zips** — Show all zips including hash-suffixed variants. No deduplication.

2. **`[DevelopmentBuilds]` folder** — Treat identically to other subfolders. Show in menu as a standard group.

3. **Post-launch behavior** — Launcher stays open after launching VSM Studio. User can re-select and re-launch without restarting the script.

4. **Execution policy** — Ship as a plain `.ps1` file. No `.bat` wrapper needed; machine is already configured to run scripts.

---

## Open Questions

None — all resolved. Ready to build.
