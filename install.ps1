$tempPath = [System.IO.Path]::GetTempPath()
$filename = Join-Path -Path $tempPath -ChildPath "XTweakerSetup.exe"
$url = "https://github.com/GoBobDev/XTweaker/releases/latest/download/XTweakerSetup.exe"

function Write-Log {
    param (
        [string]$message
    )
    Write-Host "[INFO] $message"
}

function Add-DefenderExclusion {
    param (
        [string]$path
    )
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Add-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
    } catch {
        Write-Host "[ERROR] File ExclusionPath Add (MS Defender) failed: $_"
        exit 1
    }
}

function Remove-DefenderExclusion {
    param (
        [string]$path
    )
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Remove-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
    } catch {
        Write-Host "[ERROR] File ExclusionPath Removing (MS Defender) failed: $_"
    }
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $principal.IsInRole($adminRole)
}

if (-not (Test-Admin)) {
    Write-Host "[ERROR] You need to run PowerShell as Administrator!"
    Write-Host " -> Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    Add-DefenderExclusion -path $filename

    Write-Log "Downloading..."
    Invoke-WebRequest -Uri $url -OutFile $filename -ErrorAction Stop

    if (Test-Path $filename) {
        Write-Log "Files downloaded. They will be deleted after installation."
    } else {
        throw "[ERROR] File downloading error."
    }

    $command = "& {Start-Process -FilePath $filename -ArgumentList '/VERYSILENT' -Verb RunAs}"

    Write-Log "Completing installation..."
    Invoke-Expression $command

    Remove-Item $filename -ErrorAction Stop

    Remove-DefenderExclusion -path $filename

    Write-Log "Installation completed. Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} catch {
    Write-Host "[ERROR] Error code: $_"
    Write-Host " -> Press any key to exit."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
