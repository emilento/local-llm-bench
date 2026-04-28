<#
.SYNOPSIS
    Generic llama.cpp runner with task profiles and backend/version selection.

.DESCRIPTION
    Selects the latest installed backend build by default (for example, b1247),
    or a specific build with -Version.

.EXAMPLE
    .\Run-LlamaCpp.ps1 -TaskProfile general

.EXAMPLE
    .\Run-LlamaCpp.ps1 -TaskProfile coding -Backend vulkan -Version b8893
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("rocm-stable", "rocm-preview", "vulkan")]
    [string]$Backend = "rocm-stable",

    [Parameter()]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Model,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Alias,

    [Parameter()]
    [string]$MmProj,

    [Parameter()]
    [string]$ModelsPath = "C:\AI\models",

    [Parameter()]
    [string]$LlamaBaseFolder = "C:\AI\bin\llamacpp",

    [Parameter()]
    [int]$ContextSize = 8192,

    [Parameter()]
    [double]$Temperature = 1.0,

    [Parameter()]
    [double]$TopP = 0.95,

    [Parameter()]
    [Nullable[int]]$Seed,

    [Parameter()]
    [Nullable[int]]$TopK,

    [Parameter()]
    [Nullable[double]]$PresencePenalty,

    [Parameter()]
    [Nullable[double]]$MinP
)

$ErrorActionPreference = "Stop"

function Get-BuildFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackendFolder,

        [Parameter()]
        [string]$RequestedVersion
    )

    if (!(Test-Path $BackendFolder)) {
        throw "Backend folder not found: $BackendFolder"
    }

    if ($RequestedVersion) {
        $RequestedPath = Join-Path $BackendFolder $RequestedVersion
        if (!(Test-Path $RequestedPath)) {
            throw "Requested version '$RequestedVersion' not found in '$BackendFolder'."
        }
        return (Get-Item $RequestedPath)
    }

    $Builds = Get-ChildItem -Path $BackendFolder -Directory
    if (-not $Builds) {
        throw "No build folders found in '$BackendFolder'."
    }

    $VersionedBuilds = $Builds | ForEach-Object {
        $Match = [regex]::Match($_.Name, '^b(\d+)$')
        if ($Match.Success) {
            [PSCustomObject]@{
                Item    = $_
                Numeric = [int]$Match.Groups[1].Value
            }
        }
    } | Where-Object { $null -ne $_ }

    if ($VersionedBuilds) {
        return ($VersionedBuilds | Sort-Object Numeric -Descending | Select-Object -First 1).Item
    }

    return $Builds | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

$BackendFolder = Join-Path $LlamaBaseFolder $Backend
$BuildFolder = Get-BuildFolder -BackendFolder $BackendFolder -RequestedVersion $Version
$LlamaServer = Join-Path $BuildFolder.FullName "llama-server.exe"

if (!(Test-Path $LlamaServer)) {
    throw "llama-server.exe not found in '$($BuildFolder.FullName)'."
}

$env:HF_HOME = $ModelsPath

$LlamaServerArgs = @(
    "--model", (Join-Path $ModelsPath $Model),
    "--alias", $Alias,
    "--ctx-size", $ContextSize,
    "--temp", $Temperature,
    "--top-p", $TopP    
)

if (-not [string]::IsNullOrWhiteSpace($MmProj)) {
    $LlamaServerArgs += @("--mmproj", (Join-Path $ModelsPath $MmProj))
}

if ($null -ne $TopK) {
    $LlamaServerArgs += @("--top-k", $TopK)
}

if ($null -ne $PresencePenalty) {
    $LlamaServerArgs += @("--presence-penalty", $PresencePenalty)
}

if ($null -ne $MinP) {
    $LlamaServerArgs += @("--min-p", $MinP)
}
    
if ($null -ne $Seed) {
    $LlamaServerArgs += @("--seed", $Seed)
}

$LlamaServerArgs += @("-ngl", 99, "-fa", 1, "--jinja", "--no-mmap")

Write-Host "[INFO] Backend:  $Backend" -ForegroundColor Cyan
Write-Host "[INFO] Version:  $($BuildFolder.Name)" -ForegroundColor Cyan
Write-Host "[INFO] Binary:   $LlamaServer" -ForegroundColor Gray
Write-Host "[INFO] Args:     $($LlamaServerArgs -join ' ')" -ForegroundColor Gray
Write-Host ""

Push-Location $BuildFolder.FullName

try {
    & $LlamaServer @LlamaServerArgs
}
finally {
    Pop-Location
}
