# mutation-engine.Tests.ps1 -- Pester 3.4 tests for skill-mutate.ps1 (F001 Task-03/04).
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $PSScriptRoot
$mutate = Join-Path $tools 'skill-mutate.ps1'
$normLine = '本行包含必须这一规范标记词，并且整行长度明显超过四十个字符上限，以便稳定命中双定义检测机制。'

. $mutate   # dot-source: functions only, main is guarded ($MyInvocation.InvocationName -eq '.')

function New-Sandbox([string]$Name) {
    $fx = Join-Path ([IO.Path]::GetTempPath()) "mutfix-$Name-$(Get-Random)"
    New-Item -ItemType Directory -Path (Join-Path $fx 'skills\alpha'), (Join-Path $fx 'skills\beta') -Force | Out-Null
    [IO.File]::WriteAllLines((Join-Path $fx 'skills\alpha\SKILL.md'), @('# alpha', '路径占位 specs/features/xxx 结束', $normLine))
    [IO.File]::WriteAllLines((Join-Path $fx 'skills\beta\SKILL.md'), @('# beta'))
    git -C $fx init | Out-Null
    git -C $fx -c user.name=t -c user.email=t@t add -A | Out-Null
    git -C $fx -c user.name=t -c user.email=t@t commit -m 'chore: init sandbox library' | Out-Null
    return $fx
}

function Write-CatalogJson([string]$Path, [object[]]$Cat) {
    $Cat | ConvertTo-Json -Depth 4 | ForEach-Object { [IO.File]::WriteAllText($Path, $_, (New-Object System.Text.UTF8Encoding($true))) }
}

# Toy catalogs live OUTSIDE the sandbox root: a catalog json inside it would dirty the baseline the
# harness is required to enforce (first run caught exactly that -- the gate worked, the fixture was wrong).
function New-ToyCatalogPath([string]$Name) {
    return (Join-Path $env:TEMP "toy-$Name-$(Get-Random).json")
}

function Invoke-MutateAt([string]$Root, [string]$CatalogJsonPath) {
    $out = powershell -NoProfile -ExecutionPolicy Bypass -File $mutate -ScanRoot $Root -CatalogPath $CatalogJsonPath
    return @{ Out = ($out -join "`n"); Exit = $LASTEXITCODE }
}

$toyPass = @(
    [pscustomobject]@{ Id='T1'; Type='spec-path'; File='skills\alpha\SKILL.md'; Find='specs/features/xxx'; Replace='spec/features/xxx'; Section=3; Tokens=@('skills\alpha\SKILL.md') }
    [pscustomobject]@{ Id='T2'; Type='dup-rule'; File='skills\beta\SKILL.md'; Append=$normLine; Section=6; Tokens=@('skills\alpha\SKILL.md','skills\beta\SKILL.md') }
)

Describe 'skill-mutate: apply / capture / restore full chain' {
    It 'full pass: all captured, library restored, rerun CLEAN' {
        $fx = New-Sandbox 'pass'
        $catPath = New-ToyCatalogPath 'pass'
        Write-CatalogJson $catPath $toyPass
        try {
            $r = Invoke-MutateAt $fx $catPath
            $r.Exit | Should Be 0
            $r.Out | Should Match 'captured 2 / planted 2'
            $r.Out | Should Match 'PASS'
            @(git -C $fx status --porcelain).Count | Should Be 0
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'uncaptured mutation fails the run with the summary gate' {
        $fx = New-Sandbox 'miss'
        $catPath = New-ToyCatalogPath 'miss'
        $toyMiss = @(
            [pscustomobject]@{ Id='T1'; Type='spec-path'; File='skills\alpha\SKILL.md'; Find='specs/features/xxx'; Replace='spec/features/xxx'; Section=3; Tokens=@('skills\alpha\SKILL.md') }
            [pscustomobject]@{ Id='T2'; Type='invisible'; File='skills\alpha\SKILL.md'; Find='# alpha'; Replace='# ALPHA'; Section=1; Tokens=@('never-matches-any-row') }
        )
        Write-CatalogJson $catPath $toyMiss
        try {
            $r = Invoke-MutateAt $fx $catPath
            $r.Exit | Should Be 1
            $r.Out | Should Match 'captured 1 / planted 2'
            $r.Out | Should Match 'UNCAPTURED: T2'
            @(git -C $fx status --porcelain).Count | Should Be 0
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'mid-apply crash restores applied mutations and exits non-zero (AC-004)' {
        $fx = New-Sandbox 'crash'
        $catPath = New-ToyCatalogPath 'crash'
        $toyCrash = @(
            [pscustomobject]@{ Id='T1'; Type='spec-path'; File='skills\alpha\SKILL.md'; Find='specs/features/xxx'; Replace='spec/features/xxx'; Section=3; Tokens=@('skills\alpha\SKILL.md') }
            [pscustomobject]@{ Id='T2'; Type='broken'; File='skills\nope\SKILL.md'; Find='x'; Replace='y'; Section=1; Tokens=@('x') }
        )
        Write-CatalogJson $catPath $toyCrash
        try {
            $r = Invoke-MutateAt $fx $catPath
            $r.Exit | Should Be 1
            $r.Out | Should Match 'MUTATION RUN ABORTED'
            @(git -C $fx status --porcelain).Count | Should Be 0
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'dirty baseline is refused without touching the library' {
        $fx = New-Sandbox 'dirty'
        Add-Content -LiteralPath (Join-Path $fx 'skills\alpha\SKILL.md') -Value '未提交的脏行'
        $catPath = New-ToyCatalogPath 'dirty'
        Write-CatalogJson $catPath $toyPass
        try {
            $r = Invoke-MutateAt $fx $catPath
            $r.Exit | Should Be 1
            $r.Out | Should Match 'BASELINE BLOCKED'
            $text = [IO.File]::ReadAllText((Join-Path $fx 'skills\alpha\SKILL.md'))
            $text | Should Not Match 'spec/features/xxx'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'restore failure on an untracked path lands in the unrestored list (AC-004)' {
        $fx = New-Sandbox 'unrestore'
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'skills\gamma') -Force | Out-Null
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\gamma\SKILL.md'), @('# gamma untracked'))
            $failed = Invoke-RestoreFiles $fx @('skills\gamma\SKILL.md')
            @($failed).Count | Should Be 1
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'built-in catalog: valid against the real library, four types, >=10 items' {
        $cat = $BuiltInCatalog
        @($cat).Count | Should BeGreaterThan 9
        foreach ($g in @('broken-ref','asset-missing','spec-path','dup-rule')) {
            @($cat | Where-Object { $_.Type -eq $g }).Count | Should BeGreaterThan 1
        }
        $realRoot = Split-Path -Parent $tools
        foreach ($m in $cat) {
            $p = Join-Path $realRoot $m.File
            Test-Path -LiteralPath $p | Should Be $true
            $text = [IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
            if ($m.Append) {
                $text.Contains($m.Append) | Should Be $false
                $srcPath = @($m.Tokens | Where-Object { $_ -ne $m.File })[0]
                $srcText = [IO.File]::ReadAllText((Join-Path $realRoot $srcPath), [System.Text.Encoding]::UTF8)
                $srcText.Contains($m.Append) | Should Be $true
            } else {
                $text.Contains($m.Find) | Should Be $true
            }
        }
    }
}
