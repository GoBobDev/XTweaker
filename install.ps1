# ��������� ��������� ������� � UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$tempPath = [System.IO.Path]::GetTempPath()
$filename = Join-Path -Path $tempPath -ChildPath "XTweakerSetup.exe"
$url = "https://github.com/GoBobDev/XTweaker/releases/latest/download/XTweakerSetup.exe"

function Write-Log {
    param (
        [string]$message
    )
    Write-Host "[����] $message"
}

function Add-DefenderExclusion {
    param (
        [string]$path
    )
    Write-Log "��������� ���� $path � ������ ���������� Windows Defender..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Add-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
        Write-Log "���� $path ������� �������� � ������ ����������."
    } catch {
        Write-Host "[������] �� ������� �������� ���� � ������ ���������� Windows Defender: $_"
        exit 1
    }
}

function Remove-DefenderExclusion {
    param (
        [string]$path
    )
    Write-Log "������� ���� $path �� ������ ���������� Windows Defender..."
    try {
        Start-Process -FilePath "powershell" -ArgumentList "-Command `"Remove-MpPreference -ExclusionPath '$path'`"" -Verb RunAs -Wait
        Write-Log "���� $path ������� ������ �� ������ ����������."
    } catch {
        Write-Host "[������] �� ������� ������� ���� �� ������ ���������� Windows Defender: $_"
    }
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    return $principal.IsInRole($adminRole)
}

if (-not (Test-Admin)) {
    Write-Host "[������] ������ ������ ���� ������� � ������� ��������������."
    Write-Host "������� ����� ������� ��� ������."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    Add-DefenderExclusion -path $filename

    Write-Log "��������� ����..."
    Invoke-WebRequest -Uri $url -OutFile $filename -ErrorAction Stop

    if (Test-Path $filename) {
        Write-Log "���� ������� ������."
    } else {
        throw "������ ��� ���������� �����."
    }

    $command = "& {Start-Process -FilePath $filename -ArgumentList '/VERYSILENT' -Verb RunAs}"

    Write-Log "��������� ���� � ����������� /VERYSILENT �� ����� ��������������..."
    Invoke-Expression $command

    Write-Log "��������� ���������."

    Write-Log "������� ����..."
    Remove-Item $filename -ErrorAction Stop

    Remove-DefenderExclusion -path $filename

    Write-Log "������ ��������. ������� ����� ������� ��� ������."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} catch {
    Write-Host "[������] ��������� ������: $_"
    Write-Host "������� ����� ������� ��� ������."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
