$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestUrl = 'http://35.228.183.12:8080/manifest.json'
$manifestPath = Join-Path $root 'manifest.json'
$logPath = Join-Path $root 'launcher-update.log'

function Log([string]$message) {
    $line = "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] $message"
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

Set-Content -LiteralPath $logPath -Value '' -Encoding UTF8
Log 'Update check started.'
$remote = Invoke-RestMethod -Uri $manifestUrl -TimeoutSec 20
$local = if (Test-Path -LiteralPath $manifestPath) { Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json } else { $null }

if ($remote.updates) {
    foreach ($entry in $remote.updates) { Log ("SERVER: " + [string]$entry) }
}

if ($local -and $local.version -eq $remote.version) {
    Log ("Already up to date: " + $remote.version)
    exit 0
}

Log ("New package found: " + $remote.version)
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("Unforge-r239-update-" + [guid]::NewGuid().ToString('N') + '.zip')
$stage = Join-Path ([IO.Path]::GetTempPath()) ("Unforge-r239-update-" + [guid]::NewGuid().ToString('N'))
try {
    Invoke-WebRequest -Uri $remote.url -OutFile $tmp -UseBasicParsing -TimeoutSec 120
    Expand-Archive -LiteralPath $tmp -DestinationPath $stage -Force
    Get-ChildItem -LiteralPath $stage -Force | ForEach-Object {
        if ($_.Name -notin @('UnforgeLauncher.exe', 'forge-background.png')) {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $root $_.Name) -Recurse -Force
        }
    }
    Log 'Package installed. Launcher executable was kept locked-safe.'
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
