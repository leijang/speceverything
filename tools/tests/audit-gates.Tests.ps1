# audit-gates.Tests.ps1 -- Pester 3.4 tests for skill-audit section 7 (CJK BOM) and section 8 (index status).
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $tools 'skill-audit.ps1'

function Invoke-AuditAt([string]$ScanRoot) {
    if ($ScanRoot) { powershell -NoProfile -ExecutionPolicy Bypass -File $audit -ScanRoot $ScanRoot | Out-Null }
    else { powershell -NoProfile -ExecutionPolicy Bypass -File $audit | Out-Null }
    return (Join-Path $tools 'skill-audit-report.md')
}

Describe 'skill-audit section 7: CJK script encoding gate' {
    It 'flags a CJK-bearing ps1 without UTF-8 BOM in a sandbox' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "bomfix-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'tools') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $fx 'tools\nobom.ps1'), "# 含中文注释的脚本`nWrite-Output 'x'`n", (New-Object System.Text.UTF8Encoding($false)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'CJK BOM missing: 1'
            $text | Should Match 'nobom\.ps1'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'accepts a CJK-bearing ps1 that has the BOM' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "bomok-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'tools') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $fx 'tools\withbom.ps1'), "# 含中文注释的脚本`nWrite-Output 'x'`n", (New-Object System.Text.UTF8Encoding($true)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'CJK BOM missing: 0'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'real repo: zero CJK-without-BOM scripts' {
        $report = Invoke-AuditAt ''
        $text = [IO.File]::ReadAllText($report)
        $text | Should Match 'CJK BOM missing: 0'
    }
}

Describe 'skill-audit section 9: commit message convention gate' {
    It 'flags a non-conventional commit subject in a sandbox' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "cmfix-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'tools') -Force | Out-Null
            git -C $fx init | Out-Null
            [IO.File]::WriteAllText((Join-Path $fx 'tools\x.md'), 'x')
            git -C $fx -c user.name=t -c user.email=t@t add -A | Out-Null
            git -C $fx -c user.name=t -c user.email=t@t commit -m '更新了一些东西' | Out-Null
            [IO.File]::WriteAllText((Join-Path $fx 'tools\y.md'), 'y')
            git -C $fx -c user.name=t -c user.email=t@t add -A | Out-Null
            git -C $fx -c user.name=t -c user.email=t@t commit -m 'chore(tools): 正常提交' | Out-Null
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'non-conventional: 1'
            $text | Should Match '\| [0-9a-f]{7,40} \| \*\*NON-CONVENTIONAL\*\* \|'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'real repo: every reachable commit subject is conventional' {
        $report = Invoke-AuditAt ''
        $text = [IO.File]::ReadAllText($report)
        $text | Should Match 'Commit subjects checked: \d+ \(non-conventional: 0\)'
    }
}

Describe 'skill-audit section 8: feature index status gate' {
    It 'flags an unknown status in a sandbox index' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "idxfix-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'specs\features') -Force | Out-Null
            $idx = @('# 需求索引', '', '| 编号 | 名称 | 目录 | 状态 |', '|------|------|------|------|', '| F001 | 测试 | `F001-x` | 已交付 |')
            [IO.File]::WriteAllLines((Join-Path $fx 'specs\features\index.md'), $idx, (New-Object System.Text.UTF8Encoding($true)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Index statuses unknown: 1'
            $f001 = [regex]::Escape('F001')
            $text | Should Match $f001
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'accepts legal statuses incl. parenthesized annotations' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "idxok-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'specs\features') -Force | Out-Null
            $idx = @('# 需求索引', '', '| 编号 | 名称 | 目录 | 状态 |', '|------|------|------|------|', '| F001 | 测试 | `F001-x` | 已完成（含注记） |', '| F002 | 测试 | `F002-x` | 修复中 |')
            [IO.File]::WriteAllLines((Join-Path $fx 'specs\features\index.md'), $idx, (New-Object System.Text.UTF8Encoding($true)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Index statuses unknown: 0'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'real repo index: all statuses legal' {
        $report = Invoke-AuditAt ''
        $text = [IO.File]::ReadAllText($report)
        $text | Should Match 'Index statuses unknown: 0'
    }
}

Describe 'skill-audit section 10: Agent Skills spec compliance' {
    It 'flags name/dir mismatch, oversized description, and non-standard fields in a sandbox' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "specfix-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'skills\wrong-name') -Force | Out-Null
            $longDesc = 'x' * 1025
            $sk = @('---', 'name: "totally-different"', 'slug: extra-field', "description: `"$longDesc`"", '---', '# body')
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\wrong-name\SKILL.md'), $sk, (New-Object System.Text.UTF8Encoding($true)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Spec violations: 3'
            $text | Should Match 'wrong-name'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'accepts a fully compliant skill (fields incl. metadata sub-block)' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "specok-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'skills\good-skill') -Force | Out-Null
            $sk = @('---', 'name: "good-skill"', 'description: "A good skill for testing spec compliance."', 'metadata:', '  author: x', '  version: "1.0"', '---', '# body')
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\good-skill\SKILL.md'), $sk, (New-Object System.Text.UTF8Encoding($true)))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Spec violations: 0'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'real repo: all 23 skill packages comply with the spec' {
        $report = Invoke-AuditAt ''
        $text = [IO.File]::ReadAllText($report)
        $text | Should Match 'Spec violations: 0'
    }
}
