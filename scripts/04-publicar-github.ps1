<#
  CadastroEE - publica o projeto no GitHub (repositório Barbysfn/Trabalho-Pratico-DGT2811-...)
  Usa o histórico de commits do arquivo CadastroEE.bundle (deixado na pasta scripts).
  Na primeira vez, o Git Credential Manager pode abrir o navegador para autorizar o GitHub.
  Log: scripts\logs\04-publicar-github.log
#>
$ErrorActionPreference = "Continue"
$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$raiz       = Split-Path -Parent $scriptsDir
$logsDir    = Join-Path $scriptsDir "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
Start-Transcript -Path (Join-Path $logsDir "04-publicar-github.log") -Force | Out-Null

$git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) { $git = "git" }
$url = "https://github.com/Barbysfn/Trabalho-Pratico-DGT2811-Desenvolvimento-Back-End-Corporativo-com-Java-e-Cloud.git"
$bundle = Join-Path $scriptsDir "CadastroEE.bundle"

Set-Location $raiz
if (-not (Test-Path (Join-Path $raiz ".git"))) { & $git init -b main 2>&1 | Out-Host }
& $git config user.name "Bárbara Floripes"
& $git config user.email "barbysfn@users.noreply.github.com"
if (Test-Path $bundle) {
    & $git fetch $bundle "main:refs/remotes/bundle/main" 2>&1 | Out-Host
    & $git reset --hard bundle/main 2>&1 | Out-Host
}
& $git remote remove origin 2>$null
& $git remote add origin $url
& $git log --oneline -n 10 2>&1 | Out-Host
Write-Host "==== git push ===="
& $git push -u origin main 2>&1 | Out-Host
Write-Host "push exit code: $LASTEXITCODE"
& $git status --short 2>&1 | Out-Host
Stop-Transcript | Out-Null
