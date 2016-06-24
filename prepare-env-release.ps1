<#
$note = 'hey mom, my second powershell script'
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
$cmd = "$cmd`"`"`" USE_STDCALL=1 API_ARMOR=1 USE_CRT_DLL=0 XCOMPILE=0 NO_TCL=1 SYMBOLS=0 WIN32HEAP=1 DEBUG=1 OPTIMIZATIONS=9 PLATFORM=x86 TCLSH_CMD=`""
$cmd = $cmd + [string](Get-Command "tclsh.exe").Source
$cmd = "$cmd`" LTLINKOPTS=`""
$cmd = $cmd + @'
""E:\lib\openssl\1.0.2h\msvc2013-x86-asm-shared-release\lib\libeay32.lib""" "OPTS=-DSQLITE_HAS_CODEC -DTHREADSAFE=1 -DNO_TCL=1 -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_DEFAULT_FOREIGN_KEYS=1 -DSQLITE_OMIT_TRACE=1 -DSQLITE_THREADSAFE=1 -DSQLITE_TEMP_STORE=2 -DSQLITE_DEFAULT_SYNCHRONOUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=0 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_EXTFUNC=1 -DSQLITE_OMIT_TCL_VARIABLE=1 -DSQLITE_ENABLE_FTS3_TOKENIZER=1 -DSQLITE_ENABLE_FTS4=1 -DSQLITE_OMIT_UTF16=1 -DSQLITE_OMIT_PROGRESS_CALLBACK=1 -DSQLITE_OMIT_COMPILEOPTION_DIAGS=1 -DSQLITE_DEFAULT_WORKER_THREADS=1 -DSQLITE_MAX_WORKER_THREADS=3 -DSQLITE_POWERSAFE_OVERWRITE=1 -DSQLITE_DIRECT_OVERFLOW_READ=1 -DSQLITE_SECURE_DELETE=1 -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 -DSQLITE_DISABLE_LFS=1 -DSQLITE_ENABLE_API_ARMOR=1 -DHAVE_LOCALTIME_S -DSQLITE_WIN32_MALLOC=1 -DSQLITE_WIN32_HEAP_CREATE=1 -DSQLITE_WIN32_MALLOC_VALIDATE=0 -DSQLITE_ENABLE_FTS3=1 -D_USING_V120_SDK71_ -DSQLITE_API=__declspec(dllexport) -IE:\lib\openssl\1.0.2h\msvc2013-x86-asm-shared-release\include"
'@

Write-Host ""

New-Item -Path . -Name GO.bat -Type "file" -Value "cd /d `"$exec_dir`" & `"$nmake_cmd`" $cmd"
Invoke-Expression ".\GO.bat"

Set-Location -Path "$start_location"

Rename-Item ".\sqlcipher-$sqlcipher_version" ".\sqlcipher-release"

Write-Host ""
Write-Host "---------------------------------------------------------"
Write-Host ""
Write-Host "You are done! Close the PS console and go to QtCreator `:`)"
Write-Host ""