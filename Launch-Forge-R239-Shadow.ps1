$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtime = Join-Path $root '.runtime'
$javaw = Join-Path $runtime 'jdk\bin\javaw.exe'
$proxyJar = Join-Path $root 'rsprox.jar'
$launcherClass = Join-Path $root 'ForgeHeadlessProxyLauncher.class'
$clientJar = Join-Path $root 'UnforgeR239-client.jar'
$outLog = Join-Path $root 'shadow-proxy.out.log'
$errLog = Join-Path $root 'shadow-proxy.err.log'

if (!(Test-Path -LiteralPath $javaw)) { $javaw = (Get-Command javaw.exe -ErrorAction SilentlyContinue).Source }
if (!$javaw) { throw 'Java 17 tai uudempi puuttuu.' }
if (!(Test-Path -LiteralPath $proxyJar)) { throw "rsprox.jar puuttuu: $proxyJar" }
if (!(Test-Path -LiteralPath $launcherClass)) { throw "Headless proxy launcher puuttuu: $launcherClass" }
if (!(Test-Path -LiteralPath $clientJar)) { throw "Unforge client puuttuu: $clientJar" }

$env:UNFORGE_LAUNCHER_ROOT = $root
$env:UNFORGE_CLIENT_JAR = $clientJar
$env:RSPS_JAVCONFIG_URL = 'http://35.228.183.12:8080/jav_local_239_rsprox.ws'
$env:RSPS_RSA = 'bc91664575a944cadaa833a678dffd134088f2545d664e6085405f2256f373588c5ec8d91bd9a66d8c6a8d5780eca9dd0713d4d3152ea7edb4d4936fbd11c22df51fb823b757f0b3f8baa1480fa8dd2685031e0d58b41d7a1bc18cfb8bb93b36d3450f41eae2cd38a5d54e275c4eadf203a790134dfd785802f7990a9868f605'
$env:JAVA_TOOL_OPTIONS = "-Duser.home=$root"

New-Item -ItemType Directory -Force -Path (Join-Path $root '.runelite') | Out-Null
 $settings = Join-Path $root '.runelite\settings.properties'
 $defaults = Join-Path $root 'unforge-default.settings.properties'
 if (!(Test-Path -LiteralPath $settings) -and (Test-Path -LiteralPath $defaults)) {
     Copy-Item -LiteralPath $defaults -Destination $settings -Force
 }
New-Item -ItemType Directory -Force -Path (Join-Path $env:USERPROFILE '.rsprox') | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'proxy-targets.yaml') -Destination (Join-Path $env:USERPROFILE '.rsprox\proxy-targets.yaml') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $root '.rsprox') | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'proxy-targets.yaml') -Destination (Join-Path $root '.rsprox\proxy-targets.yaml') -Force

$separator = [IO.Path]::PathSeparator
$classpath = "$proxyJar$separator$root"
Start-Process -FilePath $javaw -ArgumentList @('-cp', $classpath, 'ForgeHeadlessProxyLauncher') -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog | Out-Null
