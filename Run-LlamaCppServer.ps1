<#
.SYNOPSIS
    Generic llama.cpp runner with task profiles and backend/version selection.

.DESCRIPTION
    Selects the latest installed backend build by default (for example, b1247),
    or a specific build with -Version.

.EXAMPLE
    .\Run-LlamaCpp.ps1 -Backend vulkan 
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("rocm-stable", "rocm-preview", "vulkan")]
    [string]$Backend = "rocm-stable",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Model,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Alias,

    [Parameter()]
    [string]$MmProj,

    [Parameter()]
    [string]$ModelsPath = "C:\Users\emilento\.cache\huggingface\hub",

    [Parameter()]
    [string]$LlamaBaseFolder = "C:\Users\emilento\.cache\lemonade\bin\llamacpp\",

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

$BackendFolder = Join-Path $LlamaBaseFolder $Backend
$LlamaServer = Join-Path $BackendFolder "llama-server.exe"

if (!(Test-Path $LlamaServer)) {
    throw "llama-server.exe not found in '$BackendFolder'."
}

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

$LlamaServerArgs += @("-ngl", 999, "-fa", 1, "--jinja", "--no-mmap")

Write-Host "[INFO] Backend:  $Backend" -ForegroundColor Cyan
Write-Host "[INFO] Binary:   $LlamaServer" -ForegroundColor Gray
Write-Host "[INFO] Args:     $($LlamaServerArgs -join ' ')" -ForegroundColor Gray
Write-Host ""

Push-Location $BackendFolder

try {
    & $LlamaServer @LlamaServerArgs
}
finally {
    Pop-Location
}
