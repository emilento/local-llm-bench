<#
.SYNOPSIS
    Convenience wrapper for GPT-OSS-20B.
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
    -Model "models--unsloth--gpt-oss-20b-GGUF/snapshots/d449b42d93e1c2c7bda5312f5c25c8fb91dfa9b4/gpt-oss-20b-UD-Q8_K_XL.gguf" `
    -Alias "unsloth/gpt-oss-20b-GGUF" `
    -ContextSize $ContextSize `
    -Temperature 1.0 `
    -TopP 1.0 `
    -TopK 0
