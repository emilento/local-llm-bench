<#
.SYNOPSIS
    Convenience wrapper for GLM-4.7-Flash.
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
    -Model "models--unsloth--GLM-4.7-Flash-GGUF/snapshots/0d32489ecb9db6d2a4fc93bd27ef01519f95474d/GLM-4.7-Flash-UD-Q8_K_XL.gguf" `
    -Alias "unsloth/GLM-4.7-Flash-GGUF" `
    -ContextSize $ContextSize `
    -Seed 3407 `
    -Temperature 1.0 `
    -TopP 0.95 `
    -MinP 0.01
