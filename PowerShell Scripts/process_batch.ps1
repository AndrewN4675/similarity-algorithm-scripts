param(
    [Parameter(Mandatory=$true)]
    [string]$InputDir,

    [Parameter(Mandatory=$true)]
    [string]$ResultsDir
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RunSA = Join-Path $ScriptDir "run_similarity_algorithm.ps1"

if (-not (Test-Path $InputDir)) {
    Write-Host "Input directory '$InputDir' does not exist"
    exit -2
}

New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

$projects = Get-ChildItem -Path $InputDir -Directory

Write-Host "Projects: [ $($projects.Name -join ' ') ]"

foreach ($project in $projects) {
    & $RunSA $project.Name $InputDir $ResultsDir
}
