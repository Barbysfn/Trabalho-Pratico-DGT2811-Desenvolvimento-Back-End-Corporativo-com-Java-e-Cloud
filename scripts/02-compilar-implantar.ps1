<#
  CadastroEE - compila os três módulos (EJB, WAR, EAR) com o JDK 17,
  implanta o EAR no GlassFish 6 e testa as URLs principais.
  (No NetBeans, o equivalente é o botão Run/Deploy do projeto CadastroEE.)
  Log: scripts\logs\02-compilar-implantar.log
#>
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$raiz       = Split-Path -Parent $scriptsDir          # pasta CadastroEE
$logsDir    = Join-Path $scriptsDir "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
Start-Transcript -Path (Join-Path $logsDir "02-compilar-implantar.log") -Force | Out-Null

$gf   = "C:\glassfish6"
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1 -ExpandProperty FullName
if (-not $jdk) { $jdk = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine") }
$javac = Join-Path $jdk "bin\javac.exe"
$jarExe = Join-Path $jdk "bin\jar.exe"
Write-Host "JDK: $jdk"
$cpServidor = "$gf\glassfish\modules\*"

$build = Join-Path $raiz "build-cli"
if (Test-Path $build) { Remove-Item $build -Recurse -Force }
$ejbCls = Join-Path $build "ejb"; $warDir = Join-Path $build "war"; $earDir = Join-Path $build "ear"
New-Item -ItemType Directory -Force -Path $ejbCls, "$warDir\WEB-INF\classes", $earDir | Out-Null

function Compilar($destino, $cp, $srcDir) {
    # caminhos relativos (ASCII) no arquivo de argumentos, para evitar problemas com o "á" de "Estácio"
    $lista = Join-Path $build ("fontes-" + [guid]::NewGuid().ToString("N") + ".txt")
    Push-Location $srcDir
    $fontes = Get-ChildItem . -Recurse -Filter *.java | Resolve-Path -Relative | ForEach-Object { $_ -replace '^\.\\', '' -replace '\\', '/' }
    [IO.File]::WriteAllLines($lista, [string[]]$fontes)
    & $javac -encoding UTF-8 --release 11 -nowarn -d $destino -cp $cp "@$lista" 2>&1 | Out-Host
    $rc = $LASTEXITCODE
    Pop-Location
    return ($rc -eq 0)
}

# ---------- EJB ----------
Write-Host "==== Compilando CadastroEE-ejb ===="
$ok = Compilar $ejbCls $cpServidor "$raiz\CadastroEE-ejb\src\java"
if (-not $ok) { Write-Host "[FALHA] compilacao EJB"; Stop-Transcript; exit 1 }
New-Item -ItemType Directory -Force -Path "$ejbCls\META-INF" | Out-Null
Copy-Item "$raiz\CadastroEE-ejb\src\conf\persistence.xml" "$ejbCls\META-INF\"
& $jarExe cf "$earDir\CadastroEE-ejb.jar" -C $ejbCls . | Out-Host

# ---------- WAR ----------
Write-Host "==== Compilando CadastroEE-war ===="
$ok = Compilar "$warDir\WEB-INF\classes" "$cpServidor;$ejbCls" "$raiz\CadastroEE-war\src\java"
if (-not $ok) { Write-Host "[FALHA] compilacao WAR"; Stop-Transcript; exit 1 }
Copy-Item "$raiz\CadastroEE-war\web\*" $warDir -Recurse -Force
& $jarExe cf "$earDir\CadastroEE-war.war" -C $warDir . | Out-Host

# ---------- EAR ----------
Write-Host "==== Empacotando CadastroEE.ear ===="
$ear = Join-Path $build "CadastroEE.ear"
& $jarExe cf $ear -C $earDir . | Out-Host
Write-Host "EAR: $ear ($((Get-Item $ear).Length) bytes)"

# ---------- Deploy ----------
Write-Host "==== Implantando no GlassFish ===="
$asadmin = "$gf\bin\asadmin.bat"
$dominios = (& $asadmin list-domains) -join "`n"
if ($dominios -notmatch 'domain1 running') { & $asadmin start-domain domain1 | Out-Host }
& $asadmin deploy --force=true --name CadastroEE $ear | Out-Host

# ---------- Testes ----------
Write-Host "==== Testes HTTP ===="
foreach ($u in @("http://localhost:8080/CadastroEE-war/ServletProduto",
                 "http://localhost:8080/CadastroEE-war/ServletProdutoFC?acao=listar")) {
    try {
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 60
        Write-Host "GET $u -> $($r.StatusCode)"
        Write-Host $r.Content
    } catch { Write-Host "GET $u -> ERRO: $_" }
}
Write-Host "---- ultimas linhas do server.log ----"
Get-Content "$gf\glassfish\domains\domain1\logs\server.log" -Tail 60 -ErrorAction SilentlyContinue | Out-Host
Stop-Transcript | Out-Null
