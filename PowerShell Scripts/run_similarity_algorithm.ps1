param(
    [Parameter(Mandatory=$true)]
    [string]$Project,

    [Parameter(Mandatory=$true)]
    [string]$InputDir,

    [Parameter(Mandatory=$true)]
    [string]$ResultsDir
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SA_CONFIG_FILE = Join-Path $ScriptDir "sa.config"

if (-not (Test-Path $SA_CONFIG_FILE)) {
    Write-Host "No java configuration file found at '$SA_CONFIG_FILE'!"
    exit -2
}

# Load config
Get-Content $SA_CONFIG_FILE | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]*)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim("'")
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

if (-not $JAVA_BINARY) {
    Write-Host "JAVA_BINARY not set. Incorrect '$SA_CONFIG_FILE'."
    exit -2
}

if (-not (Test-Path $JAVA_BINARY)) {
    Write-Host "'$JAVA_BINARY' not found."
    exit -2
}

if (-not $SA_JAR) {
    Write-Host "SA_JAR not set. Incorrect '$SA_CONFIG_FILE'."
    exit -2
}

# Resolve SA_JAR to absolute path
if (-not [System.IO.Path]::IsPathRooted($SA_JAR)) {
    $SA_JAR = Join-Path $ScriptDir $SA_JAR
}
$SA_JAR = (Resolve-Path $SA_JAR).Path

if (-not (Test-Path $SA_JAR)) {
    Write-Host "'$SA_JAR' not found."
    exit -2
}

$ProjectDir = (Resolve-Path (Join-Path $InputDir $Project)).Path
$ResultsDir = (Resolve-Path $ResultsDir).Path
$ResultsFile = Join-Path $ResultsDir "$Project.xml"

$TimeoutFile = Join-Path $ResultsDir "timeout"
$FailureFile = Join-Path $ResultsDir "failure"
$SuccessFile = Join-Path $ResultsDir "success"

if (-not (Test-Path $ProjectDir)) {
    Write-Host "No project directory at '$ProjectDir'"
    exit -3
}

Write-Host "Running similarity algorithm on project $Project"

# Build arguments
$arguments = "$JAVA_ARGS -jar `"$SA_JAR`" -target `"$ProjectDir`" -output `"$ResultsFile`""

$process = Start-Process -FilePath $JAVA_BINARY `
    -ArgumentList $arguments `
    -PassThru `
    -NoNewWindow

# Simple timeout handling (30m → 30 minutes)
if ($SA_TIMEOUT -match "^(\d+)m$") {
    $timeoutMs = [int]$matches[1] * 60 * 1000
} elseif ($SA_TIMEOUT -match "^(\d+)s$") {
    $timeoutMs = [int]$matches[1] * 1000
} else {
    $timeoutMs = 0
}

if ($timeoutMs -gt 0) {
    if (-not $process.WaitForExit($timeoutMs)) {
        $process.Kill()
        $RETURN_CODE = 124
    } else {
        $RETURN_CODE = $process.ExitCode
    }
} else {
    $process.WaitForExit()
    $RETURN_CODE = $process.ExitCode
}

Write-Host "RETURN CODE: $RETURN_CODE"

if ($RETURN_CODE -eq 124 -or $RETURN_CODE -eq 137) {
    Write-Host "Similarity algorithm on project $Project timed out"
    Add-Content -Path $TimeoutFile -Value $Project
}
elseif ($RETURN_CODE -ne 0) {
    Write-Host "Similarity algorithm on project $Project failed"
    Add-Content -Path $FailureFile -Value $Project
}
else {
    Add-Content -Path $SuccessFile -Value $Project
}
