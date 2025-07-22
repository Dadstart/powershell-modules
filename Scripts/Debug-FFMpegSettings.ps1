cls; C:\modules\quick-install.ps1 -Quiet -Force
$videoSettings = New-VideoEncodingSettings -Codec x264 -CRF 21 -Preset slow -CodecProfile high -Tune film
$audioMapping0 = New-AudioTrackMapping -SourceIndex 0 -DestinationIndex 1 -CopyOriginal
$audioMapping1 = New-AudioTrackMapping -SourceIndex 1 -DestinationIndex 0 -DestinationCodec aac -DestinationChannels 6
$transcodeSettings = @('-ss', '00:20:00', '-t', '00:01:00', '-i', "C:\temp\06\s06e01.raw.mkv") + $videoSettings.ToFfmpegArgs() + $audioMapping0.ToFfmpegArgs() + $audioMapping1.ToFfmpegArgs() + @("C:\temp\06\s06e01.ffmpeg6.mp4")



