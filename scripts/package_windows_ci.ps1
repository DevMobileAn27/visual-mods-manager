param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Repository
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)\+(\d+)$') {
    throw 'Expected MAJOR.MINOR.PATCH+BUILD'
}
$windowsVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
$archiveName = "visual-mods-manager-$Version-windows-x64"
$keyPath = Join-Path $env:RUNNER_TEMP 'vmm-dsa-private.pem'
$secretPublic = Join-Path $env:RUNNER_TEMP 'vmm-secret-public.der'
$repoPublic = Join-Path $env:RUNNER_TEMP 'vmm-repo-public.der'

function Invoke-Checked([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE)" }
}

try {
    if (-not $env:WINDOWS_DSA_PRIVATE_KEY_BASE64) { throw 'Missing Windows signing secret' }
    $env:PATH = "C:\Program Files\OpenSSL-Win64\bin;$env:PATH"
    Invoke-Checked 'python' @('scripts/windows_update_key.py', '--output', $keyPath)
    Invoke-Checked 'openssl' @('pkey', '-in', $keyPath, '-pubout', '-outform', 'DER', '-out', $secretPublic)
    Invoke-Checked 'openssl' @('pkey', '-pubin', '-in', 'dsa_pub.pem', '-outform', 'DER', '-out', $repoPublic)
    if ((Get-FileHash $secretPublic).Hash -ne (Get-FileHash $repoPublic).Hash) {
        throw 'Private key secret does not match dsa_pub.pem'
    }

    & .\scripts\prepare_7zip.ps1
    Invoke-Checked 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' @(
        "/DAppVersion=$Version", "/DWindowsVersion=$windowsVersion", 'windows\installer\XXMI-Manager.iss'
    )
    $installer = Join-Path $PWD 'dist\Visual-Mods-Manager-Setup.exe'
    $signed = (& dart run auto_updater:sign_update $installer $keyPath | Out-String)
    if ($LASTEXITCODE -ne 0 -or $signed -notmatch 'sparkle:dsaSignature="([^"]+)"') {
        throw 'Installer signing failed'
    }
    $signature = $Matches[1]
    Invoke-Checked 'python' @(
        'scripts/create_appcast.py', '--repository', $Repository,
        '--tag', "v$Version", '--version', $Version, '--signature', $signature,
        '--installer', $installer, '--output', 'dist/appcast.xml'
    )

    # Include all DLLs, assets and bundled 7zip, just as the installer does.
    Compress-Archive -Path 'build/windows/x64/runner/Release/*' -DestinationPath "dist/$archiveName.zip"
    $hash = (Get-FileHash "dist/$archiveName.zip" -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText((Join-Path $PWD "dist/$archiveName.sha256"), "$hash  $archiveName.zip`n")
} finally {
    foreach ($file in @($keyPath, $secretPublic, $repoPublic)) {
        if (Test-Path $file) { Remove-Item $file -Force }
    }
}
