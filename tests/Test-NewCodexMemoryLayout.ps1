[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot 'scripts/New-CodexMemoryLayout.ps1'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
$testRoot = Join-Path $tempRoot ("codex-memory-layout-test-{0}" -f [guid]::NewGuid().ToString('N'))
$vaultPath = Join-Path $testRoot 'vault'

function Assert-True {
    param(
        [Parameter(Mandatory)] [bool] $Condition,
        [Parameter(Mandatory)] [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

try {
    Assert-True -Condition (Test-Path -LiteralPath $scriptPath -PathType Leaf) -Message 'Layout script is missing.'

    $firstRunOutput = (& $scriptPath -VaultPath $vaultPath -ProjectSlug 'sample-project' 6>&1 | Out-String)
    Assert-True -Condition (-not $firstRunOutput.Contains($vaultPath, [StringComparison]::OrdinalIgnoreCase)) -Message 'The script printed the private VaultPath.'

    $expectedDirectories = @(
        'global/conversations',
        'global/inbox',
        'global/profile',
        'global/knowledge',
        'global/experience',
        'global/decisions',
        'projects/sample-project/checkpoints',
        'projects/sample-project/remember',
        'projects/sample-project/decisions',
        'projects/sample-project/experience'
    )

    foreach ($relativePath in $expectedDirectories) {
        $fullPath = Join-Path $vaultPath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $fullPath -PathType Container) -Message "Missing directory: $relativePath"
    }

    $readmePath = Join-Path $vaultPath 'README.md'
    Assert-True -Condition (Test-Path -LiteralPath $readmePath -PathType Leaf) -Message 'Vault README was not created.'

    $customReadme = "# Keep this content`n"
    Set-Content -LiteralPath $readmePath -Value $customReadme -NoNewline -Encoding utf8
    $null = (& $scriptPath -VaultPath $vaultPath -ProjectSlug 'sample-project' 6>&1)
    Assert-True -Condition ((Get-Content -LiteralPath $readmePath -Raw) -eq $customReadme) -Message 'Second run overwrote the existing Vault README.'

    $rootRejected = $false
    try {
        & $scriptPath -VaultPath ([IO.Path]::GetPathRoot($vaultPath)) -ProjectSlug 'sample-project'
    }
    catch {
        $rootRejected = $true
    }
    Assert-True -Condition $rootRejected -Message 'The script accepted a drive root as VaultPath.'

    $homeRejected = $false
    try {
        & $scriptPath -VaultPath ([Environment]::GetFolderPath('UserProfile')) -ProjectSlug 'sample-project'
    }
    catch {
        $homeRejected = $true
    }
    Assert-True -Condition $homeRejected -Message 'The script accepted the user home directory as VaultPath.'

    $invalidReadmeVault = Join-Path $testRoot 'invalid-readme-vault'
    $null = New-Item -ItemType Directory -Path (Join-Path $invalidReadmeVault 'README.md') -Force
    $readmeDirectoryRejected = $false
    try {
        $null = (& $scriptPath -VaultPath $invalidReadmeVault -ProjectSlug 'sample-project' 6>&1)
    }
    catch {
        $readmeDirectoryRejected = $true
    }
    Assert-True -Condition $readmeDirectoryRejected -Message 'The script accepted a README.md directory where a file is required.'

    Write-Host 'LAYOUT_TEST=PASS'
}
catch {
    Write-Host "LAYOUT_TEST=FAIL - $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
        $expectedPrefix = $tempRoot + [IO.Path]::DirectorySeparatorChar
        if (-not $resolvedTestRoot.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean an unexpected path: $resolvedTestRoot"
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
