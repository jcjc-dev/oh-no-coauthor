# oh-no-coauthor uninstaller (PowerShell)
# Removes hooks and restores previous configuration.

param(
    [switch]$Global,
    [switch]$Local,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$HookDirName = ".oh-no-coauthor"
$GlobalHookDir = Join-Path $HOME "$HookDirName/hooks"
$BackupSuffix = ".pre-oh-no-coauthor"
$ConfigFile = Join-Path $HOME "$HookDirName/config"

function Show-Usage {
    Write-Host "Usage: uninstall.ps1 [-Global] [-Local]"
    Write-Host ""
    Write-Host "  -Global   Remove global hooks (default)"
    Write-Host "  -Local    Remove hooks from the current repo only"
}

function Remove-Hook {
    param([string]$HookPath)

    $hookName = Split-Path $HookPath -Leaf

    if (Test-Path $HookPath) {
        $content = Get-Content $HookPath -Raw -ErrorAction SilentlyContinue
        if ($content -and $content -match "oh-no-coauthor") {
            Remove-Item $HookPath -Force
            Write-Host "  Removed $hookName"

            $backupPath = "$HookPath$BackupSuffix"
            if (Test-Path $backupPath) {
                Move-Item $backupPath $HookPath -Force
                Write-Host "  Restored previous $hookName from backup"
            }
        }
    }
}

function Uninstall-Global {
    Write-Host "Removing oh-no-coauthor global hooks..."
    Write-Host ""

    if (-not (Test-Path $GlobalHookDir)) {
        Write-Host "Nothing to remove -- oh-no-coauthor is not installed globally."
        exit 0
    }

    Remove-Hook -HookPath (Join-Path $GlobalHookDir "prepare-commit-msg")
    Remove-Hook -HookPath (Join-Path $GlobalHookDir "commit-msg")

    # Restore previous hooksPath
    if (Test-Path $ConfigFile) {
        $config = Get-Content $ConfigFile
        $prevPath = ($config | Where-Object { $_ -match "^previous_hooks_path=" }) -replace "^previous_hooks_path=", ""

        if ($prevPath) {
            Write-Host "  Restoring previous core.hooksPath: $prevPath"
            git config --global core.hooksPath $prevPath
        } else {
            git config --global --unset core.hooksPath 2>$null
        }
        Remove-Item $ConfigFile -Force
    } else {
        $currentHooksPath = git config --global core.hooksPath 2>$null
        if ($currentHooksPath -and $currentHooksPath -match "\.oh-no-coauthor") {
            git config --global --unset core.hooksPath 2>$null
            Write-Host "  Removed core.hooksPath config"
        }
    }

    # Clean up directory if empty
    $remaining = (Get-ChildItem $GlobalHookDir -File -ErrorAction SilentlyContinue).Count
    if ($remaining -eq 0) {
        $parentDir = Join-Path $HOME $HookDirName
        Remove-Item $parentDir -Recurse -Force
        Write-Host "  Cleaned up $parentDir"
    } else {
        Write-Host "  Note: $GlobalHookDir still has other hooks, leaving directory intact"
    }

    Write-Host ""
    Write-Host "Done. oh-no-coauthor has been removed."
}

function Uninstall-Local {
    Write-Host "Removing oh-no-coauthor hooks from this repo..."
    Write-Host ""

    if (-not (Test-Path ".git")) {
        Write-Error "Not in a git repository. Run this from the root of a git repo."
        exit 1
    }

    Remove-Hook -HookPath ".git/hooks/prepare-commit-msg"
    Remove-Hook -HookPath ".git/hooks/commit-msg"

    Write-Host ""
    Write-Host "Done. oh-no-coauthor hooks removed from this repo."
}

# --- Main ---

if ($Help) {
    Show-Usage
    exit 0
}

if ($Local) {
    Uninstall-Local
} else {
    Uninstall-Global
}
