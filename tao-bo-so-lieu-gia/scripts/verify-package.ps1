[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Project root not found: $root"
}
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $root '00_project_control\MANIFEST_SHAREABLE.tsv'
}
$manifest = [IO.Path]::GetFullPath($ManifestPath)
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$manifestPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$expectedTop = @(
    '00_project_control', '01_gate1_source', '02_gate2_metadata',
    '03_gate3_synthetic', '04_handoff', '90_archive'
)
$actualTop = Get-ChildItem -LiteralPath $root -Directory | Select-Object -ExpandProperty Name
foreach ($name in $expectedTop) {
    if ($name -notin $actualTop) { $errors.Add("MISSING_TOP_LEVEL:$name") }
}
foreach ($name in $actualTop) {
    if ($name -notin $expectedTop) { $warnings.Add("EXTRA_TOP_LEVEL:$name") }
}

$forbiddenManifestPrefixes = @(
    '01_gate1_source\',
    '02_gate2_metadata\runs_pending\',
    '03_gate3_synthetic\data_pending\',
    '90_archive\'
)
if (-not (Test-Path -LiteralPath $manifest)) {
    $errors.Add("MISSING_MANIFEST:$manifest")
} else {
    $rows = Import-Csv -Delimiter "`t" -LiteralPath $manifest
    foreach ($row in $rows) {
        [void]$manifestPaths.Add($row.path)
        foreach ($prefix in $forbiddenManifestPrefixes) {
            if ($row.path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                $errors.Add("FORBIDDEN_MANIFEST_PATH:$($row.path)")
            }
        }
        $full = Join-Path $root $row.path
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            $errors.Add("MISSING_FILE:$($row.path)")
            continue
        }
        $item = Get-Item -LiteralPath $full
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToLowerInvariant()
        if ($item.Length -ne [int64]$row.size_bytes) { $errors.Add("SIZE_MISMATCH:$($row.path)") }
        if ($hash -ne $row.sha256) { $errors.Add("HASH_MISMATCH:$($row.path)") }
    }
    Write-Output "MANIFEST_ENTRIES_CHECKED=$($rows.Count)"
}

$validationPath = Join-Path $root '03_gate3_synthetic\validation\validation_report.txt'
$privacyPath = Join-Path $root '03_gate3_synthetic\validation\privacy_classification.txt'
if (-not (Test-Path -LiteralPath $validationPath)) {
    $errors.Add('MISSING_VALIDATION_REPORT')
} elseif ((Get-Content -Raw -LiteralPath $validationPath) -notmatch '(?mi)^OVERALL\s*=\s*PASS\s*$') {
    $errors.Add('VALIDATION_NOT_PASS')
}
if (-not (Test-Path -LiteralPath $privacyPath)) {
    $errors.Add('MISSING_PRIVACY_CLASSIFICATION')
} else {
    $privacy = Get-Content -Raw -LiteralPath $privacyPath
    if ($privacy -notmatch '(?mi)^CLASSIFICATION\s*=\s*SYNTHETIC_SAFE\s*$') {
        $errors.Add('SYNTHETIC_NOT_SAFE')
    }
    if ($privacy -notmatch '(?mi)^DECISION\s*=\s*ALLOW\s*$') {
        $errors.Add('SYNTHETIC_NOT_ALLOWED')
    }
}

$dataExtensions = @('.sav', '.dta', '.rds', '.rdata')
Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Extension.ToLowerInvariant() -in $dataExtensions
} | ForEach-Object {
    $relative = $_.FullName.Substring($root.Length + 1)
    $packagePrefix = '04_handoff\package\'
    $packageRelative = if ($relative.StartsWith($packagePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $relative.Substring($packagePrefix.Length)
    } else {
        $null
    }
    $allowed = $relative -like '03_gate3_synthetic\data_pending\*' -or
        $relative -like '03_gate3_synthetic\data_safe\*' -or
        ($null -ne $packageRelative -and $packageRelative -like '03_gate3_synthetic\data_safe\*' -and $manifestPaths.Contains($packageRelative))
    if (-not $allowed) {
        $errors.Add("DATA_FILE_OUTSIDE_SYNTHETIC_AREA:$relative")
    }
}

foreach ($pending in @(
    '02_gate2_metadata\runs_pending',
    '03_gate3_synthetic\data_pending'
)) {
    $pendingPath = Join-Path $root $pending
    if ((Test-Path -LiteralPath $pendingPath) -and
        (Get-ChildItem -LiteralPath $pendingPath -Recurse -File | Select-Object -First 1)) {
        $warnings.Add("PENDING_CONTENT_NOT_IN_SHAREABLE_PACKAGE:$pending")
    }
}

$legacyPatterns = @(
    '\\metadata_output(\\|$)',
    '\\synthetic_output(\\|$)',
    '\\01_metadata(\\|$)',
    '\\02_synthetic(\\|$)'
)
$textFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.sps,*.do,*.R,*.py,*.md,*.yaml
foreach ($file in $textFiles) {
    if ($file.FullName -like '*\90_archive\*') { continue }
    $text = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($pattern in $legacyPatterns) {
        if ($text -match $pattern) {
            $errors.Add("STALE_PATH:$($file.FullName.Substring($root.Length + 1))")
            break
        }
    }
}

$spssFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.sps'
foreach ($file in $spssFiles) {
    if ($file.FullName -like '*\90_archive\*') { continue }
    $text = Get-Content -Raw -LiteralPath $file.FullName
    if ($text -match '(?i)\bWINDOW\s*=\s*HIDDEN\b') {
        $errors.Add("SPSS_INCOMPATIBLE_WINDOW_HIDDEN:$($file.FullName.Substring($root.Length + 1))")
    }
}

foreach ($warning in $warnings) { Write-Warning $warning }
foreach ($errorItem in $errors) { Write-Error $errorItem }

if ($errors.Count -gt 0) {
    Write-Output 'PACKAGE_STATUS=BLOCKED'
    exit 1
}

Write-Output 'PACKAGE_STATUS=PASS'
Write-Output "WARNING_COUNT=$($warnings.Count)"
