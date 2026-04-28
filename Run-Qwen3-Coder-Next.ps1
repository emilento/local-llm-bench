<#
.SYNOPSIS
    Convenience wrapper for Qwen3-Coder-Next.
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
    -Model "unsloth/Qwen3-Coder-Next-GGUF/Qwen3-Coder-Next-UD-Q4_K_XL.gguf" `
    -Alias "unsloth/Qwen3-Coder-Next-GGUF" `
    -ContextSize $ContextSize `
    -Temperature 1.0 `
    -TopP 0.95 `
    -TopK 40 `
    -MinP 0.01
