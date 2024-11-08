#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

function Main() {
  $watch = [Diagnostics.Stopwatch]::StartNew()

  if ($PSCommandPath -eq "") {
    Write-Host "PSCommandPath is empty."
    exit 1
  }

  [string] $listfile = Join-Path (Split-Path $PSCommandPath) "dockerimages.txt"
  if (!(Test-Path $listfile)) {
    Write-Host "Listfile not found: '$listfile'"
    exit 1
  }

  [string[]] $images = Get-Content $listfile | ? { !$_.TrimStart().StartsWith("#") -and $_ }

  Pull-Images $images
  Write-ExcessiveImages $images

  Write-Host "Done: $($watch.Elapsed)" -f Green
}

function Pull-Images([string[]] $images) {
  Write-Host "Pulling $($images.Count) images..." -f Green

  $ErrorActionPreference = "Continue"

  foreach ($image in $images) {
    Write-Host "Pulling $image" -f Green
    docker pull $image
  }

  $ErrorActionPreference = "Stop"

  docker system prune -f
  docker images | sort
}

function Write-ExcessiveImages([string[]] $images) {
  $currentimages = docker images | grep -v '^REPOSITORY' | sort | awk '{print $1 ":" $2}'
  for ([int] $i = 0; $i -lt $currentimages.Length; $i++) {
    if ($currentimages[$i].EndsWith(":latest")) {
      $currentimages[$i] = $currentimages[$i].Substring(0, $currentimages[$i].Length - 7)
    }
  }

  foreach ($image in $currentimages) {
    if ($images -notcontains $image) {
      Write-Host "Excessive image: '$image'" -f Yellow
    }
  }
}

Main
