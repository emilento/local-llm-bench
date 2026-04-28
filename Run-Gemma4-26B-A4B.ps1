<#
.SYNOPSIS
    Convenience wrapper for Gemma4-26B-A4B.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$ContextSize = 4 * 8192
)

$Runner = Join-Path $PSScriptRoot "Run-LlamaCppServer.ps1"
if (!(Test-Path $Runner)) {
    throw "Runner script not found: $Runner"
}

& $Runner `
    -Model "unsloth/gemma-4-26B-A4B-it-GGUF/gemma-4-26B-A4B-it-UD-Q8_K_XL.gguf" `
    -MmProj "unsloth/gemma-4-26B-A4B-it-GGUF/mmproj-BF16.gguf" `
    -Alias "unsloth/gemma-4-26B-A4B-it-GGUF" `
    -ContextSize $ContextSize `
    -Temperature 1.0 `
    -TopP 0.95 `
    -TopK 64
