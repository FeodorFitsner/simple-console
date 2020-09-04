$PACKAGES_ROOT = "$env:SYSTEMDRIVE\avvm"
$REGISTRY_ROOT = 'HKLM:\Software\AppVeyor\VersionManager'
$downloadRoot = $null

function Get-DownloadRoot {
    if(-not $downloadRoot) {
		if($env:AVVM_DOWNLOAD_URL) {
			$downloadRoot = $env:AVVM_DOWNLOAD_URL
		} else {
			$storageAccountName = (Invoke-RestMethod "$env:APPVEYOR_URL/api/buildjobs/$env:APPVEYOR_JOB_ID/downloadstorage")
			if($storageAccountName.indexOf('://') -eq -1) {
				$downloadRoot = "http://$storageAccountName.blob.core.windows.net/downloads/avvm"
			} else {
				$downloadRoot = $storageAccountName
			}
		}
    }
    return $downloadRoot
}

function Parse-Version([string]$str) {
    $versionDigits = $str.Split('.')
    $version = @{
        major = -1
        minor = -1
        build = -1
        revision = -1
        number = 0
        value = $null
    }

    $version.value = $str

    if($versionDigits -and $versionDigits.Length -gt 0) {
        $version.major = [int]$versionDigits[0]
    }
    if($versionDigits.Length -gt 1) {
        $version.minor = [int]$versionDigits[1]
    }
    if($versionDigits.Length -gt 2) {
        $version.build = [int]$versionDigits[2]
    }
    if($versionDigits.Length -gt 3) {
        $version.revision = [int]$versionDigits[3]
    }

    for($i = 0; $i -lt $versionDigits.Length; $i++) {
        $version.number += [long]$versionDigits[$i] -shl 16 * (3 - $i)
    }

    return $version
}

function Get-MaxVersion([string]$product, [string]$majorVersion) {
    # fetch available versions
    $content = (New-Object Net.WebClient).DownloadString("$(Get-DownloadRoot)/$product-versions.txt")

    $allVersions = $content.split(@("`n","`r"), [System.StringSplitOptions]::RemoveEmptyEntries)

    if($majorVersion -eq 'lts') {
        $majorVersion = $allVersions | Where-Object { $_.StartsWith("lts:") } | % { $_.split(':')[1] }
    } elseif ($majorVersion -eq 'stable') {
        $majorVersion = $allVersions | Where-Object { $_.StartsWith("stable:") } | % { $_.split(':')[1] }
    } elseif ($majorVersion -eq 'current') {
        $majorVersion = $allVersions | Where-Object { $_.StartsWith("current:") } | % { $_.split(':')[1] }
    }

    # parse versions and find the latest
    $versions = $allVersions | Where-Object {"$_.".StartsWith("$majorVersion.") -or -not $majorVersion }

    if($versions.Count -eq 0) {
        return $null
    }
    elseif($versions.indexOf('.') -ne -1) {
        return $versions
    } else {
        $maxVersion = $versions[0]
        for($i = 0; $i -lt $versions.Count; $i++) {
            if(-not $versions[$i].Contains(':') -and ((Parse-Version $versions[$i]).number -gt (Parse-Version $maxVersion).number)) {
                $maxVersion = $versions[$i]
            }
        }
        return $maxVersion
    }
}

function GetProductVersion($product, $version, $platform) {
    # version
    $version = Get-MaxVersion $product $version

    $path = Join-Path (Join-Path (Join-Path $PACKAGES_ROOT $product) $version) $platform 

    if(-not (Test-Path $path)) {
        $packageName = "$product-$version-$platform.7z"
        $zipPath = "$($env:USERPROFILE)\$packageName"
        $downloadUrl = "$(Get-DownloadRoot)/$packageName"
        try
        {
            (New-Object Net.WebClient).DownloadFile($downloadUrl, $zipPath)
            7z x $zipPath -y -o"$path" | Out-Null
            del $zipPath
        }
        catch [system.net.webexception]
        {
            if($_.Exception.Response.StatusCode -eq 'NotFound') {
                throw "$product $version $platform package not found"
            }
        }
    }

    return @{
        Path = $path
        Version = $version
    }
}

function GetInstalledProductVersion($product) {
    $productRegPath = "$REGISTRY_ROOT\$product"
    if(Test-Path $productRegPath) {
        $ver = Get-ItemProperty -Path $productRegPath
        @{
            Product = $product
            Version = $ver.Version
            Platform = $ver.Platform
        }
    }
}

function Uninstall-Product {
    Param(
      [Parameter(Mandatory=$true, Position=1)]
      [string]$Product,

      [Parameter(Mandatory=$true, Position=2)]
      [string]$Version,

      [Parameter(Mandatory=$true, Position=3)]
      [string]$Platform
    )
    $productVersion = GetProductVersion $product $version $platform
    $productPath = $productVersion.Path
    $version = $productVersion.Version

    Write-Host "Uninstalling $product $version ($platform)..."

    # load file mappings
    $files = $null
    $filesPath = Join-Path $productPath 'files.ps1'
    if(Test-Path $filesPath) {
        . $filesPath
    }

    # move folders from local paths to package paths
    if($files) {
        $files.GetEnumerator() | ForEach-Object {
            $itemPackagePath = [IO.Path]::Combine((Resolve-Path $productPath), $_.Name)
            $itemLocalPath = $_.Value
            if ([IO.File]::Exists($itemLocalPath)) {
                if ([IO.File]::Exists($itemPackagePath)) {
                    Remove-Item $itemPackagePath -Force
                }
                [IO.File]::Move($itemLocalPath, $itemPackagePath)
            } elseif ([IO.Directory]::Exists($itemLocalPath)) {
                if ([IO.Directory]::Exists($itemPackagePath)) {
                    Remove-Item $itemPackagePath -Recurse -Force
                }
                [IO.Directory]::Move($itemLocalPath, $itemPackagePath)
            }
        }
    }

    # run uninstall.ps1
    $uninstallScript = Join-Path $productPath 'uninstall.ps1'
    if(Test-Path $uninstallScript) {
        . $uninstallScript
    }

    # remove product version registry key
    $productRegPath = "$REGISTRY_ROOT\$product"
    if(Test-Path $productRegPath) {
        Remove-Item $productRegPath -Force
    }
}

function InstallProduct($product, $version, $platform) {
    $productVersion = GetProductVersion $product $version $platform
    $productPath = $productVersion.Path
    $version = $productVersion.Version

    Write-Host "Installing $product $version ($platform)..."

    # load file mappings
    $files = $null
    $filesPath = Join-Path $productPath 'files.ps1'
    if(Test-Path $filesPath) {
        . $filesPath
    }

    # move folders from package paths to local paths
    if($files) {
        $files.GetEnumerator() | ForEach-Object {
            $itemPackagePath = [IO.Path]::Combine((Resolve-Path $productPath), $_.Name)
            $itemLocalPath = $_.Value
            if ([IO.File]::Exists($itemPackagePath)) {
                if ([IO.File]::Exists($itemLocalPath)) {
                    Remove-Item $itemLocalPath -Force
                }
                [IO.File]::Move($itemPackagePath, $itemLocalPath)
            } elseif ([IO.Directory]::Exists($itemPackagePath)) {
                if ([IO.Directory]::Exists($itemLocalPath)) {
                    Remove-Item $itemLocalPath -Recurse -Force
                }
                [IO.Directory]::Move($itemPackagePath, $itemLocalPath)
            }
        }
    }

    # run install.ps1
    $installScript = Join-Path $productPath 'install.ps1'
    if(Test-Path $installScript) {
        . $installScript
    }

    # add product version registry key
    $productRegPath = "$REGISTRY_ROOT\$product"
    New-Item $productRegPath -Force | Out-Null
    New-ItemProperty -Path $productRegPath -Name Version -PropertyType String -Value $version -Force | Out-Null
    New-ItemProperty -Path $productRegPath -Name Platform -PropertyType String -Value $platform -Force | Out-Null
}

function Install-Product {
    Param(
      [Parameter(Mandatory=$true, Position=1)]
      [string]$Product,

      [Parameter(Mandatory=$false, Position=2)]
      [string]$Version = $null,

      [Parameter(Mandatory=$false, Position=3)]
      [string]$Platform = $null
    )

    $installed = GetInstalledProductVersion $Product

    # display installed product if version is not specified
    if ($Version -eq $null) {
        $installed
        return
    }

    # determine platform if not specified
    if (-not $Platform) {
        $maxVersion = Get-MaxVersion $Product $Version
        if ((Parse-Version $maxVersion).major -ge 14) {
            # Set Node 14.x to x64 because of bug: https://github.com/appveyor/ci/issues/3407#issuecomment-680316850
            $Platform = 'x64'
        } else {
            $Platform = 'x86'
        }
    }

    $productVersion = GetProductVersion $Product $Version $Platform
    $Version = $productVersion.Version

    # uninstall existing version if found
    if($installed -and ($Version -ne $installed.Version -or $Platform -ne $installed.Platform))
    {
        Uninstall-Product $Product $installed.Version $installed.Platform
    }

    if(-not $installed -or ($installed -and ($Version -ne $installed.Version -or $Platform -ne $installed.Platform)))
    {
        InstallProduct $Product $Version $Platform
    }
}

# export module members
Export-ModuleMember -Function Install-Product, Uninstall-Product, Get-MaxVersion
