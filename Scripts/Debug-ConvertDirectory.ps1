C:\modules\quick-install.ps1 -Force -Quiet

$seasonDir = 'C:\temp\07\test'
Set-Location $seasonDir
C:\modules\scripts\Convert-Directory.ps1 -InputDirectory $seasonDir -Verbose -Debug
