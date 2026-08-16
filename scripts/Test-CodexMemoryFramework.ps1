[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Write-CheckResult {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Passed,
        [string] $Detail = ''
    )

    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    $suffix = if ($Detail) { " - $Detail" } else { '' }
    Write-Host "$Name=$status$suffix"
}

$failures = [System.Collections.Generic.List[string]]::new()

$requiredFiles = @(
    '.gitignore',
    '.github/assets/readme/hero.svg',
    'LICENSE',
    'SECURITY.md',
    'README.md',
    'docs/architecture.md',
    'docs/deployment-guide.md',
    'docs/user-guide.md',
    'scripts/New-CodexMemoryLayout.ps1',
    'scripts/Test-CodexMemoryFramework.ps1',
    'templates/user/basic-memory.example.json',
    'templates/project/basic-memory.example.json',
    'templates/vault/README.md',
    'tests/Test-NewCodexMemoryLayout.ps1'
)

$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf) })
if ($missing.Count -gt 0) {
    $failures.Add("缺少必需文件：$($missing -join ', ')")
}
Write-CheckResult -Name 'REQUIRED_FILES' -Passed ($missing.Count -eq 0) -Detail ($missing -join ', ')

$jsonFiles = @(
    'templates/user/basic-memory.example.json',
    'templates/project/basic-memory.example.json'
)
$jsonErrors = [System.Collections.Generic.List[string]]::new()
foreach ($relativePath in $jsonFiles) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    try {
        $null = Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json
    }
    catch {
        $jsonErrors.Add("$relativePath：$($_.Exception.Message)")
    }
}
if ($jsonErrors.Count -gt 0) {
    $failures.AddRange($jsonErrors)
}
Write-CheckResult -Name 'JSON_TEMPLATES' -Passed ($jsonErrors.Count -eq 0) -Detail ($jsonErrors -join '; ')

$placeholderRequirements = [ordered]@{
    'templates/user/basic-memory.example.json' = @('<GLOBAL_MEMORY_PROJECT>')
    'templates/project/basic-memory.example.json' = @('<PROJECT_MEMORY_PROJECT>', '<GLOBAL_MEMORY_PROJECT>', '<REPOSITORY_IDENTIFIER>')
    'templates/vault/README.md' = @('<VAULT_PATH>', '<PROJECT_SLUG>')
}
$placeholderErrors = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $placeholderRequirements.GetEnumerator()) {
    $fullPath = Join-Path $repoRoot $entry.Key
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    foreach ($placeholder in $entry.Value) {
        if (-not $content.Contains($placeholder, [StringComparison]::Ordinal)) {
            $placeholderErrors.Add("$($entry.Key)：缺少 $placeholder")
        }
    }
}
if ($placeholderErrors.Count -gt 0) {
    $failures.AddRange($placeholderErrors)
}
Write-CheckResult -Name 'PLACEHOLDERS' -Passed ($placeholderErrors.Count -eq 0) -Detail ($placeholderErrors -join '; ')

$syntaxErrors = [System.Collections.Generic.List[string]]::new()
foreach ($scriptFile in Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scripts'), (Join-Path $repoRoot 'tests') -Filter '*.ps1' -File) {
    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptFile.FullName,
        [ref] $tokens,
        [ref] $parseErrors
    )
    foreach ($parseError in $parseErrors) {
        $relativePath = [IO.Path]::GetRelativePath($repoRoot, $scriptFile.FullName)
        $syntaxErrors.Add("$relativePath：$($parseError.Message)")
    }
}
if ($syntaxErrors.Count -gt 0) {
    $failures.AddRange($syntaxErrors)
}
Write-CheckResult -Name 'POWERSHELL_SYNTAX' -Passed ($syntaxErrors.Count -eq 0) -Detail ($syntaxErrors -join '; ')

$svgErrors = [System.Collections.Generic.List[string]]::new()
foreach ($svgFile in Get-ChildItem -LiteralPath (Join-Path $repoRoot '.github/assets/readme') -Filter '*.svg' -File -ErrorAction SilentlyContinue) {
    try {
        $document = [xml] (Get-Content -LiteralPath $svgFile.FullName -Raw)
        if ($document.DocumentElement.LocalName -ne 'svg') {
            throw '根元素不是 svg。'
        }
    }
    catch {
        $relativePath = [IO.Path]::GetRelativePath($repoRoot, $svgFile.FullName)
        $svgErrors.Add("$relativePath：$($_.Exception.Message)")
    }
}
if ($svgErrors.Count -gt 0) {
    $failures.AddRange($svgErrors)
}
Write-CheckResult -Name 'SVG_ASSETS' -Passed ($svgErrors.Count -eq 0) -Detail ($svgErrors -join '; ')

$gitCandidates = @(& git -C $repoRoot ls-files --cached --others --exclude-standard 2>$null)
if ($LASTEXITCODE -ne 0) {
    throw '无法读取 Git 跟踪候选文件。请确认脚本在 Git 仓库中运行。'
}

$textExtensions = @('.md', '.json', '.ps1', '.psm1', '.txt', '.yml', '.yaml', '.svg', '.gitignore')
$forbiddenPatterns = [ordered]@{
    'personal Windows profile path' = [regex]::Escape(('C:' + [char]92 + 'Users' + [char]92 + 'Len' + 'ovo'))
    'personal vault path' = [regex]::Escape(('F:' + [char]92 + 'Obsidian_' + 'notebook'))
    'private project identifier' = [regex]::Escape(('state' + 'grip'))
    'GitHub classic token' = 'ghp_[A-Za-z0-9]{20,}'
    'OpenAI-style secret key' = 'sk-[A-Za-z0-9_-]{20,}'
    'private key block' = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
    'non-placeholder secret assignment' = '(?im)^\s*(?:api[_-]?key|token|password|secret)\s*[:=]\s*["''][^<\r\n][^"''\r\n]{7,}["'']\s*$'
}

$privacyErrors = [System.Collections.Generic.List[string]]::new()
foreach ($relativePath in $gitCandidates) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $extension = [IO.Path]::GetExtension($relativePath).ToLowerInvariant()
    if ($relativePath -eq '.gitignore') {
        $extension = '.gitignore'
    }
    elseif ($relativePath -eq 'LICENSE') {
        $extension = '.txt'
    }
    if ($extension -notin $textExtensions) {
        continue
    }

    $content = Get-Content -LiteralPath $fullPath -Raw
    foreach ($entry in $forbiddenPatterns.GetEnumerator()) {
        if ($content -match $entry.Value) {
            $privacyErrors.Add("$relativePath：$($entry.Key)")
        }
    }
}
if ($privacyErrors.Count -gt 0) {
    $failures.AddRange($privacyErrors)
}
Write-CheckResult -Name 'PRIVACY_SCAN' -Passed ($privacyErrors.Count -eq 0) -Detail ($privacyErrors -join '; ')

$fenceErrors = [System.Collections.Generic.List[string]]::new()
foreach ($relativePath in $gitCandidates | Where-Object { $_ -like '*.md' }) {
    $fullPath = Join-Path $repoRoot $relativePath
    $fenceCount = ([regex]::Matches((Get-Content -LiteralPath $fullPath -Raw), '(?m)^```')).Count
    if (($fenceCount % 2) -ne 0) {
        $fenceErrors.Add("$relativePath：代码围栏数量为奇数 ($fenceCount)")
    }
}
if ($fenceErrors.Count -gt 0) {
    $failures.AddRange($fenceErrors)
}
Write-CheckResult -Name 'MARKDOWN_FENCES' -Passed ($fenceErrors.Count -eq 0) -Detail ($fenceErrors -join '; ')

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'FRAMEWORK_TEST=FAIL'
    foreach ($failure in $failures) {
        Write-Host "- $failure"
    }
    exit 1
}

Write-Host 'FRAMEWORK_TEST=PASS'
