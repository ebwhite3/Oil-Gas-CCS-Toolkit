# =============================================================================
# deploy.ps1 - Publish the NSLLC Petroleum Toolkit to Cloudflare Pages.
#
# One-command deploy. Stages this folder's toolkit as index.html (+ the public/
# logo), then direct-uploads to the Cloudflare Pages project via Wrangler. You
# control WHEN the public site changes - nothing auto-publishes on git push.
#
# Usage (from this folder, or just double-check the path):
#   pwsh -File deploy.ps1                 # deploy
#   pwsh -File deploy.ps1 -SkipVerify     # deploy, skip the post-deploy HTTP check
#   pwsh -File deploy.ps1 -Config "D:\path\.cloudflare.json"   # non-default creds
#
# Requirements: Node.js (npx) on PATH  ->  winget install OpenJS.NodeJS.LTS
# Credentials:  .cloudflare.json holding { token, account_id }. Auto-located in
#               the current user's _ClaudeOS Dropbox copy (works on both the i9
#               and the OptiPlex via %USERPROFILE%); never echoed or committed.
#
# Like serve.bat, this operates on its own folder ($PSScriptRoot), so it keeps
# working if the toolkit folder is moved or renamed - keep deploy.ps1 alongside
# oil-gas-ccs-toolkit.html.
# =============================================================================
[CmdletBinding()]
param(
  [string]$Config,
  [string]$Project = "nsllc-toolkit",
  [switch]$SkipVerify
)
$ErrorActionPreference = "Stop"

# Resolve the credentials file. An explicit -Config wins; otherwise try the
# current user's Dropbox (covers both the i9 [ebwhi] and OptiPlex [Admin] via
# %USERPROFILE%), then the two known absolute paths as a fallback.
if (-not $Config) {
  $candidates = @(
    (Join-Path $env:USERPROFILE "Dropbox (Personal)\_ClaudeCowork\_ClaudeOS\00_Resources\.cloudflare.json"),
    "C:\Users\ebwhi\Dropbox (Personal)\_ClaudeCowork\_ClaudeOS\00_Resources\.cloudflare.json",
    "C:\Users\Admin\Dropbox (Personal)\_ClaudeCowork\_ClaudeOS\00_Resources\.cloudflare.json"
  )
  $Config = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $Config) {
    throw "Could not auto-locate .cloudflare.json. Tried:`n  $($candidates -join "`n  ")`nPass it explicitly with -Config `"<path>`"."
  }
}

$ScriptDir = $PSScriptRoot
$SourceHtml = Join-Path $ScriptDir "oil-gas-ccs-toolkit.html"
$SourceLogo = Join-Path $ScriptDir "public\numeric-solutions-logo.png"
$ProdUrl = "https://$Project.pages.dev"

# --- preflight ---------------------------------------------------------------
# A shell opened before Node was installed won't have it on PATH yet; refresh.
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
}
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  throw "Node.js (npx) not found on PATH. Install it with:  winget install OpenJS.NodeJS.LTS  (then open a new terminal)."
}
if (-not (Test-Path $SourceHtml)) { throw "Toolkit not found: $SourceHtml" }
if (-not (Test-Path $SourceLogo)) { throw "Logo not found: $SourceLogo  (it is a relative asset and 404s if omitted)." }
if (-not (Test-Path $Config))     { throw "Cloudflare credentials not found: $Config" }

$cf = Get-Content $Config -Raw | ConvertFrom-Json
if (-not $cf.token -or -not $cf.account_id) { throw "Config $Config is missing 'token' or 'account_id'." }

# --- stage -------------------------------------------------------------------
# Cloudflare Pages serves index.html at the root, so the descriptively-named
# toolkit file is copied to index.html only here, at deploy time.
$Stage = Join-Path $env:TEMP "nsllc-toolkit-deploy"
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $Stage "public") | Out-Null
Copy-Item $SourceHtml (Join-Path $Stage "index.html") -Force
Copy-Item $SourceLogo (Join-Path $Stage "public\numeric-solutions-logo.png") -Force
Write-Host "Staged:" -ForegroundColor Cyan
Get-ChildItem $Stage -Recurse -File | ForEach-Object { "  " + $_.FullName.Substring($Stage.Length + 1) }

# --- deploy ------------------------------------------------------------------
$env:CLOUDFLARE_API_TOKEN  = $cf.token
$env:CLOUDFLARE_ACCOUNT_ID = $cf.account_id
Write-Host "Deploying to Cloudflare Pages project '$Project'..." -ForegroundColor Cyan
npx --yes wrangler@latest pages deploy "$Stage" --project-name $Project --branch main --commit-dirty=true
if ($LASTEXITCODE -ne 0) { throw "wrangler deploy failed (exit $LASTEXITCODE)." }

# --- verify ------------------------------------------------------------------
if (-not $SkipVerify) {
  Start-Sleep -Seconds 3
  Write-Host "Verifying $ProdUrl ..." -ForegroundColor Cyan
  $ok = $true
  foreach ($u in @($ProdUrl, "$ProdUrl/public/numeric-solutions-logo.png")) {
    try {
      $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 30
      "  HTTP {0,3}  {1}" -f $r.StatusCode, $u
      if ($r.StatusCode -ne 200) { $ok = $false }
    } catch { "  FAIL     $u  ($($_.Exception.Message))"; $ok = $false }
  }
  if (-not $ok) { throw "Post-deploy verification failed." }
}

Write-Host "`nDone. Live at $ProdUrl" -ForegroundColor Green
