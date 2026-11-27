# skill-audit.ps1 -- mechanical audit of the SpecEverything skill library.
#
# What it checks (all reproducible, third-party verifiable):
#   1. Every "skill-name SS N" / bare "SS N" section reference resolves to a real numbered heading.
#   2. Every "assets/xxx.md" template reference exists on disk next to the referencing file.
#   3. Singular "spec/" path mentions (the workspace dir is "specs/").
#   4. Per-SKILL.md size: chars / CJK / printable-ascii + rough token estimate (budget gate).
#      Estimate formula: tokens ~= CJK + ascii/4 (upper bound; used for RELATIVE budget control only).
#   5. Every mudules/*-usage skill ships a references/*directory-tree*.md.
#   6. tools/**/*.ps1 containing CJK must carry a UTF-8 BOM (PS 5.1 else parses as ANSI; specs/错题本.md entry 2).
#   7. specs/features/index.md statuses must be from the enum owned by spec-standards 第3节 (transition-owner
#      map kept machine-readable inside check 8 below).
#   8. Every commit reachable from HEAD carries a Conventional Commits subject per dev-standards 第7节.
#
# Usage:   powershell -NoProfile -ExecutionPolicy Bypass -File tools\skill-audit.ps1 [-ScanRoot <path>]
# Output:  tools/skill-audit-report.md -- regenerated on every run; commit the snapshot as evidence.
#          The report contains NO timestamp/volatile field (BUG-001): its content is a pure function of
#          the library, so regenerating on an unchanged tree leaves git clean and any baseline gate
#          (e.g. skill-mutate.ps1) stays satisfiable. Evidence time lives in the committing git history.
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

# 7. CJK script encoding gate: tools/**/*.ps1 containing CJK must start with a UTF-8 BOM -- PS 5.1
#    parses BOM-less files as ANSI and CJK literals silently degrade (specs/错题本.md entry 2).
$bomRows = New-Object System.Collections.Generic.List[string]
$bomMissing = 0
$toolsDir = Join-Path $root 'tools'
if (Test-Path -LiteralPath $toolsDir) {
    foreach ($f in (Get-ChildItem -LiteralPath $toolsDir -Recurse -Filter '*.ps1')) {
        $bytes = [IO.File]::ReadAllBytes($f.FullName)
        $text  = [System.Text.Encoding]::UTF8.GetString($bytes)
        if ($text -match '[\u4e00-\u9fff]') {
            $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
            if (-not $hasBom) { $bomMissing++ }
            $rel = $f.FullName.Substring($root.Length + 1)
            $bomRows.Add("| $rel | $(if ($hasBom) {'OK'} else {'**MISSING UTF-8 BOM**'}) |")
        }
    }
}

# 8. feature index status gate. Transition-owner map, machine-readable copy of spec-standards 第3节
#    (prose stays the sole definition; this copy exists so the check is self-describing):
#      规划中 →[requirements-clarification 完成]→ 需求已确认 →[tech-design 完成]→ 设计已确认
#      →[implementation 首个任务动工]→ 开发中 →[code-review 通过]→ 已实现/待验收
#      →[blackbox-test 验收通过 + release-deploy 合并发布]→ 已完成
#      任意状态 +[bugfix-workflow 立案]→ 修复中；已取消 = 终态。
#    Liveness (dead/unreachable states) needs multi-feature history to be decidable; today the gate
#    mechanically validates enum membership per row, which is what caught the stale-status class.
$legalStates = @('规划中','需求已确认','设计已确认','开发中','已实现/待验收','已完成','修复中','已取消')
$idxRows = New-Object System.Collections.Generic.List[string]
$idxBad = 0
$idxPath = Join-Path $root 'specs\features\index.md'
if (Test-Path -LiteralPath $idxPath) {
    foreach ($line in [IO.File]::ReadAllLines($idxPath, $utf8)) {
        if ($line -notmatch '^\|' -or $line -match '^\|[-\s]*-') { continue }
        $cells = @($line -split '\|' | ForEach-Object { $_.Trim() })
        if ($cells.Count -lt 5 -or $cells[1] -eq '编号') { continue }
        $base = ($cells[4] -split '（')[0].Trim()
        $ok = $legalStates -contains $base
        if (-not $ok) { $idxBad++ }
        $idxRows.Add("| $($cells[1])（$($cells[2])） $base | $(if ($ok) {'OK'} else {'**UNKNOWN STATUS**'}) |")
    }
}

# 9. commit message convention gate (post-hoc): every commit reachable from HEAD must carry a
#    Conventional Commits subject per dev-standards 第7节 -- types feat/fix/refactor/style/docs/test/
#    chore/perf/ci, scope optional, subject non-empty. Matching runs on git's side (--invert-grep)
#    so console codepages cannot corrupt the verdict; report rows stay ASCII (hashes only).
$cmRows  = New-Object System.Collections.Generic.List[string]
$cmBad   = 0
$cmTotal = 0
if (Test-Path -LiteralPath (Join-Path $root '.git')) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $tot = git -C $root rev-list --count HEAD 2>$null
        if ($LASTEXITCODE -eq 0) { $cmTotal = [int]$tot }
        if ($cmTotal -gt 0) {
            $conv = '^(feat|fix|refactor|style|docs|test|chore|perf|ci)(\([^)]+\))?: .+'
            $badHashes = @(git -C $root log --format=%h --extended-regexp --invert-grep --grep=$conv 2>$null)
            if ($LASTEXITCODE -eq 0) {
                $cmBad = $badHashes.Count
                foreach ($h in $badHashes) { $cmRows.Add("| $h | **NON-CONVENTIONAL** |") }
            }
        }
    } finally { $ErrorActionPreference = $prevEap }
}

$clean = ($refBroken -eq 0 -and $assetMissing -eq 0 -and $specHits -eq 0 -and $mudMissing -eq 0 -and $dupHits -eq 0 -and $bomMissing -eq 0 -and $idxBad -eq 0 -and $cmBad -eq 0)

$L = New-Object System.Collections.Generic.List[string]
$L.Add('# Skill Library Mechanical Audit')
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
$L.Add('## 7. CJK script encoding (tools/**/*.ps1 with CJK must carry UTF-8 BOM)')
$L.Add('')
$L.Add("CJK BOM missing: $bomMissing")
$L.Add('')
$L.Add('| script | status |')
$L.Add('|---|---|')
if ($bomRows.Count -eq 0) { $L.Add('| (no CJK scripts found) | |') } else { foreach ($r in $bomRows) { $L.Add($r) } }
$L.Add('')
$L.Add('## 8. feature index statuses (specs/features/index.md; enum per spec-standards 第3节)')
$L.Add('')
$L.Add("Index statuses unknown: $idxBad")
$L.Add('')
$L.Add('| feature | status | verdict |')
$L.Add('|---|---|---|')
if ($idxRows.Count -eq 0) { $L.Add('| (no index file) | | |') } else { foreach ($r in $idxRows) { $L.Add($r) } }
$L.Add('')
$L.Add('## 9. commit message convention (subjects reachable from HEAD per dev-standards 第7节; git-side match, ASCII rows)')
$L.Add('')
$L.Add("Commit subjects checked: $cmTotal (non-conventional: $cmBad)")
$L.Add('')
$L.Add('| commit | verdict |')
$L.Add('|---|---|')
if ($cmRows.Count -eq 0) { $L.Add('| (all conventional or not a git repo) | |') } else { foreach ($r in $cmRows) { $L.Add($r) } }
$L.Add('')

[IO.File]::WriteAllLines($outPath, $L, $utf8BOM)
Write-Output ("audit done: refs=$refTotal broken=$refBroken assetsMissing=$assetMissing specPaths=$specHits mudTreeMissing=$mudMissing dups=$dupHits bomMissing=$bomMissing idxBad=$idxBad cmBad=$cmBad report=$outPath")
if ($clean) { exit 0 } else { exit 1 }
