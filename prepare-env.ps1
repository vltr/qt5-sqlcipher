<#
$note = 'hey mom, my first powershell script'
#>

$sqlcipher_version = "3.4.0"
$start_location = "$PSScriptRoot"

Write-Host ""
Write-Host "Testing environment ..."
Write-Host ""

if ((Get-Command "tclsh.exe" -ErrorAction SilentlyContinue) -eq $null) { 
	Write-Error "Unable to find tclsh.exe in your PATH."
	Write-Host "Please, install ActiveTCL from http://www.activestate.com/activetcl"
	Write-Host "You can install any other TCL that suits this build script."
	return
} else {
	Write-Host "- tclsh.exe found!"
}

if ((Get-Command "nmake.exe" -ErrorAction SilentlyContinue) -eq $null) { 
	Write-Error "Unable to find nmake.exe in your PATH"
	Write-Host "Are you sure you have any development tool?"
	return
} else {
	Write-Host "- nmake.exe found!"
}

if ((Get-Command "cl.exe" -ErrorAction SilentlyContinue) -eq $null) { 
	Write-Error "Unable to find cl.exe in your PATH"
	Write-Host "Are you sure you have any development tool?"
	return
} else {
	Write-Host "- cl.exe found!"
}

# thanks to http://stackoverflow.com/a/27768628
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Write-Host ""
Write-Host "Ok, everything seems fine so far ..."

$download_url = "https://github.com/sqlcipher/sqlcipher/archive/v$sqlcipher_version.zip"
$output = "$PSScriptRoot\sqlcipher.zip"

if (Test-Path $output) {
	Write-Host "The zipped source exists already, no need to download."
	Write-Host "Extracting source ..."
} else {
	Write-Host "Downloading SQLCipher v$sqlcipher_version ... This might take a while ..."
	(New-Object System.Net.WebClient).DownloadFile($download_url, $output)
	Write-Host "Download finished. Extracting source ..."
}

$dest_dir = "$PSScriptRoot\."
Unzip $output $dest_dir
Write-Host "Extract finished. Let the damage begin ..."
Set-Location -Path "$start_location\sqlcipher-$sqlcipher_version"

$exec_dir = [string](Get-Location).Path

$nmake_cmd = [string](Get-Command "nmake.exe").Source
$cmd = "-f `""
$cmd = $cmd + [string](Get-Location).Path
$cmd = "$cmd\Makefile.msc`" libsqlite3.lib `"NCC=`"`""
$cmd = $cmd + [string](Get-Command "cl.exe").Source
$cmd = "$cmd`"`"`" SYMBOLS=1 OPTIMIZATIONS=0 DYNAMIC_SHELL=0 USE_NATIVE_LIBPATHS=0 USE_CRT_DLL=0 USE_ICU=0 DEBUG=3 XCOMPILE=0 NO_TCL=1 PLATFORM=x86 USE_FULLWARN=1 API_ARMOR=1 USE_RC=1 MEMDEBUG=1 OSTRACE=1 TCLSH_CMD=`""
$cmd = $cmd + [string](Get-Command "tclsh.exe").Source
$cmd = "$cmd`" LTLINKOPTS=`""
$cmd = $cmd + @'
""E:\lib\openssl-1.0.2h-msvc2013-x86-debug-nasm\bin"";""E:\lib\openssl-1.0.2h-msvc2013-x86-debug-nasm\lib"" ""E:\lib\openssl-1.0.2h-msvc2013-x86-debug-nasm\lib\libeay32.lib""" "OPTS=-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=2 -D_USING_V120_SDK71_ -DSQLITE_API=__declspec(dllexport) -IE:\lib\openssl-1.0.2h-msvc2013-x86-debug-nasm\include"
'@

Write-Host ""

New-Item -Path . -Name GO.bat -Type "file" -Value "cd /d `"$exec_dir`" & `"$nmake_cmd`" $cmd"
Invoke-Expression ".\GO.bat"

Set-Location -Path "$start_location"

Rename-Item ".\sqlcipher-$sqlcipher_version" ".\sqlcipher-src"

Write-Host ""
Write-Host "---------------------------------------------------------"
Write-Host ""
Write-Host "You are done! Close the PS console and go to QtCreator `:`)"
Write-Host ""