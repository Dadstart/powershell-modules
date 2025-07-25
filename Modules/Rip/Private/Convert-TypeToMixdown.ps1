# Audio mixdowns
$Script:AudioMixdowns = @{
    'Surround 5.1' = '5point1'
    'Stereo'       = 'stereo'
    'Mono'         = 'mono'
}
function Convert-TypeToMixdown {
    <#
    .SYNOPSIS
        Converts audio type to HandBrake mixdown setting.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Surround 5.1', 'Stereo', 'Mono')]
        [string]$Type
    )
    if ($Script:AudioMixdowns.ContainsKey($Type)) {
        return $Script:AudioMixdowns[$Type]
    }
    throw "Unknown audio type: $Type"
}
