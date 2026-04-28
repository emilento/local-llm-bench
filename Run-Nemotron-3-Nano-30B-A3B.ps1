<#
.SYNOPSIS
    Convenience wrapper for Nemotron-3-Nano-30B-A3B.
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
    -Model "unsloth/Nemotron-3-Nano-30B-A3B-GGUF/Nemotron-3-Nano-30B-A3B-UD-Q8_K_XL.gguf" `
    -Alias "unsloth/Nemotron-3-Nano-30B-A3B-GGUF" `
    -ContextSize $ContextSize `
    -Seed 3407 `
    -Temperature 0.6 `
    -TopP 0.95 `
    -MinP 0.01
