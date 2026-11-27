# duplicate-detection.Tests.ps1 -- Pester 3.4 (PS 5.1 built-in) tests for skill-audit section 6.
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $tools 'skill-audit.ps1'

function Invoke-AuditAt([string]$ScanRoot) {
    if ($ScanRoot) { powershell -NoProfile -ExecutionPolicy Bypass -File $audit -ScanRoot $ScanRoot | Out-Null }
    else { powershell -NoProfile -ExecutionPolicy Bypass -File $audit | Out-Null }
    return (Join-Path $tools 'skill-audit-report.md')
}

Describe 'skill-audit section 6: duplicate definition detection' {
    It 'flags a >=40-char normative line present in two distinct files' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "dupfix-hit-$(Get-Random)"
        $long = '本条规范句超过四十个字符并且包含必须这一规范标记词，因此双定义检测必须将其命中成对出现。'
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'skills\alpha'), (Join-Path $fx 'skills\beta') -Force | Out-Null
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\alpha\SKILL.md'), @('# alpha', $long))
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\beta\SKILL.md'), @('# beta', $long))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Duplicate definitions: 1'
            $text | Should Match ([regex]::Escape('skills\alpha\SKILL.md'))
            $text | Should Match ([regex]::Escape('skills\beta\SKILL.md'))
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'ignores sub-40-char lines, within-file duplicates, and non-normative boilerplate' {
        $fx = Join-Path ([IO.Path]::GetTempPath()) "dupfix-miss-$(Get-Random)"
        $short = '本句带必须标记但长度不足四十字符因此不命中。'
        $same  = '本条长句出现在同一文件内两次，包含必须标记词，但由于不是跨文件双定义而不应被命中。'
        $plain = 'This is a long duplicated boilerplate line over forty characters without any normative marker at all.'
        try {
            New-Item -ItemType Directory -Path (Join-Path $fx 'skills\alpha'), (Join-Path $fx 'skills\beta') -Force | Out-Null
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\alpha\SKILL.md'), @('# alpha', $short, $same, $same, $plain))
            [IO.File]::WriteAllLines((Join-Path $fx 'skills\beta\SKILL.md'), @('# beta', $short, $plain))
            $report = Invoke-AuditAt $fx
            $text = [IO.File]::ReadAllText($report)
            $text | Should Match 'Duplicate definitions: 0'
        } finally { Remove-Item -Recurse -Force $fx -ErrorAction SilentlyContinue }
    }

    It 'current real library: zero duplicate definitions and verdict line unchanged' {
        $report = Invoke-AuditAt ''
        $text = [IO.File]::ReadAllText($report)
        $text | Should Match 'Duplicate definitions: 0'
        $text | Should Match 'Verdict: \*\*CLEAN\*\*'
    }
}
