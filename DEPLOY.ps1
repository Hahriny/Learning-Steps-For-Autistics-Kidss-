# ============================================================
#  Learning Steps For Autistic Kids - ONE-CLICK DEPLOY SCRIPT
# ============================================================
#  HOW TO USE:
#  1. Get FRESH keys from https://eliteacademy.awsapps.com/start
#     (click your account -> Access keys -> copy the 3 lines)
#  2. Paste your 3 keys into the section marked below
#  3. Right-click this file -> "Run with PowerShell"
#     OR in PowerShell run:  ./DEPLOY.ps1
# ============================================================

# ---- STEP 1: PASTE YOUR FRESH SANDBOX KEYS HERE ----
$env:AWS_ACCESS_KEY_ID     = "PASTE_ACCESS_KEY_HERE"
$env:AWS_SECRET_ACCESS_KEY = "PASTE_SECRET_KEY_HERE"
$env:AWS_SESSION_TOKEN     = "PASTE_SESSION_TOKEN_HERE"
$env:AWS_DEFAULT_REGION    = "ap-southeast-1"
# ----------------------------------------------------

# Make sure aws, sam and git are on PATH for this session
$env:PATH += ";C:\Program Files\Amazon\AWSCLIV2"
$env:PATH += ";C:\Program Files\Amazon\AWSSAMCLI\bin"
$env:PATH += ";C:\Program Files\Git\cmd"

$ErrorActionPreference = "Stop"
$STACK  = "learning-steps"
$REGION = "ap-southeast-1"
$ROOT   = "C:\Users\User\Learning Steps For Autistic Kids Kiro"

Set-Location $ROOT

Write-Host "`n=== STEP 1: Checking which AWS account we are in ===" -ForegroundColor Cyan
aws sts get-caller-identity
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Keys are invalid or expired. Get fresh keys and paste them at the top of this file." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n=== STEP 2: Building the app with SAM ===" -ForegroundColor Cyan
sam build --template infra/template.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Build failed. Read the message above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n=== STEP 3: Deploying to AWS (3-5 minutes) ===" -ForegroundColor Cyan
sam deploy `
    --stack-name $STACK `
    --resolve-s3 `
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM `
    --region $REGION `
    --no-confirm-changeset `
    --no-fail-on-empty-changeset
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Deploy failed. Read the message above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n=== STEP 4: Reading the deployed URLs ===" -ForegroundColor Cyan
function Get-Output($key) {
    aws cloudformation describe-stacks --stack-name $STACK --region $REGION `
        --query "Stacks[0].Outputs[?OutputKey=='$key'].OutputValue" --output text
}

$bucket     = Get-Output "BucketName"
$website    = Get-Output "WebsiteUrl"
$diagram    = Get-Output "DiagramApiUrl"
$lesson     = Get-Output "YourLessonUrl"
$writing    = Get-Output "WritingPracticeUrl"
$badge      = Get-Output "YourStarBadgeUrl"
$parent     = Get-Output "ParentandTeacherNotesUrl"
$helper     = Get-Output "FriendlyLearningHelperUrl"

Write-Host "Bucket:  $bucket"
Write-Host "Website: $website"

Write-Host "`n=== STEP 5: Injecting backend URLs into the website ===" -ForegroundColor Cyan
$html = Get-Content "frontend/index.html" -Raw
$html = $html -replace '__DIAGRAM_API_URL__',           $diagram
$html = $html -replace '__URL_YOUR_LESSON__',           $lesson
$html = $html -replace '__URL_WRITING_PRACTICE__',      $writing
$html = $html -replace '__URL_YOUR_STAR_BADGE__',       $badge
$html = $html -replace '__URL_PARENT_AND_TEACHER_NOTES__', $parent
$html = $html -replace '__URL_FRIENDLY_LEARNING_HELPER__', $helper
Set-Content "frontend/index.html" -Value $html -NoNewline

Write-Host "`n=== STEP 6: Uploading website files to S3 ===" -ForegroundColor Cyan
aws s3 sync frontend/ "s3://$bucket/" --region $REGION --cache-control "no-cache"

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  DONE! Your website is LIVE at:" -ForegroundColor Green
Write-Host "  $website" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host "`nOpen that link in your browser!`n"
Read-Host "Press Enter to close"
