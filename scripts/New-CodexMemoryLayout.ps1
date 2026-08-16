[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $VaultPath,

    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string] $ProjectSlug = 'example-project'
)

$ErrorActionPreference = 'Stop'

function Get-ComparablePath {
    param([Parameter(Mandatory)] [string] $Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

$normalizedVaultPath = [IO.Path]::GetFullPath($VaultPath)
$comparableVaultPath = Get-ComparablePath -Path $normalizedVaultPath
$comparableRootPath = Get-ComparablePath -Path ([IO.Path]::GetPathRoot($normalizedVaultPath))

if ($comparableVaultPath.Equals($comparableRootPath, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'VaultPath cannot be a drive or filesystem root.'
}

$homePath = [Environment]::GetFolderPath('UserProfile')
if ($homePath) {
    $comparableHomePath = Get-ComparablePath -Path $homePath
    if ($comparableVaultPath.Equals($comparableHomePath, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'VaultPath cannot be the user home directory.'
    }
}

$directories = @(
    'global/conversations',
    'global/inbox',
    'global/profile',
    'global/knowledge',
    'global/experience',
    'global/decisions',
    "projects/$ProjectSlug/checkpoints",
    "projects/$ProjectSlug/remember",
    "projects/$ProjectSlug/decisions",
    "projects/$ProjectSlug/experience"
)

$null = New-Item -ItemType Directory -Path $normalizedVaultPath -Force
foreach ($relativePath in $directories) {
    $null = New-Item -ItemType Directory -Path (Join-Path $normalizedVaultPath $relativePath) -Force
}

$readmePath = Join-Path $normalizedVaultPath 'README.md'
if ((Test-Path -LiteralPath $readmePath) -and -not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
    throw 'README.md exists but is not a file.'
}

if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
    $readme = @"
# Codex Memory Vault

This Vault stores local memory data outside the framework repository.

- Register `global/` as the global Basic Memory Project.
- Register `projects/$ProjectSlug/` as a separate project-scoped Basic Memory Project.
- Do not register this Vault root as a Project.
- Do not commit this Vault to the framework repository.
"@
    Set-Content -LiteralPath $readmePath -Value $readme -Encoding utf8
}

Write-Host 'LAYOUT_CREATED=PASS'
Write-Host 'BASIC_MEMORY_REGISTRATION=NOT_PERFORMED'
