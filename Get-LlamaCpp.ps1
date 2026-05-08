<#
.SYNOPSIS
    Downloads ROCm and Vulkan llama.cpp binaries.
#>

$ErrorActionPreference = "Stop"

$BaseFolder = "C:\AI\bin\llamacpp"

$Sources = @(
    @{ 
        Repo      = "lemonade-sdk/llamacpp-rocm" 
        Pattern   = "*windows-rocm-gfx1151-x64.zip" 
        Label     = "ROCm (Preview)" 
        SubFolder = "rocm-preview"
    },
    @{ 
        Repo      = "ggml-org/llama.cpp" 
        Pattern   = "*-win-hip-radeon-x64.zip" 
        Label     = "ROCm (Stable)" 
        SubFolder = "rocm-stable"
    },
    @{ 
        Repo      = "ggml-org/llama.cpp" 
        Pattern   = "*win-vulkan-x64.zip"
        Label     = "Vulkan" 
        SubFolder = "vulkan"
    }
)

function Initialize-Environment {
    if (!(Test-Path $BaseFolder)) {
        Write-Host "[*] Creating download directory: $BaseFolder" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $BaseFolder | Out-Null
    }
}

function Get-VersionFromRelease {
    param (
        $ReleaseInfo
    )

    if ($ReleaseInfo.tag_name) {
        return $ReleaseInfo.tag_name
    }

    if ($ReleaseInfo.name) {
        return $ReleaseInfo.name
    }

    if ($ReleaseInfo.published_at) {
        return ([DateTime]$ReleaseInfo.published_at).ToString("yyyyMMdd")
    }

    return "unknown-version"
}

function Format-FolderName {
    param (
        [string]$Name
    )

    $InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $Sanitized = $Name

    foreach ($Char in $InvalidChars) {
        $Sanitized = $Sanitized.Replace($Char, "-")
    }

    return $Sanitized.Trim()
}

function Get-FromRepoAndInstall {
    param (
        [string]$Repo,
        [string]$Pattern,
        [string]$Label,
        [string]$SubFolder
    )

    try {
        # 1. Fetch latest release from GitHub API
        $ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        Write-Host "[*] Fetching $Label from $Repo..." -ForegroundColor Cyan
        
        $ReleaseInfo = Invoke-RestMethod -Uri $ApiUrl
        $VersionRaw = Get-VersionFromRelease -ReleaseInfo $ReleaseInfo
        $Version = Format-FolderName -Name $VersionRaw

        # 2. Setup destination folder (<source>/<version>)
        $ExtractPath = Join-Path (Join-Path $BaseFolder $SubFolder) $Version
        if (Test-Path $ExtractPath) {
            Write-Host "    Clearing destination: $ExtractPath" -ForegroundColor Gray
            Remove-Item -Path $ExtractPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null

        $Asset = $ReleaseInfo.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1

        if ($Asset) {
            $ZipFile = Join-Path $BaseFolder "$($Asset.name)"
            
            # 3. Cleanup zip file
            if (Test-Path $ZipFile) {
                Remove-Item -Path $ZipFile -Force
            }
           
            # 4. Download
            Write-Host "[+] Found: $($Asset.name) (version: $VersionRaw). Downloading..." -ForegroundColor Green
            Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ZipFile
            
            # 5. Extract
            Write-Host "    Extracting to $ExtractPath..." -ForegroundColor Gray
            Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force
            
            Write-Host "[!] $Label installation complete." -ForegroundColor Green

            return [PSCustomObject]@{
                Label       = $Label
                SubFolder   = $SubFolder
                Version     = $VersionRaw
                ExtractPath = $ExtractPath
                Success     = $true
            }
        }
        else {
            Write-Warning "[-] No binary matching '$Pattern' found in $Repo."

            return [PSCustomObject]@{
                Label       = $Label
                SubFolder   = $SubFolder
                Version     = $null
                ExtractPath = $null
                Success     = $false
            }
        }
    }
    catch {
        Write-Warning ("[-] Failed to fetch from {0}: {1}" -f $Repo, $_.Exception.Message)

        return [PSCustomObject]@{
            Label       = $Label
            SubFolder   = $SubFolder
            Version     = $null
            ExtractPath = $null
            Success     = $false
        }
    }
}

try {
    Initialize-Environment

    $InstallResults = @()

    foreach ($Source in $Sources) {
        $Result = Get-FromRepoAndInstall `
            -Repo $Source.Repo `
            -Pattern $Source.Pattern `
            -Label $Source.Label `
            -SubFolder $Source.SubFolder

        if ($null -ne $Result) {
            $InstallResults += $Result
        }
    }

    Write-Host "`n[SUCCESS] All binaries processed successfully!" -ForegroundColor Cyan
    Write-Host "Paths (versioned):" -ForegroundColor Gray

    foreach ($Source in $Sources) {
        $Result = $InstallResults | Where-Object { $_.SubFolder -eq $Source.SubFolder } | Select-Object -First 1
        $SummaryLabel = " {0}:" -f $Source.Label.PadRight(14)

        if ($Result -and $Result.Success) {
            Write-Host ("{0} {1}" -f $SummaryLabel, $Result.ExtractPath) -ForegroundColor White
        }
        else {
            Write-Host ("{0} (not installed this run)" -f $SummaryLabel) -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "A critical error occurred: $($_.Exception.Message)"
}
