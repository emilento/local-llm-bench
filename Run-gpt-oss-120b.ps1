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
    -Model "models--ggml-org--gpt-oss-120b-GGUF/snapshots/d932fcea62f83e088d8f076a2cd2d7eb02dfa682/gpt-oss-120b-mxfp4-00001-of-00003.gguf" `
    -Alias "ggml-org/gpt-oss-120b-GGUF" `
    -ContextSize $ContextSize `
    -Temperature 1.0 `
    -TopP 1.0 `
    -TopK 0
