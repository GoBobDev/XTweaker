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
    Write-Host "[ОШИБКА] Скрипт должен быть запущен с правами администратора."
    Write-Host "Нажмите любую клавишу для выхода."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    Add-DefenderExclusion -path $filename

    Write-Log "Скачиваем файл..."
    Invoke-WebRequest -Uri $url -OutFile $filename -ErrorAction Stop

    if (Test-Path $filename) {
        Write-Log "Файл успешно скачан."
    } else {
        throw "Ошибка при скачивании файла."
    }

    $command = "& {Start-Process -FilePath $filename -ArgumentList '/VERYSILENT' -Verb RunAs}"

    Write-Log "Запускаем файл с параметрами /VERYSILENT от имени администратора..."
    Invoke-Expression $command

    Write-Log "Установка завершена."

    Write-Log "Удаляем файл..."
    Remove-Item $filename -ErrorAction Stop

    Remove-DefenderExclusion -path $filename

    Write-Log "Скрипт завершен. Нажмите любую клавишу для выхода."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} catch {
    Write-Host "[ОШИБКА] Произошла ошибка: $_"
    Write-Host "Нажмите любую клавишу для выхода."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
