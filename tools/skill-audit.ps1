# skill-audit.ps1 -- mechanical audit of the SpecEverything skill library.
#
# What it checks (all reproducible, third-party verifiable):
#   1. Every "skill-name SS N" / bare "SS N" section reference resolves to a real numbered heading.
#   2. Every "assets/xxx.md" template reference exists on disk next to the referencing file.
#   3. Singular "spec/" path mentions (the workspace dir is "specs/").
#   4. Per-SKILL.md size: chars / CJK / printable-ascii + rough token estimate (budget gate).
#      Estimate formula: tokens ~= CJK + ascii/4 (upper bound; used for RELATIVE budget control only).
#   5. Every mudules/*-usage skill ships a references/*directory-tree*.md.
#
# Usage:   powershell -NoProfile -ExecutionPolicy Bypass -File tools\skill-audit.ps1 [-ScanRoot <path>]
# Output:  tools/skill-audit-report.md (regenerated on every run; commit the snapshot as evidence)
# Exit:    0 = clean, 1 = findings.
#
# -ScanRoot is the test seam (default: repo root = parent of tools/); zero-arg behavior is the contract
# guarded by tests/golden-normal-report.txt (F001 AC-005).
#
# NOTE (F001): since the duplicate-definition check this file now contains CJK literals (marker words +
# comments). It MUST stay saved as UTF-8 **with BOM** -- without BOM, PS 5.1 reads it as ANSI and the
# marker regex silently degrades to garbage (misses every hit).

param([string]$ScanRoot = '')

$ErrorActionPreference = 'Stop'
$root    = if ($ScanRoot) { (Resolve-Path -LiteralPath $ScanRoot).Path } else { Split-Path -Parent $PSScriptRoot }
$outPath = Join-Path $PSScriptRoot 'skill-audit-report.md'
$utf8BOM = New-Object System.Text.UTF8Encoding($true)
$utf8    = [System.Text.Encoding]::UTF8
$SS       = [char]0x00A7   # section sign; built via codepoint so this ASCII-only script survives ANSI misreads
$secRef   = "$SS" + '\s?(\d+(?:\.\d+)?)'

# All markdown files except .git, tools (this script's own output) -- README/specs/skills/mudules are the graph.
$mdFiles = Get-ChildItem -Path $root -Recurse -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '\\(\.git|tools)\\' }

# Skill dir map: directory name -> SKILL.md path (covers skills/ and mudules/).
$skillMap = @{}
foreach ($f in ($mdFiles | Where-Object { $_.Name -eq 'SKILL.md' })) { $skillMap[$f.Directory.Name] = $f.FullName }

function Resolve-Skill([string]$name) {
    if ($skillMap.ContainsKey($name)) { return $skillMap[$name] }
    $full = 'speceverything-' + $name   # tolerate short forms like "spec-standards"
    if ($skillMap.ContainsKey($full)) { return $skillMap[$full] }
    return $null
}

# Section map: file -> set of numbered heading ids ("2", "2.1", "13", ...).
$sections = @{}
foreach ($f in $mdFiles) {
    $set = @{}
    foreach ($line in [IO.File]::ReadAllLines($f.FullName, $utf8)) {
        if ($line -match '^#{1,6}\s*(\d+(?:\.\d+)*)[.\s]') { $set[$Matches[1]] = $true }
    }
    $sections[$f.FullName] = $set
}

$refRows    = New-Object System.Collections.Generic.List[string]
$assetRows  = New-Object System.Collections.Generic.List[string]
$specRows   = New-Object System.Collections.Generic.List[string]
$refTotal   = 0; $refBroken = 0; $assetMissing = 0; $specHits = 0

foreach ($f in $mdFiles) {
    $rel = $f.FullName.Substring($root.Length + 1)
    $raw = [IO.File]::ReadAllLines($f.FullName, $utf8)
    for ($i = 0; $i -lt $raw.Length; $i++) {
        $line = $raw[$i]; $ln = $i + 1

        # resolvable skill-name tokens on this line, with positions
        $nameHits = @()
        foreach ($m in [regex]::Matches($line, '[A-Za-z][A-Za-z0-9-]{2,}')) {
            $t = Resolve-Skill $m.Value
            if ($t) { $nameHits += [pscustomobject]@{ Pos = $m.Index; Target = $t } }
        }

        # section refs: target = last skill name appearing before the ref; none = self
        foreach ($m in [regex]::Matches($line, $secRef)) {
            $refTotal++
            $pre = $line.Substring(0, $m.Index)
            $target = $f.FullName
            foreach ($n in $nameHits) { if ($n.Pos -lt $m.Index) { $target = $n.Target } }
            if ($target -eq $f.FullName -and $pre -match '\.md') {
                # no skill name precedes the ref and the line mentions a doc file:
                # ref points at a runtime document (e.g. 开发规范.md SS 3, 过程复盘.md SS 2.4), not a skill section
                $refRows.Add("| ${rel}:${ln} | (runtime doc) | $($m.Groups[1].Value) | RUNTIME-DOC |")
                continue
            }
            $num = $m.Groups[1].Value
            $ok  = $sections[$target].ContainsKey($num)
            if (-not $ok) { $refBroken++ }
            $trel = $target.Substring($root.Length + 1)
            $refRows.Add(("| {0}:{1} | {2} | {3} | {4} |" -f $rel, $ln, $trel, $num, $(if ($ok) {'OK'} else {'**BROKEN**'})))
        }

        # asset template refs (CJK filenames allowed by \w)
        foreach ($m in [regex]::Matches($line, 'assets/[\w\-]+\.md')) {
            $p  = Join-Path $f.DirectoryName ($m.Value -replace '/', '\')
            $ok = Test-Path -LiteralPath $p
            if (-not $ok) { $assetMissing++ }
            $assetRows.Add("| ${rel}:${ln} | $($m.Value) | $(if ($ok) {'OK'} else {'**MISSING**'}) |")
        }

        # singular "spec/" (lookbehind so "specs/" is not matched)
        foreach ($m in [regex]::Matches($line, '(?<![A-Za-z])spec/')) {
            $specHits++
            $snip = $line.Trim()
            if ($snip.Length -gt 90) { $snip = $snip.Substring(0, 90) + '...' }
            $specRows.Add("| ${rel}:${ln} | $snip |")
        }
    }
}

# size / budget table for every SKILL.md
$sizeRows = @()
foreach ($f in ($mdFiles | Where-Object { $_.Name -eq 'SKILL.md' })) {
    $text  = [IO.File]::ReadAllText($f.FullName, $utf8)
    $cjk   = [regex]::Matches($text, '[\u4e00-\u9fff]').Count
    $ascii = [regex]::Matches($text, '[\x21-\x7e]').Count
    $est   = [int][math]::Ceiling($cjk + $ascii / 4.0)
    $sizeRows += [pscustomobject]@{ Skill = $f.Directory.Name; Chars = $text.Length; CJK = $cjk; Ascii = $ascii; Tok = $est }
}
$sizeRows  = $sizeRows | Sort-Object Tok -Descending
$totTok    = ($sizeRows | Measure-Object Tok -Sum).Sum
$totChars  = ($sizeRows | Measure-Object Chars -Sum).Sum
$totCjk    = ($sizeRows | Measure-Object CJK -Sum).Sum

# mudules directory-tree requirement
$mudRows = New-Object System.Collections.Generic.List[string]
$mudMissing = 0
foreach ($k in @($skillMap.Keys)) {
    if ($k -notlike '*-usage') { continue }
    $refDir = Join-Path (Split-Path -Parent $skillMap[$k]) 'references'
    $tree = @()
    if (Test-Path -LiteralPath $refDir) { $tree = Get-ChildItem -LiteralPath $refDir -Filter '*directory-tree*.md' }
    if ($tree.Count -eq 0) { $mudMissing++ }
    $mudRows.Add("| $k | $(if ($tree.Count -gt 0) {'OK'} else {'**MISSING directory-tree**'}) |")
}

# 6. duplicate definition check (F001): >=40-char NORMATIVE line (必须/禁止/不得/严禁/一律/唯一定义处)
#    present in >=2 distinct files under skills/ + mudules/.
#    Marker filter: first live run without it flagged 22 structural boilerplate repeats (SQL examples,
#    stage declarations, context pointers) as false positives; rules drift lives in marker-bearing sentences
#    (known real case: the mistake-ledger entry double definition, collapsed 2026-11-27, contains 必须).
$dupRows = New-Object System.Collections.Generic.List[string]
$dupHits = 0
$lineMap = @{}
foreach ($dir in @('skills', 'mudules')) {
    $p = Join-Path $root $dir
    if (-not (Test-Path -LiteralPath $p)) { continue }
    foreach ($f in (Get-ChildItem -LiteralPath $p -Recurse -Filter '*.md')) {
        $ln = 0
        foreach ($line in [IO.File]::ReadAllLines($f.FullName, $utf8)) {
            $ln++
            $t = $line.Trim()
            if ($t.Length -lt 40) { continue }
            if ($t -notmatch '必须|禁止|不得|严禁|一律|唯一定义处') { continue }
            if (-not $lineMap.ContainsKey($t)) { $lineMap[$t] = New-Object System.Collections.Generic.List[string] }
            $rel = $f.FullName.Substring($root.Length + 1)
            $lineMap[$t].Add("$rel`:$ln")
        }
    }
}
foreach ($k in @($lineMap.Keys)) {
    $locs = $lineMap[$k]
    $files = @($locs | ForEach-Object { ($_ -split ':')[0] } | Select-Object -Unique)
    if ($files.Count -ge 2) {
        $dupHits++
        $snippet = $k; if ($snippet.Length -gt 60) { $snippet = $snippet.Substring(0, 60) + '...' }
        $dupRows.Add("| $($locs[0]) | $($locs[1]) | $snippet |")
    }
}

$clean = ($refBroken -eq 0 -and $assetMissing -eq 0 -and $specHits -eq 0 -and $mudMissing -eq 0 -and $dupHits -eq 0)

$L = New-Object System.Collections.Generic.List[string]
$L.Add('# Skill Library Mechanical Audit')
$L.Add('')
$L.Add("_generated by ``tools/skill-audit.ps1`` on $(Get-Date -Format 'yyyy-MM-dd HH:mm')_")
$L.Add('')
$L.Add("Verdict: **$(if ($clean) {'CLEAN'} else {'FINDINGS'})** -- refs checked: $refTotal (broken: $refBroken), assets missing: $assetMissing, singular spec/ paths: $specHits, mudules missing tree: $mudMissing")
$L.Add('')
$L.Add('## 1. Section reference check (skill name + SS number -> target heading exists)')
$L.Add('')
$L.Add('| source file:line | target | ref | status |')
$L.Add('|---|---|---|---|')
foreach ($r in $refRows) { $L.Add($r) }
$L.Add('')
$L.Add('## 2. assets/ template existence')
$L.Add('')
$L.Add('| source file:line | referenced asset | status |')
$L.Add('|---|---|---|')
if ($assetRows.Count -eq 0) { $L.Add('| (none referenced) | | |') } else { foreach ($r in $assetRows) { $L.Add($r) } }
$L.Add('')
$L.Add('## 3. Singular "spec/" paths (workspace dir is "specs/")')
$L.Add('')
$L.Add('| source file:line | line excerpt |')
$L.Add('|---|---|')
if ($specRows.Count -eq 0) { $L.Add('| (none) | |') } else { foreach ($r in $specRows) { $L.Add($r) } }
$L.Add('')
$L.Add('## 4. Size / token budget (per SKILL.md; estimate = CJK + ascii/4)')
$L.Add('')
$L.Add('| skill | chars | cjk | ascii | ~tokens |')
$L.Add('|---|---|---|---|---|')
foreach ($s in $sizeRows) { $L.Add("| $($s.Skill) | $($s.Chars) | $($s.CJK) | $($s.Ascii) | $($s.Tok) |") }
$L.Add("| **TOTAL ($($sizeRows.Count) SKILL.md)** | **$totChars** | **$totCjk** | | **$totTok** |")
$L.Add('')
$L.Add('## 5. mudules/*-usage directory-tree requirement')
$L.Add('')
$L.Add('| module | status |')
$L.Add('|---|---|')
foreach ($r in $mudRows) { $L.Add($r) }
$L.Add('')
$L.Add('## 6. duplicate definition check (>=40-char normative line, marker words present, in >=2 distinct files; skills/ + mudules/ only)')
$L.Add('')
$L.Add("Duplicate definitions: $dupHits")
$L.Add('')
$L.Add('| first | other | line (<=60 chars) |')
$L.Add('|---|---|---|')
if ($dupRows.Count -eq 0) { $L.Add('| (none) | | |') } else { foreach ($r in $dupRows) { $L.Add($r) } }
$L.Add('')

[IO.File]::WriteAllLines($outPath, $L, $utf8BOM)
Write-Output ("audit done: refs=$refTotal broken=$refBroken assetsMissing=$assetMissing specPaths=$specHits mudTreeMissing=$mudMissing dups=$dupHits report=$outPath")
if ($clean) { exit 0 } else { exit 1 }
