# 📘 FFprobe JSON Output Reference
## 🧾 -show_format
Returns metadata about the container format.

| Field            | Example Value           | Description                            |
|------------------|-------------------------|----------------------------------------|
| filename         | "movie.mkv"             | Name of the input file                 |
| nb_streams       | 3                       | Number of streams in the container     |
| format_name      | "matroska,webm"         | Short name(s) of the container format  |
| format_long_name | "Matroska / WebM"       | Full name of the container format      |
| start_time       | "0.000000"              | Start time of the container in seconds |
| duration         | "3600.123456"           | Duration of the container in seconds   |
| size             | "123456789"             | File size in bytes                     |
| bit_rate         | "456789"                | Overall bit rate in bits per second    |
| probe_score      | 100                     | Confidence score of format detection (0–100) |
| tags             | { "title": "My Movie" } | Container-level metadata tags |

## 📚 -show_chapters
Returns chapter information if present.

| Field       | Example Value        | Description                                |
|-------------|----------------------|--------------------------------------------|
| id          | 0                    | Chapter index                              |
| time_base   | "1/1000"             | Time base used for timestamps              |
| start       | 0                    | Start timestamp (in time_base units)       |
| start_time  | "0.000000"           | Start time in seconds                      |
| end         | 60000                | End timestamp (in time_base units)         |
| end_time    | "60.000000"          | End time in seconds                        |
| tags        | { "title": "Intro" } | Metadata tags for the chapter (e.g. title) |

## 🎞️ -show_streams
Returns detailed info about each stream (video, audio, subtitle, etc.).

| Field           | Example Value              | Description                            |
|-----------------|----------------------------|----------------------------------------|
| index           | 0                          | Stream index                           |
| codec_name      | "h264"                     | Codec short name                       |
| codec_long_name | "H.264 / AVC / MPEG-4 AVC" | Codec full name                        |
| codec_type      | "video"                    | Type of stream (video, audio, subtitle, etc.) |
| profile         | "High"                     | Codec profile                          |
| width / height  | 1920 / 1080                | Video resolution (only for video)      |
| sample_rate     | "48000"                    | Audio sample rate (only for audio)     |
| channels        | 2                          | Number of audio channels               |
| channel_layout  | "stereo"                   | Audio channel layout                   |
| bit_rate        | "320000"                   | Bit rate of the stream                 |
| duration        | "3600.123456"              | Duration of the stream in seconds      |
| r_frame_rate    | "25/1"                     | Raw frame rate                         |
| avg_frame_rate  | "25/1"                     | Average frame rate                     |
| time_base       | "1/90000"                  | Time base used for timestamps          |
| start_time      | "0.000000"                 | Start time of the stream in seconds    |
| tags            | { "language": "eng" }      | Stream-level metadata tags             |
| disposition     | { "default": 1 }           | Stream disposition flags (e.g. default, forced, etc.) |
