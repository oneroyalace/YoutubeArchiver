# Overview

YoutubeArchiver is a Ruby gem that downloads YouTube Video metadata and media. It works in conjunction with [Zenodotus](https://github.com/TechAndCheck/zenodotus) and [Hypatia](https://github.com/TechAndCheck/hypatia) to archive fact-checked image/video posts. YoutubeArchiver exists alongside a collection of other media scrapers created by the Duke Reporters' Lab, including [Birdsong](https://github.com/cguess/birdsong/) (a Twitter scraper), [Zorki](https://github.com/cguess/zorki) (an Instagram scraper), and [Forki](https://github.com/TechAndCheck/forki) (a Facebook scraper). 

Like the other scrapers, YoutubeArchiver follows a standard architecture created by @cguess. The scraper is engaged by one of two methods: `Video.lookup` or `Channel.lookup`, which respectively return `YoutubeArchiver::Video` and `YoutubeArchiver::Channel` objects. These psuedo JSON object store video/channel metadata and media. 

`YoutubeArchiver` differs from the other scrapers in how it acquires media and metadata for a video or channel lookup. `YoutubeArchiver` uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) to download video media files and the [YouTube Data API V3](https://developers.google.com/youtube/v3) to download channel and video metadata. For now, the project pecifically uses the Youtube API's [Videos: list](https://developers.google.com/youtube/v3/docs/videos/list) and [Channels: list](https://developers.google.com/youtube/v3/docs/channels/list) endpoints. 

# Installation

Add this line to your application's Gemfile:

```ruby
gem 'youtubearchiver'
```

And then execute:

    $ bundle install
## Requirements
`YoutubeArchiver` uses yt-dlp to download Youtube Videos. Installation instructions for the project can be found [here](https://github.com/yt-dlp/yt-dlp#installation). 

# Setup

## Acquiring a YouTube API key

1. [Create or select](https://console.cloud.google.com/projectselector2/home/dashboard?authuser=0&supportedpurview=project&pli=1) a Google Cloud Project  
2. Find the [Youtube Data API v3](https://console.cloud.google.com/apis/api/youtube.googleapis.com/metrics?project=multi-scrobble-yt&authuser=0&supportedpurview=project) in the Google API marketplace. Enable the API for the selected project. 
3. After enabling the API, click on the credentials tab link in the API page sidebar. 
4. Create an "API Key" credential. 

## Setting environment variables
Set the `YOUTUBE_API_KEY` environment variable equal to the API key generated above. Make sure not to commit the API key to git!
