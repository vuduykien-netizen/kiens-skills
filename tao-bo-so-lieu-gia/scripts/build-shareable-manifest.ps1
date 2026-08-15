[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Project root not found: $root"
}
$rootPrefix = $root + '\'

if (-not $OutputPath) {
    $OutputPath = Join-Path $root '00_project_control\MANIFEST_SHAREABLE.tsv'
}
$output = [IO.Path]::GetFullPath($OutputPath)
if (-not $output.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Manifest output must stay inside project root: $output"
}

$privacyPath = Join-Path $root '03_gate3_synthetic\validation\privacy_classification.txt'
if (-not (Test-Path -LiteralPath $privacyPath)) {
    throw "Missing privacy classification: $privacyPath"
}
$privacy = Get-Content -Raw -LiteralPath $privacyPath
if ($privacy -notmatch '(?mi)^CLASSIFICATION\s*=\s*SYNTHETIC_SAFE\s*$' -or
    $privacy -notmatch '(?mi)^DECISION\s*=\s*ALLOW\s*$') {
    throw 'Synthetic data is not SYNTHETIC_SAFE / ALLOW.'
}

$reviewedRoot = Join-Path $root '02_gate2_metadata\reviewed'
if (Test-Path -LiteralPath $reviewedRoot) {
    Get-ChildItem -LiteralPath $reviewedRoot -Directory | ForEach-Object {
        $review = Get-ChildItem -LiteralPath $_.FullName -File -Filter 'privacy_review*' |
            Select-Object -First 1
        if (-not $review) {
            throw "Reviewed metadata has no privacy review: $($_.FullName)"
        }
        $text = Get-Content -Raw -LiteralPath $review.FullName
        if ($text -notmatch 'SAFE_METADATA' -or $text -notmatch '(?i)ALLOW') {
            throw "Reviewed metadata is not SAFE_METADATA / ALLOW: $($_.FullName)"
        }
    }
}

$includeRoots = @(
    '00_project_control',
    '02_gate2_metadata\scripts',
    '02_gate2_metadata\reviewed',
    '02_gate2_metadata\guides',
    '03_gate3_synthetic\specification',
    '03_gate3_synthetic\scripts',
    '03_gate3_synthetic\data_safe',
    '03_gate3_synthetic\validation',
    '03_gate3_synthetic\guides',
    '04_handoff\audit'
)

function Get-Classification([string]$relative) {
    if ($relative -like '02_gate2_metadata\reviewed\*') { return @('SAFE_METADATA', 'ALLOW') }
    if ($relative -like '03_gate3_synthetic\data_safe\*') { return @('SYNTHETIC_SAFE', 'ALLOW') }
    if ($relative -like '03_gate3_synthetic\validation\*') { return @('VALIDATION', 'PASS') }
    if ($relative -match '\\scripts\\') { return @('SCRIPT', 'CURRENT') }
    if ($relative -like '03_gate3_synthetic\specification\*') { return @('SPECIFICATION', 'CURRENT') }
    if ($relative -like '04_handoff\audit\*') { return @('AUDIT', 'CURRENT') }
    return @('DOCUMENTATION', 'CURRENT')
}

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($relativeRoot in $includeRoots) {
    $fullRoot = Join-Path $root $relativeRoot
    if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) { continue }
    Get-ChildItem -LiteralPath $fullRoot -Recurse -File | ForEach-Object {
        $relative = $_.FullName.Substring($root.Length + 1)
        if ($relative -in @(
            '00_project_control\MANIFEST_SHAREABLE.tsv',
            '00_project_control\MANIFEST_LOCAL_ONLY.tsv'
        )) { return }
        $classStatus = Get-Classification $relative
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
        $rows.Add([pscustomobject]@{
            path = $relative
            size_bytes = $_.Length
            sha256 = $hash
            classification = $classStatus[0]
            status = $classStatus[1]
        })
    }
}

$parent = Split-Path -Parent $output
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("path`tsize_bytes`tsha256`tclassification`tstatus")
foreach ($row in ($rows | Sort-Object path)) {
    $lines.Add("$($row.path)`t$($row.size_bytes)`t$($row.sha256)`t$($row.classification)`t$($row.status)")
}
Set-Content -LiteralPath $output -Value $lines -Encoding utf8

Write-Output "MANIFEST_PATH=$output"
Write-Output "MANIFEST_ENTRIES=$($rows.Count)"

