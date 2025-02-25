# Установка кодировки консоли в UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$tempPath = [System.IO.Path]::GetTempPath()
$filename = Join-Path -Path $tempPath -ChildPath "XTweakerSetup.exe"
$url = "https://github.com/GoBobDev/XTweaker/releases/latest/download/XTweakerSetup.exe"

function Write-Log {
    param (
        [string]$message
    )
    Write-Host "[ИНФО] $message"
}

function Add-DefenderExclusion {
    param (
        [string]$path
    )
    Write-Log "Добавляем файл $path в список исключений Windows Defender..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Add-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
        Write-Log "Файл $path успешно добавлен в список исключений."
    } catch {
        Write-Host "[ОШИБКА] Не удалось добавить файл в список исключений Windows Defender: $_"
        exit 1
    }
}

function Remove-DefenderExclusion {
    param (
        [string]$path
    )
    Write-Log "Удаляем файл $path из списка исключений Windows Defender..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Remove-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
        Write-Log "Файл $path успешно удален из списка исключений."
    } catch {
        Write-Host "[ОШИБКА] Не удалось удалить файл из списка исключений Windows Defender: $_"
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
