param(
    [Parameter(Mandatory=$true)]
    [string]$InputJarDir,

    [Parameter(Mandatory=$true)]
    [string]$OutputClassDir
)

if (-not (Test-Path $InputJarDir)) {
    Write-Host "Input directory '$InputJarDir' does not exist"
    exit -1
}

$projects = Get-ChildItem -Path $InputJarDir -Directory

foreach ($project in $projects) {
    Write-Host "PROJ: $($project.Name)"

    $projectOutputDir = Join-Path $OutputClassDir $project.Name
    New-Item -ItemType Directory -Force -Path $projectOutputDir | Out-Null

    $jars = Get-ChildItem -Path $project.FullName -File

    foreach ($jar in $jars) {
        Expand-Archive -Path $jar.FullName -DestinationPath $projectOutputDir -Force
    }
}

$projects.Name
