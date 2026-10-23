<#
  CadastroEE - Instalação do ambiente (Windows)
  ------------------------------------------------
  Instala (se ainda não existir):
    - JDK 17 (Eclipse Temurin)
    - Apache NetBeans
    - SQL Server 2022 Express (instância padrão, TCP 1433, autenticação mista)
    - SQL Server Management Studio
    - GlassFish 6.2.5 em C:\glassfish6
    - Driver JDBC mssql-jdbc-12.2.0.jre8.jar (copiado para C:\glassfish6\glassfish\lib)
  Configura:
    - banco "loja" (login/senha loja) a partir de scripts\sql\loja.sql
    - pool de conexões SQLServerPool e recurso JNDI jdbc/loja no GlassFish
  Log: scripts\logs\01-instalar-ambiente.log
#>
param([string]$UsuarioOriginal = "")

$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logsDir    = Join-Path $scriptsDir "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

# ---------- auto-elevação ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $u = "$env:USERDOMAIN\$env:USERNAME"
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($MyInvocation.MyCommand.Path)`"", "-UsuarioOriginal", "`"$u`"")
    exit
}
if (-not $UsuarioOriginal) { $UsuarioOriginal = "$env:USERDOMAIN\$env:USERNAME" }

$log = Join-Path $logsDir "01-instalar-ambiente.log"
Start-Transcript -Path $log -Force | Out-Null
$status = [ordered]@{}
function Etapa($nome) { Write-Host ""; Write-Host "==== $nome ====" -ForegroundColor Cyan }
function Ok($k, $v)   { $status[$k] = "OK: $v";    Write-Host "[OK] $k - $v" -ForegroundColor Green }
function Falha($k, $v){ $status[$k] = "FALHA: $v"; Write-Host "[FALHA] $k - $v" -ForegroundColor Red }

$downloads = Join-Path $env:TEMP "cadastroee-setup"
New-Item -ItemType Directory -Force -Path $downloads | Out-Null
$temWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
Write-Host "Usuario: $UsuarioOriginal  | winget: $temWinget"

function Baixar($url, $destino) {
    if (Test-Path $destino) { return $true }
    try { Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing; return $true }
    catch { Write-Host "Erro ao baixar $url : $_"; return $false }
}
function InstalarWinget($id, $extra = @()) {
    if (-not $temWinget) { return $false }
    $wa = @("install", "--id", $id, "-e", "--silent", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity", "--source", "winget") + $extra
    Write-Host "winget $($wa -join ' ')"
    & winget.exe @wa | Out-Host
    return ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189)  # 0x8A15002B = já instalado
}
function AtualizarPath {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
}

# =====================================================================
Etapa "1. JDK 17"
function AcharJdk17 {
    $bases = @("C:\Program Files\Eclipse Adoptium", "C:\Program Files\Java", "C:\Program Files\Microsoft", "C:\Program Files\Zulu")
    foreach ($b in $bases) {
        if (Test-Path $b) {
            $d = Get-ChildItem $b -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(jdk-?17|zulu-?17|jdk17)' -and (Test-Path (Join-Path $_.FullName "bin\javac.exe")) } | Select-Object -First 1
            if ($d) { return $d.FullName }
        }
    }
    return $null
}
$jdk = AcharJdk17
if (-not $jdk) {
    if (-not (InstalarWinget "EclipseAdoptium.Temurin.17.JDK")) {
        $msi = Join-Path $downloads "temurin17.msi"
        if (Baixar "https://api.adoptium.net/v3/installer/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk" $msi) {
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome /qn"
        }
    }
    $jdk = AcharJdk17
}
if ($jdk) {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk, "Machine")
    $env:JAVA_HOME = $jdk
    Ok "JDK17" $jdk
} else { Falha "JDK17" "nao encontrado apos instalacao" }

# =====================================================================
Etapa "2. Apache NetBeans"
function AcharNetBeans {
    $c = @()
    foreach ($b in @("C:\Program Files", "$env:LOCALAPPDATA\Programs", "C:\Program Files (x86)")) {
        if (Test-Path $b) { $c += Get-ChildItem $b -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'NetBeans' } }
    }
    foreach ($d in $c) {
        $exe = Get-ChildItem $d.FullName -Recurse -Filter "netbeans64.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { return (Split-Path (Split-Path $exe.FullName -Parent) -Parent) }
    }
    return $null
}
$nb = AcharNetBeans
if (-not $nb) { InstalarWinget "Apache.NetBeans" | Out-Null; $nb = AcharNetBeans }
if ($nb) { Ok "NetBeans" $nb } else { Falha "NetBeans" "nao encontrado apos instalacao" }

# =====================================================================
Etapa "3. GlassFish 6.2.5"
$gfRoot = "C:\glassfish6"
if (-not (Test-Path "$gfRoot\bin\asadmin.bat")) {
    $zip = Join-Path $downloads "glassfish-6.2.5.zip"
    $ok = Baixar "https://repo1.maven.org/maven2/org/glassfish/main/distributions/glassfish/6.2.5/glassfish-6.2.5.zip" $zip
    if (-not $ok) { $ok = Baixar "https://download.eclipse.org/ee4j/glassfish/glassfish-6.2.5.zip" $zip }
    if ($ok) { Expand-Archive -Path $zip -DestinationPath "C:\" -Force }
}
if (Test-Path "$gfRoot\bin\asadmin.bat") {
    # GlassFish deve rodar com o JDK 17
    if ($jdk) {
        $asenv = "$gfRoot\glassfish\config\asenv.bat"
        $conteudo = Get-Content $asenv | Where-Object { $_ -notmatch '^set AS_JAVA=' }
        $conteudo += "set AS_JAVA=$jdk"
        Set-Content -Path $asenv -Value $conteudo -Encoding ASCII
    }
    Ok "GlassFish" $gfRoot
} else { Falha "GlassFish" "download/extracao falhou" }

# =====================================================================
Etapa "4. Driver JDBC do SQL Server (mssql-jdbc-12.2.0.jre8.jar)"
$driversDir = Join-Path $scriptsDir "drivers"
New-Item -ItemType Directory -Force -Path $driversDir | Out-Null
$jar = Join-Path $driversDir "mssql-jdbc-12.2.0.jre8.jar"
$ok = Baixar "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.2.0.jre8/mssql-jdbc-12.2.0.jre8.jar" $jar
if (-not $ok) {
    # alternativa: pacote zip oficial da Microsoft
    $mszip = Join-Path $downloads "sqljdbc_12.2.0.0_ptb.zip"
    if (Baixar "https://go.microsoft.com/fwlink/?linkid=2222954" $mszip) {
        Expand-Archive $mszip -DestinationPath (Join-Path $downloads "sqljdbc") -Force
        $f = Get-ChildItem (Join-Path $downloads "sqljdbc") -Recurse -Filter "mssql-jdbc-12.2.0.jre8.jar" | Select-Object -First 1
        if ($f) { Copy-Item $f.FullName $jar -Force; $ok = $true }
    }
}
if ($ok -and (Test-Path "$gfRoot\glassfish\lib")) {
    Copy-Item $jar "$gfRoot\glassfish\lib\" -Force
    Ok "DriverJDBC" "$gfRoot\glassfish\lib\mssql-jdbc-12.2.0.jre8.jar"
} else { Falha "DriverJDBC" "nao foi possivel baixar/copiar" }

# =====================================================================
Etapa "5. SQL Server 2022 Express"
function AcharInstanciaSql {
    $k = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    if (Test-Path $k) {
        $p = Get-ItemProperty $k
        foreach ($n in @("MSSQLSERVER", "SQLEXPRESS")) { if ($p.$n) { return @{ Nome = $n; Id = $p.$n } } }
        $prop = $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | Select-Object -First 1
        if ($prop) { return @{ Nome = $prop.Name; Id = $prop.Value } }
    }
    return $null
}
$inst = AcharInstanciaSql
if (-not $inst) {
    $ini = Join-Path $downloads "sqlconfig.ini"
    $saPwd = "Sa#" + ([guid]::NewGuid().ToString("N").Substring(0, 16)) + "x9"
@"
[OPTIONS]
ACTION="Install"
FEATURES=SQLENGINE
INSTANCENAME="MSSQLSERVER"
INSTANCEID="MSSQLSERVER"
SQLSYSADMINACCOUNTS="$UsuarioOriginal"
SECURITYMODE="SQL"
SAPWD="$saPwd"
TCPENABLED="1"
NPENABLED="0"
UPDATEENABLED="False"
IACCEPTSQLSERVERLICENSETERMS="True"
QUIET="True"
"@ | Set-Content -Path $ini -Encoding Unicode
    # 1) obtem o bootstrapper oficial (SSEI) do SQL Server 2022 Express
    $sseiDir = Join-Path $downloads "ssei"
    New-Item -ItemType Directory -Force -Path $sseiDir | Out-Null
    $ssei = Get-ChildItem $sseiDir -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $ssei -and $temWinget) {
        & winget.exe download --id Microsoft.SQLServer.2022.Express -e -d $sseiDir --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
        $ssei = Get-ChildItem $sseiDir -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if (-not $ssei) {
        $dest = Join-Path $sseiDir "SQL2022-SSEI-Expr.exe"
        if (Baixar "https://go.microsoft.com/fwlink/p/?linkid=2216019" $dest) { $ssei = Get-Item $dest }
    }
    if ($ssei) {
        # 2) baixa a midia "Core" do Express e extrai
        $media = Join-Path $downloads "sqlmedia"
        Write-Host "Baixando midia do SQL Server Express..."
        Start-Process $ssei.FullName -Wait -ArgumentList "/ACTION=Download /MEDIAPATH=`"$media`" /MEDIATYPE=Core /QUIET /ENU"
        $pkg = Get-ChildItem $media -Filter "SQLEXPR*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pkg) {
            $ext = Join-Path $downloads "sqlexpr"
            Start-Process $pkg.FullName -Wait -ArgumentList "/q /x:`"$ext`""
            # 3) instala com o arquivo de configuracao (instancia padrao, TCP, autenticacao mista)
            Write-Host "Instalando SQL Server Express (pode levar ~10 min)..."
            $p = Start-Process (Join-Path $ext "setup.exe") -Wait -PassThru -ArgumentList "/CONFIGURATIONFILE=`"$ini`""
            Write-Host "setup.exe exit code: $($p.ExitCode)"
        } else { Write-Host "Midia do SQL Server nao foi baixada." }
    } else {
        Write-Host "Bootstrapper nao obtido; tentando instalacao padrao via winget"
        InstalarWinget "Microsoft.SQLServer.2022.Express" | Out-Null
    }
    Remove-Item $ini -Force -ErrorAction SilentlyContinue
    $inst = AcharInstanciaSql
}
if ($inst) {
    Ok "SQLServer" "instancia $($inst.Nome) ($($inst.Id))"
    # --- TCP 1433 fixo + autenticacao mista ---
    $base = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($inst.Id)\MSSQLServer"
    Set-ItemProperty -Path $base -Name LoginMode -Value 2
    $tcp = "$base\SuperSocketNetLib\Tcp"
    Set-ItemProperty -Path $tcp -Name Enabled -Value 1
    Set-ItemProperty -Path "$tcp\IPAll" -Name TcpPort -Value "1433"
    Set-ItemProperty -Path "$tcp\IPAll" -Name TcpDynamicPorts -Value ""
    $svc = if ($inst.Nome -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$($inst.Nome)" }
    Set-Service -Name $svc -StartupType Automatic
    Restart-Service -Name $svc -Force
    Start-Sleep -Seconds 8
    $sqlServerLocal = if ($inst.Nome -eq "MSSQLSERVER") { "localhost" } else { "localhost\$($inst.Nome)" }
    Ok "SQLServerTCP" "porta 1433, autenticacao mista, servico $svc"
} else { Falha "SQLServer" "instancia nao encontrada apos instalacao" }

# =====================================================================
Etapa "6. Banco loja (scripts\sql\loja.sql)"
function ExecutarSqlScript($connStr, $arquivo) {
    $sql = Get-Content $arquivo -Raw -Encoding UTF8
    $lotes = [regex]::Split($sql, '^\s*GO\s*$', [Text.RegularExpressions.RegexOptions]::Multiline)
    $cn = New-Object System.Data.SqlClient.SqlConnection $connStr
    $cn.Open()
    foreach ($l in $lotes) {
        if ($l.Trim()) {
            $cmd = $cn.CreateCommand(); $cmd.CommandText = $l; $cmd.CommandTimeout = 120
            [void]$cmd.ExecuteNonQuery()
        }
    }
    $cn.Close()
}
if ($inst) {
    try {
        ExecutarSqlScript "Server=$sqlServerLocal;Database=master;Integrated Security=True;" (Join-Path $scriptsDir "sql\loja.sql")
        # teste com o login loja via TCP 1433 (o mesmo caminho usado pelo JDBC)
        $cn = New-Object System.Data.SqlClient.SqlConnection "Server=tcp:localhost,1433;Database=loja;User Id=loja;Password=loja;"
        $cn.Open(); $cmd = $cn.CreateCommand(); $cmd.CommandText = "SELECT COUNT(*) FROM Produto"
        $n = $cmd.ExecuteScalar(); $cn.Close()
        Ok "BancoLoja" "login loja/loja via TCP 1433 OK; $n produtos"
    } catch { Falha "BancoLoja" "$_" }
}

# =====================================================================
Etapa "7. GlassFish: pool SQLServerPool e recurso jdbc/loja"
if (Test-Path "$gfRoot\bin\asadmin.bat") {
    $asadmin = "$gfRoot\bin\asadmin.bat"
    & $asadmin start-domain domain1
    $pools = (& $asadmin list-jdbc-connection-pools) -join "`n"
    if ($pools -notmatch 'SQLServerPool') {
        # mesmo comando do roteiro, executado no modo multimode do asadmin (com o id do pool ao final)
        $cmds = Join-Path $downloads "asadmin-pool.txt"
@'
create-jdbc-connection-pool --datasourceclassname com.microsoft.sqlserver.jdbc.SQLServerDataSource --restype javax.sql.DataSource --property driverClass=com.microsoft.sqlserver.jdbc.SQLServerDriver:portNumber=1433:password=loja:user=loja:serverName=localhost:databaseName=loja:trustServerCertificate=true:URL="jdbc\\:sqlserver\\://localhost\\:1433\\;databaseName\\=loja\\;encrypt\\=true\\;trustServerCertificate\\=true\\;" SQLServerPool
'@ | Set-Content -Path $cmds -Encoding ASCII
        & $asadmin multimode --file $cmds | Out-Host
        $pools = (& $asadmin list-jdbc-connection-pools) -join "`n"
        if ($pools -notmatch 'SQLServerPool') {
            Write-Host "Tentando sem a propriedade URL..."
            & $asadmin create-jdbc-connection-pool --datasourceclassname com.microsoft.sqlserver.jdbc.SQLServerDataSource --restype javax.sql.DataSource --property "driverClass=com.microsoft.sqlserver.jdbc.SQLServerDriver:portNumber=1433:password=loja:user=loja:serverName=localhost:databaseName=loja:trustServerCertificate=true" SQLServerPool
        }
    }
    $ping = (& $asadmin ping-connection-pool SQLServerPool) -join "`n"
    Write-Host $ping
    if ($ping -match 'successfully') { Ok "PoolSQLServer" "ping-connection-pool SQLServerPool executado com sucesso" } else { Falha "PoolSQLServer" $ping }
    $res = (& $asadmin list-jdbc-resources) -join "`n"
    if ($res -notmatch 'jdbc/loja') { & $asadmin create-jdbc-resource --connectionpoolid SQLServerPool jdbc/loja }
    $res = (& $asadmin list-jdbc-resources) -join "`n"
    if ($res -match 'jdbc/loja') { Ok "RecursoJNDI" "jdbc/loja" } else { Falha "RecursoJNDI" $res }
    & $asadmin stop-domain domain1
}

# =====================================================================
Etapa "8. SQL Server Management Studio (opcional, demorado)"
$ssms = Get-ChildItem "C:\Program Files*\Microsoft SQL Server Management Studio*" -Recurse -Filter "Ssms.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $ssms) {
    foreach ($id in @("Microsoft.SQLServerManagementStudio.21", "Microsoft.SQLServerManagementStudio")) {
        if (InstalarWinget $id) { break }
    }
    $ssms = Get-ChildItem "C:\Program Files*\Microsoft SQL Server Management Studio*" -Recurse -Filter "Ssms.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($ssms) { Ok "SSMS" $ssms.FullName } else { Falha "SSMS" "nao instalado (opcional)" }

# =====================================================================
# o Liberica JDK (dependencia do NetBeans) muda o JAVA_HOME; volta para o JDK 17
if ($jdk) { [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk, "Machine") }

Etapa "Resumo"
$status | Format-Table -AutoSize | Out-String -Width 300 | Write-Host
$status | ConvertTo-Json | Set-Content -Path (Join-Path $logsDir "01-status.json") -Encoding UTF8
Stop-Transcript | Out-Null
Write-Host "Concluido. Esta janela pode ser fechada."
