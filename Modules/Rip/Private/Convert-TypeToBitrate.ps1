# Audio bitrates
$Script:AudioBitrates = @{
    'Surround 5.1' = 384
    'Stereo'       = 160
    'Mono'         = 80
}
function Convert-TypeToBitrate {
    <#
    .SYNOPSIS
        Converts audio type to HandBrake bitrate setting.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Surround 5.1', 'Stereo', 'Mono')]
        [string]$Type
    )
    if ($Script:AudioBitrates.ContainsKey($Type)) {
        return $Script:AudioBitrates[$Type]
    }
    throw "Unknown audio type: $Type"
}
