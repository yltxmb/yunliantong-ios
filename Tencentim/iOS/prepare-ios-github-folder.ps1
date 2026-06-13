# 从 d:\yk 抽出「仅 iOS 云链通」目录，供 GitHub 上传
# 用法: cd d:\yk\Tencentim\iOS  然后  .\prepare-ios-github-folder.ps1

$ErrorActionPreference = "Stop"
$srcRoot = "d:\yk"
$dstRoot = "d:\yunliantong-ios"

$paths = @(
    @{ Src = ".github"; Dst = ".github" },
    @{ Src = "Tencentim\TencentCloud-TIMSDK\iOS\Demo"; Dst = "Tencentim\TencentCloud-TIMSDK\iOS\Demo" },
    @{ Src = "Tencentim\iOS\README.md"; Dst = "Tencentim\iOS\README.md" },
    @{ Src = "Tencentim\iOS\GITHUB-SETUP.md"; Dst = "Tencentim\iOS\GITHUB-SETUP.md" },
    @{ Src = "Tencentim\iOS\prepare-ios-github-folder.ps1"; Dst = "Tencentim\iOS\prepare-ios-github-folder.ps1" }
)

if (Test-Path $dstRoot) {
    Write-Host "清理旧目录 $dstRoot ..."
    Remove-Item -Recurse -Force $dstRoot
}
New-Item -ItemType Directory -Force -Path $dstRoot | Out-Null

foreach ($p in $paths) {
    $from = Join-Path $srcRoot $p.Src
    $to = Join-Path $dstRoot $p.Dst
    if (-not (Test-Path $from)) {
        Write-Warning "跳过（不存在）: $($p.Src)"
        continue
    }
    $parent = Split-Path $to -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    if (Test-Path $from -PathType Container) {
        Write-Host "复制目录 $($p.Src) ..."
        robocopy $from $to /E /XD Pods build DerivedData xcuserdata .git /XF *.xcuserstate /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy 失败: $($p.Src)" }
    } else {
        Write-Host "复制文件 $($p.Src) ..."
        Copy-Item -Force $from $to
    }
}

@'
# YunLianTong iOS (GitHub repo)

Only iOS Demo + GitHub Actions. See `Tencentim/iOS/GITHUB-SETUP.md`.

GitHub Desktop: add folder `d:\yunliantong-ios` (NOT `d:\yk`).
'@ | Set-Content -Encoding UTF8 (Join-Path $dstRoot "README.md")

Write-Host ""
Write-Host "Done. GitHub Desktop -> Add local repository:"
Write-Host "  $dstRoot"
Write-Host ""
