<#
.SYNOPSIS
    Downloads files directly from Hugging Face using Invoke-WebRequest.

.DESCRIPTION
    Downloads one or more files from Hugging Face model repositories.
    Supports resuming interrupted downloads and shows progress.

.PARAMETER Repo
    Hugging Face model path, for example: unsloth/Qwen3.6-35B-A3B-GGUF.

.PARAMETER Files
    One or more files within the model repository.
    Used with -Repo to auto-build URLs in the form:
    https://huggingface.co/<model>/resolve/<revision>/<file>?download=true

.PARAMETER Revision
    Repo revision/branch. Defaults to main.

.PARAMETER OutputFolder
    Destination folder. Defaults to C:\AI\models.

.EXAMPLE
    .\Download-HuggingFace.ps1 `
        -Repo "unsloth/Qwen3.6-35B-A3B-GGUF" `
        -Files @(
            "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf",
            "mmproj-BF16.gguf"
        ) `
        -OutputFolder "C:\AI\models\unsloth\Qwen3.6-35B-A3B-GGUF"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Repo,

    [Parameter(Mandatory = $true)]
    [string[]] $Files,

    [Parameter(Mandatory = $false)]
    [string] $Revision = "main",

    [Parameter(Mandatory = $false)]
    [string] $OutputFolder = "C:\AI\models"
)

$ErrorActionPreference = "Stop"

$HuggingFaceBaseUrl = "https://huggingface.co"

function Build-UrlList {
    $resolvedUrls = @()

    if (-not $Files -or $Files.Count -eq 0) {
        throw "-Files cannot be empty."
    }

    $trimmedModel = $Repo.Trim('/').Trim()
    foreach ($file in $Files) {
        $trimmedFile = $file.Trim('/').Trim()
        $resolvedUrls += "$HuggingFaceBaseUrl/$trimmedModel/resolve/$Revision/${trimmedFile}?download=true"
    }

    if (-not $resolvedUrls -or $resolvedUrls.Count -eq 0) {
        throw "No download URLs were generated from -Repo and -Files."
    }

    return $resolvedUrls
}

function Get-FileNameFromUrl {
    param ([string] $Url)

    # Strip query string, then extract the last path segment
    $cleanUrl = $Url -replace '\\\?', '?'
    $path = (($cleanUrl -split '\?')[0]).TrimEnd('/', '\')
    $fileName = [System.IO.Path]::GetFileName($path)
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        throw "Unable to extract filename from URL: $Url"
    }
    return $fileName
}

function Get-RemoteFileSize {
    param ([string] $Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -MaximumRedirection 10
        $contentLength = $response.Headers['Content-Length']
        if ($contentLength) { 
            return [long] $contentLength
        }
    }
    catch {
        # HEAD not supported — size unknown
    }
    return $null
}

function Format-FileSize {
    param ([long] $Bytes)

    if ($Bytes -ge 1GB) { 
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    
    if ($Bytes -ge 1MB) { 
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }

    if ($Bytes -ge 1KB) { 
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }

    return "$Bytes B"
}

function Invoke-Download {
    param (
        [string] $Url,
        [string] $DestinationPath
    )

    $remoteSize = Get-RemoteFileSize -Url $Url

    if ($remoteSize) {
        Write-Host "  Remote size : $(Format-FileSize $remoteSize)" -ForegroundColor DarkGray
    }

    # Resume support: if partial file exists and we know the remote size, check if already complete
    if (Test-Path $DestinationPath) {
        $localSize = (Get-Item $DestinationPath).Length
        if ($remoteSize -and $localSize -eq $remoteSize) {
            Write-Host "  Already complete, skipping." -ForegroundColor Green
            return
        }
        Write-Host "  Partial file found ($( Format-FileSize $localSize )), restarting download." -ForegroundColor Yellow
        Remove-Item $DestinationPath -Force
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Host "  Downloading..." -ForegroundColor Cyan

    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $DestinationPath `
        -UseBasicParsing `
        -MaximumRedirection 10

    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed
    $localSize = (Get-Item $DestinationPath).Length
    $speed = if ($elapsed.TotalSeconds -gt 0) { $localSize / $elapsed.TotalSeconds } else { 0 }

    Write-Host "  Done. $(Format-FileSize $localSize) in $( '{0:mm\:ss}' -f $elapsed ) ($( Format-FileSize ([long]$speed) )/s)" -ForegroundColor Green
}

$ResolvedUrls = Build-UrlList

if (-not $PSBoundParameters.ContainsKey('OutputFolder')) {
    $OutputFolder = Join-Path "C:\AI\models" (($Repo.Replace('/', '\')).Trim('\'))
}

if (-not (Test-Path $OutputFolder)) {
    Write-Host "[*] Creating output folder: $OutputFolder" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$total = $ResolvedUrls.Count
$current = 0

foreach ($url in $ResolvedUrls) {
    $current++
    $fileName = Get-FileNameFromUrl -Url $url
    $destinationPath = Join-Path $OutputFolder $fileName

    Write-Host ""
    Write-Host "[$current/$total] $fileName" -ForegroundColor White
    Write-Host "  URL  : $url" -ForegroundColor DarkGray
    Write-Host "  Dest : $destinationPath" -ForegroundColor DarkGray

    try {
        Invoke-Download -Url $url -DestinationPath $destinationPath
    }
    catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "All downloads complete." -ForegroundColor Green
