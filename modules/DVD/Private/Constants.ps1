# DVD Module Constants
$Script:DefaultChapterNumber = 3
$Script:DefaultChapterDuration = 30
$Script:ProcessingSubDirectories = @('HandBrake', 'Remux', 'Topaz', 'Bonus')
$Script:HandBrakeCLIPath = 'C:\Program Files\HandBrake\HandBrakeCLI.exe'

# Audio bitrates
$Script:AudioBitrates = @{
    'Surround 5.1' = 384
    'Stereo'       = 160
    'Mono'         = 80
}

# Audio mixdowns
$Script:AudioMixdowns = @{
    'Surround 5.1' = '5point1'
    'Stereo'       = 'stereo'
    'Mono'         = 'mono'
} 