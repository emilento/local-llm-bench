<#
.SYNOPSIS
    Convenience wrapper for Qwen3.6-35B-A3B coding tasks.
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
    -Model "unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf," `
    -MmProj "unsloth/Qwen3.6-35B-A3B-GGUF/mmproj-BF16.gguf" `
    -Alias "unsloth/Qwen3.6-35B-A3B-GGUF-Coding" `
    -ContextSize $ContextSize `
    -Temperature 0.6 `
    -TopP 0.95 `
    -TopK 20 `
    -PresencePenalty 0.0 `
    -MinP 0.00
