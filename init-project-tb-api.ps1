# ================================================================
#  new-api.ps1  -  Create new project from tb.api.template
#  Usage : .\new-api.ps1 [ProjectName]
#  Example: .\new-api.ps1 my.company.orders
# ================================================================

param(
    [string]$ProjectName = ""
)

$TEMPLATE_REPO   = "https://github.com/NITINAIP/tb-template.git"
$TEMPLATE_FOLDER = "tb.api.template"
$TMPL_PLAIN      = "tb.api.template"
$TMPL_PASCAL_DOT = "Tb.Api.Template"
$TMPL_PASCAL     = "TbApiTemplate"
$TMPL_SNAKE      = "tb_api_template"

# ── Color helpers ────────────────────────────────────────────────
function Write-Step   { param($n,$msg) Write-Host "[$n/5] $msg" -ForegroundColor Cyan }
function Write-Ok     { param($msg)    Write-Host "  OK  $msg"  -ForegroundColor Green }
function Write-Fail   { param($msg)    Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# ── Banner ───────────────────────────────────────────────────────
Write-Host ""
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host "  TB API Project Generator"                         -ForegroundColor Cyan
Write-Host " ================================================" -ForegroundColor Cyan
Write-Host ""

# ── รับชื่อโปรเจค ────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Read-Host " Project name (e.g. my.company.orders)"
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Fail "Project name cannot be empty."
}

$TargetDir = Join-Path (Get-Location) $ProjectName

# ── ตรวจ git ─────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail "Git is not installed."
}

# ── ตรวจ folder ซ้ำ ─────────────────────────────────────────────
if (Test-Path $TargetDir) {
    Write-Fail "Folder already exists: $TargetDir"
}

# ── สร้าง casing variants ────────────────────────────────────────
#   my.company.orders  →  My.Company.Orders / MyCompanyOrders / my_company_orders
$parts           = $ProjectName.Split('.')
$pascalParts     = $parts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
$ProjectPascalDot = $pascalParts -join '.'
$ProjectPascal    = $pascalParts -join ''
$ProjectSnake     = $ProjectName.Replace('.','_').ToLower()

Write-Host ""
Write-Host " Project  : $ProjectName"
Write-Host " Location : $TargetDir"
Write-Host ""
Write-Host " Patterns:"
Write-Host "   $TMPL_PLAIN      -> $ProjectName"
Write-Host "   $TMPL_PASCAL_DOT -> $ProjectPascalDot"
Write-Host "   $TMPL_PASCAL     -> $ProjectPascal"
Write-Host "   $TMPL_SNAKE  -> $ProjectSnake"
Write-Host ""

# ── [1/5] Sparse-checkout เฉพาะ tb.api.template ─────────────────
Write-Step 1 "Cloning tb.api.template (sparse)..."

$TmpDir = Join-Path $env:TEMP ("_tb_tpl_" + [System.IO.Path]::GetRandomFileName())

try {
    git clone --no-checkout --depth=1 --filter=blob:none $TEMPLATE_REPO $TmpDir 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Fail "git clone failed." }

    Push-Location $TmpDir
    git sparse-checkout init --cone 2>$null
    git sparse-checkout set $TEMPLATE_FOLDER 2>$null
    git checkout 2>$null
    Pop-Location
}
catch {
    Write-Fail "Clone error: $_"
}

Write-Ok "Cloned."

# ── [2/5] Copy template → TargetDir ─────────────────────────────
Write-Step 2 "Copying template..."

$SrcPath = Join-Path $TmpDir $TEMPLATE_FOLDER
Copy-Item -Path $SrcPath -Destination $TargetDir -Recurse -Force
Remove-Item $TmpDir -Recurse -Force

Write-Ok "Copied."

# ── [3/5] Rename files & folders ────────────────────────────────
Write-Step 3 "Renaming files and folders..."

# Sort Descending → rename ลึกสุดก่อน ป้องกัน path หาย
Get-ChildItem -Path $TargetDir -Recurse |
    Where-Object { $_.Name -like "*$TMPL_PLAIN*" } |
    Sort-Object FullName -Descending |
    ForEach-Object {
        $newName = $_.Name -replace [regex]::Escape($TMPL_PLAIN), $ProjectName
        Rename-Item -Path $_.FullName -NewName $newName -Force
    }

Write-Ok "Done."

# ── [4/5] Replace text inside files ─────────────────────────────
Write-Step 4 "Replacing text inside files..."

$Extensions = @(
    "*.cs","*.csproj","*.sln","*.json","*.yaml","*.yml",
    "*.xml","*.config","*.md","*.txt","*.props","*.targets",
    "*.env","*.sh","*.bat","Dockerfile"
)

$files = Get-ChildItem -Path $TargetDir -Recurse -Include $Extensions |
         Where-Object { -not $_.PSIsContainer }

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Replace ลำดับ: PascalDot ก่อน (ยาวกว่า) → Pascal → Snake → Plain
    $updated = $content `
        -replace [regex]::Escape($TMPL_PASCAL_DOT), $ProjectPascalDot `
        -replace [regex]::Escape($TMPL_PASCAL),     $ProjectPascal `
        -replace [regex]::Escape($TMPL_SNAKE),      $ProjectSnake `
        -replace [regex]::Escape($TMPL_PLAIN),      $ProjectName

    if ($content -ne $updated) {
        [System.IO.File]::WriteAllText($file.FullName, $updated, [System.Text.Encoding]::UTF8)
    }
}

Write-Ok "Done."

# ── [5/5] Init git ───────────────────────────────────────────────
Write-Step 5 "Initializing git..."

Push-Location $TargetDir
git init -q
git add .
git commit -q -m "Initial commit (from tb.api.template)"
Pop-Location

Write-Ok "Done."

# ── Summary ───────────────────────────────────────────────────────
Write-Host ""
Write-Host " ================================================" -ForegroundColor Green
Write-Host "  Done! Project ready: $ProjectName"               -ForegroundColor Green
Write-Host "  Path: $TargetDir"                                -ForegroundColor Green
Write-Host " ================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Next steps:"
Write-Host "   cd $ProjectName"
Write-Host "   dotnet restore"
Write-Host "   dotnet build"
Write-Host ""