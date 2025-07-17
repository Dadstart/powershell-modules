$ModuleRoot = $PSScriptRoot

function Get-ModuleType {
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$RootPath,
        [Parameter(Mandatory, Position = 2)]
        [string]$TypeName
    )

    $typesPath = Join-Path $RootPath $TypeName
    if (Test-Path $typesPath) {
        $types = Get-ChildItem -Path $typesPath -Filter '*.ps1' |
            Sort-Object BaseName |
            Select-Object -ExpandProperty BaseName
        return $types
    }
    else {
        return @()
    }
}

# Shared loading
$classes = Get-ModuleType $ModuleRoot 'Classes'
if ($classes) {
    foreach ($class in $classes) {
        Write-Verbose "Loading shared class: $class"
        . (Join-Path $ModuleRoot 'Classes' "$class.ps1")
        Write-Verbose "Loaded shared class: $class"
    }
    Export-ModuleMember -Variable $classes
}

$publicFunctions = Get-ModuleType $ModuleRoot 'Public'
if ($publicFunctions) {
    foreach ($function in $publicFunctions) {
        Write-Verbose "Loading public shared function: $function"
        . (Join-Path $ModuleRoot 'Public' "$function.ps1")
        Write-Verbose "Loaded public shared function: $function"
    }
    Export-ModuleMember -Function $publicFunctions
}

