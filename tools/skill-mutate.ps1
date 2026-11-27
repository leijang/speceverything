# skill-mutate.ps1 -- mutation gate for the SpecEverything skill library (F001, Task-03/04).
# One zero-arg command proves the audit gates catch a fixed catalog of planted defects:
#   baseline gate -> apply built-in mutations -> run skill-audit.ps1 -> parse report per mutation
#   -> git-restore everything -> rerun audit must be CLEAN -> "captured X / planted N" verdict.
# Exit codes: 0 = all captured + library restored byte-clean + rerun CLEAN; 1 = anything else, with reasons.
# Test seam (design D6, specs/features/F001-审计变异测试-20261127/技术方案.md):
#   -ScanRoot <path>    library root to mutate (default: parent of tools/)
#   -CatalogPath <file> JSON catalog (default: built-in $BuiltInCatalog below)
# NOTE: contains CJK -- MUST stay saved UTF-8 **with BOM** (PS 5.1 otherwise parses it as ANSI).

param(
    [string]$ScanRoot    = '',
    [string]$CatalogPath = ''
)

$ErrorActionPreference = 'Stop'
$script:mutateExitCode = 0
$script:utf8    = [System.Text.Encoding]::UTF8

# Fixed catalog: reproducible implants only against committed, real files (AC-001 Given).
# Types map to audit report sections: 1 = section refs, 2 = assets, 3 = singular spec/, 6 = dup rules.
$script:BuiltInCatalog = @(
    [pscustomobject]@{ Id='M01'; Type='broken-ref';  File='skills\feature\speceverything-feature-implementation\SKILL.md'; Find='speceverything-bugfix-workflow §2.1'; Replace='speceverything-bugfix-workflow §9.9'; Section=1; Tokens=@('skills\feature\speceverything-feature-implementation\SKILL.md','BROKEN') }
    [pscustomobject]@{ Id='M02'; Type='broken-ref';  File='README.md'; Find='speceverything-feature-release-deploy §2.1'; Replace='speceverything-feature-release-deploy §9.9'; Section=1; Tokens=@('README.md','BROKEN') }
    [pscustomobject]@{ Id='M03'; Type='broken-ref';  File='skills\feature\speceverything-feature-release-deploy\SKILL.md'; Find='speceverything-spec-standards §4.1'; Replace='speceverything-spec-standards §4.9'; Section=1; Tokens=@('skills\feature\speceverything-feature-release-deploy\SKILL.md','BROKEN') }
    [pscustomobject]@{ Id='M04'; Type='asset-missing'; File='skills\feature\speceverything-feature-implementation\SKILL.md'; Find='assets/stage-completion-report-template.md'; Replace='assets/stage-completion-report-missing.md'; Section=2; Tokens=@('skills\feature\speceverything-feature-implementation\SKILL.md','MISSING') }
    [pscustomobject]@{ Id='M05'; Type='asset-missing'; File='skills\feature\speceverything-feature-code-review\SKILL.md'; Find='assets/code-review-report-template.md'; Replace='assets/code-review-report-missing.md'; Section=2; Tokens=@('skills\feature\speceverything-feature-code-review\SKILL.md','MISSING') }
    [pscustomobject]@{ Id='M06'; Type='asset-missing'; File='skills\feature\speceverything-feature-tech-design\SKILL.md'; Find='assets/feature-tech-design-template.md'; Replace='assets/feature-tech-design-template-missing.md'; Section=2; Tokens=@('skills\feature\speceverything-feature-tech-design\SKILL.md','MISSING') }
    [pscustomobject]@{ Id='M07'; Type='spec-path'; File='skills\feature\speceverything-feature-requirements-clarification\SKILL.md'; Find='specs/features/XXX-功能名称-YYYYMMDD/需求说明.md'; Replace='spec/features/XXX-功能名称-YYYYMMDD/需求说明.md'; Section=3; Tokens=@('skills\feature\speceverything-feature-requirements-clarification\SKILL.md') }
    [pscustomobject]@{ Id='M08'; Type='spec-path'; File='skills\feature\speceverything-feature-implementation\SKILL.md'; Find='specs/features/XXX-功能名称-YYYYMMDD/'; Replace='spec/features/XXX-功能名称-YYYYMMDD/'; Section=3; Tokens=@('skills\feature\speceverything-feature-implementation\SKILL.md') }
    [pscustomobject]@{ Id='M09'; Type='spec-path'; File='skills\standard\speceverything-spec-standards\SKILL.md'; Find='`specs/features/XXX-功能名称-YYYYMMDD/`'; Replace='`spec/features/XXX-功能名称-YYYYMMDD/`'; Section=3; Tokens=@('skills\standard\speceverything-spec-standards\SKILL.md') }
    [pscustomobject]@{ Id='M10'; Type='dup-rule'; File='skills\speceverything-bugfix-workflow\SKILL.md'; Append='仓库尚无测试运行基础设施时，先确认任务规划的基础设施层包含测试框架搭建任务；无测试运行器不得声称执行 TDD。'; Section=6; Tokens=@('skills\feature\speceverything-feature-implementation\SKILL.md','skills\speceverything-bugfix-workflow\SKILL.md') }
    [pscustomobject]@{ Id='M11'; Type='dup-rule'; File='skills\feature\speceverything-feature-hifi-design\SKILL.md'; Append='禁止扁平命名（如 `specs/features/{功能名}_技术方案.md`）——同需求的所有文档必须聚在其规格目录内。'; Section=6; Tokens=@('skills\standard\speceverything-spec-standards\SKILL.md','skills\feature\speceverything-feature-hifi-design\SKILL.md') }
)

function Get-MutateCatalog([string]$Path) {
    if ($Path) {
        $raw = [IO.File]::ReadAllText($Path, $script:utf8)
        $parsed = ConvertFrom-Json $raw
        return @($parsed | ForEach-Object {
            [pscustomobject]@{ Id=$_.Id; Type=$_.Type; File=$_.File; Find=$_.Find; Replace=$_.Replace; Append=$_.Append; Section=[int]$_.Section; Tokens=@($_.Tokens) }
        })
    }
    return $script:BuiltInCatalog
}

function Test-MutateBaseline([string]$Root) {
    $problems = New-Object System.Collections.Generic.List[string]
    $dirty = @(git -C $Root status --porcelain)
    foreach ($d in $dirty) { $problems.Add("git dirty: $d") }
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'skill-audit.ps1') -ScanRoot $Root | Out-Null
    if ($LASTEXITCODE -ne 0) { $problems.Add("baseline audit not CLEAN (exit=$LASTEXITCODE)") }
    return $problems
}

function Invoke-ApplyOne([string]$Root, [object]$M, [System.Collections.Generic.List[object]]$Applied) {
    $p = Join-Path $Root $M.File
    if (-not (Test-Path -LiteralPath $p)) { throw "mutation $($M.Id): target file missing: $($M.File)" }
    $bytes  = [IO.File]::ReadAllBytes($p)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $text   = [IO.File]::ReadAllText($p, $script:utf8)
    if ($M.Append) {
        if ($text.Contains($M.Append)) { throw "mutation $($M.Id): append line already present in $($M.File)" }
        $new = $text.TrimEnd("`r","`n") + "`r`n" + $M.Append + "`r`n"
        [IO.File]::WriteAllText($p, $new, (New-Object System.Text.UTF8Encoding($hasBom)))
    } else {
        if (-not $text.Contains($M.Find)) { throw "mutation $($M.Id): find string not present in $($M.File)" }
        [IO.File]::WriteAllText($p, $text.Replace($M.Find, $M.Replace), (New-Object System.Text.UTF8Encoding($hasBom)))
    }
    $Applied.Add($M)
}

function Invoke-RestoreFiles([string]$Root, [string[]]$Files) {
    $failed = New-Object System.Collections.Generic.List[string]
    # PS 5.1: with EAP=Stop, a native command writing to stderr via 2>$null raises a terminating
    # NativeCommandError -- exactly the untracked-path case this function must REPORT, not throw on.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        foreach ($f in ($Files | Select-Object -Unique)) {
            git -C $Root checkout -- $f 2>$null
            if ($LASTEXITCODE -ne 0) { $failed.Add($f); continue }
            $st = @(git -C $Root status --porcelain -- $f)
            if ($st.Count -gt 0) { $failed.Add($f) }
        }
    } finally {
        $ErrorActionPreference = $prev
    }
    return $failed
}

function Read-CaptureResult([string]$ReportPath, [object[]]$Cat) {
    $rowsBySection = @{}
    $cur = ''
    foreach ($l in [IO.File]::ReadAllLines($ReportPath, $script:utf8)) {
        if ($l -match '^## (\d+)\.') { $cur = $Matches[1]; continue }
        if ($cur -and $l.StartsWith('|')) {
            if (-not $rowsBySection.ContainsKey($cur)) { $rowsBySection[$cur] = New-Object System.Collections.Generic.List[string] }
            $rowsBySection[$cur].Add($l)
        }
    }
    $uncaptured = New-Object System.Collections.Generic.List[object]
    foreach ($m in $Cat) {
        $key = [string]$m.Section
        $rows = if ($rowsBySection.ContainsKey($key)) { $rowsBySection[$key] } else { $null }
        $hit = $false
        if ($rows) {
            foreach ($r in $rows) {
                $ok = $true
                foreach ($t in @($m.Tokens)) { if (-not $r.Contains([string]$t)) { $ok = $false; break } }
                if ($ok) { $hit = $true; break }
            }
        }
        if (-not $hit) { $uncaptured.Add($m) }
    }
    return $uncaptured
}

function Invoke-MutationRun([string]$Root, [object[]]$Cat) {
    $audit  = Join-Path $PSScriptRoot 'skill-audit.ps1'
    $report = Join-Path $PSScriptRoot 'skill-audit-report.md'

    $problems = Test-MutateBaseline $Root
    if ($problems.Count -gt 0) {
        foreach ($p in $problems) { Write-Output "BASELINE BLOCKED: $p" }
        $script:mutateExitCode = 1
        return
    }

    $applied = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($m in $Cat) { Invoke-ApplyOne $Root $m $applied }
        powershell -NoProfile -ExecutionPolicy Bypass -File $audit -ScanRoot $Root | Out-Null
        $uncaptured = Read-CaptureResult $report $Cat
        $n = @($Cat).Count
        $x = $n - @($uncaptured).Count
        Write-Output "captured $x / planted $n"
        if (@($uncaptured).Count -gt 0) {
            $script:mutateExitCode = 1
            foreach ($u in $uncaptured) { Write-Output "UNCAPTURED: $($u.Id) expected section $($u.Section) in $($u.File)" }
        }
    } catch {
        Write-Output "MUTATION RUN ABORTED: $($_.Exception.Message)"
        $script:mutateExitCode = 1
    } finally {
        if ($applied.Count -gt 0) {
            $files  = @($applied | ForEach-Object { $_.File })
            $failed = Invoke-RestoreFiles $Root $files
            if (@($failed).Count -gt 0) {
                $script:mutateExitCode = 1
                foreach ($f in $failed) { Write-Output "UNRESTORED: $f" }
            }
            $dirty = @(git -C $Root status --porcelain)
            if ($dirty.Count -gt 0) {
                $script:mutateExitCode = 1
                foreach ($d in $dirty) { Write-Output "DIRTY AFTER RESTORE: $d" }
            }
        }
    }

    if ($applied.Count -gt 0 -and $script:mutateExitCode -eq 0) {
        powershell -NoProfile -ExecutionPolicy Bypass -File $audit -ScanRoot $Root | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $script:mutateExitCode = 1
            Write-Output "FAIL: rerun after restore is not CLEAN (exit=$LASTEXITCODE)"
        } else {
            Write-Output "PASS: captured all planted mutations, library restored, rerun CLEAN"
        }
    }
}

# dot-source guard: Pester dot-sources this file for the functions; real runs execute it via -File.
if ($MyInvocation.InvocationName -ne '.') {
    $runRoot = if ($ScanRoot) { (Resolve-Path -LiteralPath $ScanRoot).Path } else { Split-Path -Parent $PSScriptRoot }
    $runCat   = Get-MutateCatalog $CatalogPath
    Invoke-MutationRun $runRoot $runCat
    exit $script:mutateExitCode
}
