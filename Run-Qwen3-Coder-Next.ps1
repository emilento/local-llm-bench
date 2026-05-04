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
    -Model "models--unsloth--Qwen3-Coder-Next-GGUF/snapshots/ce09c67b53bc8739eef83fe67b2f5d293c270632/UD-Q8_K_XL/Qwen3-Coder-Next-UD-Q8_K_XL-00001-of-00003.gguf" `
    -Alias "unsloth/Qwen3-Coder-Next-GGUF" `
    -ContextSize $ContextSize `
    -Temperature 1.0 `
    -TopP 0.95 `
    -TopK 40 `
    -MinP 0.01
