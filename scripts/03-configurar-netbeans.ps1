<#
  CadastroEE - prepara o NetBeans 25 (feche o NetBeans antes de rodar):
    - NetBeans executando com o JDK 17 (mesmo JDK do GlassFish 6)
    - servidor GlassFish 6.2.5 (C:\glassfish6) registrado na aba Serviços > Servidores
    - driver JDBC do SQL Server (mssql-jdbc-12.2.0.jre8.jar) em Serviços > Banco de Dados > Drivers
    - conexão "loja" (jdbc:sqlserver://localhost:1433;databaseName=loja;...)
    - nbproject/private/private.properties dos três projetos apontando para o GlassFish
  Log: scripts\logs\03-configurar-netbeans.log
#>
$ErrorActionPreference = "Continue"
$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$raiz       = Split-Path -Parent $scriptsDir
$logsDir    = Join-Path $scriptsDir "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
Start-Transcript -Path (Join-Path $logsDir "03-configurar-netbeans.log") -Force | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding($false)
function Gravar($caminho, $texto) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $caminho) | Out-Null
    [IO.File]::WriteAllText($caminho, $texto, $utf8)
    Write-Host "gravado: $caminho"
}
function XmlEsc($s) { return [Security.SecurityElement]::Escape($s) }

$ud     = Join-Path $env:APPDATA "NetBeans\25"
$jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1 -ExpandProperty FullName
if (-not $jdk) { $jdk = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine") }
$gfHome = "C:\glassfish6\glassfish"
$jar    = "$gfHome\lib\mssql-jdbc-12.2.0.jre8.jar"
$url    = "[$gfHome;$gfHome\domains\domain1]deployer:gfv610ee9:localhost:4848"
Write-Host "userdir: $ud`nJDK: $jdk`nGlassFish: $gfHome"

# 1) NetBeans rodando com o JDK 17
Gravar (Join-Path $ud "etc\netbeans.conf") "netbeans_jdkhome=`"$jdk`"`r`n"

# 2) Servidor GlassFish 6.2.5
$inst = Join-Path $ud "config\GlassFishJakartaEE91\Instances"
Gravar (Join-Path $inst "glassfish_autoregistered_instance") ""
Gravar (Join-Path $inst ".nbattrs") @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE attributes PUBLIC "-//NetBeans//DTD DefaultAttributes 1.0//EN" "http://www.netbeans.org/dtds/attributes-1_0.dtd">
<attributes version="1.0">
    <fileobject name="glassfish_autoregistered_instance">
        <attr name="adminPort" stringvalue="4848"/>
        <attr name="debugPort" stringvalue=""/>
        <attr name="derbyStartOn" boolvalue="false"/>
        <attr name="displayName" stringvalue="GlassFish Server 6.2.5"/>
        <attr name="domainname" stringvalue="domain1"/>
        <attr name="domainsfolder" stringvalue="$(XmlEsc "$gfHome\domains")"/>
        <attr name="driverDeployOn" stringvalue="true"/>
        <attr name="homefolder" stringvalue="$(XmlEsc $gfHome)"/>
        <attr name="host" stringvalue="localhost"/>
        <attr name="httphostname" stringvalue="localhost"/>
        <attr name="httpportnumber" stringvalue="8080"/>
        <attr name="installfolder" stringvalue="C:\glassfish6"/>
        <attr name="java.platform" stringvalue=""/>
        <attr name="jvmMode" stringvalue="normal"/>
        <attr name="password" stringvalue=""/>
        <attr name="preserveSessionsOn" boolvalue="true"/>
        <attr name="url" stringvalue="$(XmlEsc $url)"/>
        <attr name="use.shared.mem" boolvalue="false"/>
        <attr name="useIDEProxyOn" boolvalue="true"/>
        <attr name="username" stringvalue="admin"/>
    </fileobject>
</attributes>
"@

# 3) Driver JDBC do SQL Server e conexão com o banco loja
$jarUrl = "file:/" + ($jar -replace '\\', '/')
Gravar (Join-Path $ud "config\Databases\JDBCDrivers\SQLServer.xml") @"
<?xml version='1.0'?>
<!DOCTYPE driver PUBLIC '-//NetBeans//DTD JDBC Driver 1.1//EN' 'http://www.netbeans.org/dtds/jdbc-driver-1_1.dtd'>
<driver>
  <name value='SQLServer'/>
  <display-name value='Microsoft SQL Server'/>
  <class value='com.microsoft.sqlserver.jdbc.SQLServerDriver'/>
  <urls>
      <url value='$jarUrl'/>
  </urls>
</driver>
"@
Gravar (Join-Path $ud "config\Databases\Connections\loja.xml") @"
<?xml version='1.0'?>
<!DOCTYPE connection PUBLIC '-//NetBeans//DTD Database Connection 1.1//EN' 'http://www.netbeans.org/dtds/connection-1_1.dtd'>
<connection>
  <driver-class value='com.microsoft.sqlserver.jdbc.SQLServerDriver'/>
  <driver-name value='SQLServer'/>
  <database-url value='jdbc:sqlserver://localhost:1433;databaseName=loja;encrypt=true;trustServerCertificate=true;'/>
  <schema value='dbo'/>
  <user value='loja'/>
  <display-name value='loja [loja em dbo]'/>
  <password value='bG9qYQ=='/>
</connection>
"@

# 4) private.properties dos projetos
$udEsc  = ($ud -replace '\\', '\\')
$priv = @"
j2ee.server.domain=$($gfHome -replace '\\','\\')\\domains\\domain1
j2ee.server.home=$($gfHome -replace '\\','\\')
j2ee.server.instance=$($url -replace '\\','\\' -replace ':','\:')
j2ee.server.middleware=C\:\\glassfish6
user.properties.file=$udEsc\\build.properties
"@
foreach ($p in @("nbproject", "CadastroEE-ejb\nbproject", "CadastroEE-war\nbproject")) {
    Gravar (Join-Path $raiz "$p\private\private.properties") $priv
}

# 5) abrir os três projetos automaticamente na próxima vez que o NetBeans iniciar
$prefs = Join-Path $ud "config\Preferences\org\netbeans\modules\projectui.properties"
$urls = @($raiz, "$raiz\CadastroEE-ejb", "$raiz\CadastroEE-war") | ForEach-Object { ([Uri]((Resolve-Path $_).Path + "\")).AbsoluteUri }
$linhas = @()
if (Test-Path $prefs) { $linhas = Get-Content $prefs | Where-Object { $_ -notmatch '^(openProjectsURLs|openProjectsDisplayNames|openProjectsIcons|mainProjectURL)' } }
for ($i = 0; $i -lt $urls.Count; $i++) { $linhas += "openProjectsURLs.$i=$($urls[$i])" }
$linhas += "mainProjectURL=$($urls[0])"
Gravar $prefs (($linhas -join "`r`n") + "`r`n")

Write-Host "Concluido."
Stop-Transcript | Out-Null
