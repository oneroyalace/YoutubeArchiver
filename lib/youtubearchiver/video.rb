# frozen_string_literal: true

require "securerandom"

require "byebug"
require "terrapin"

module YoutubeArchiver
  class Video
    def self.lookup(ids = [])
      ids = [ids] unless ids.is_a?(Array)

      # ids.each { |id| raise YoutubeArchiver::InvalidIdError unless /\A\d+\z/.match(id) }
      response = retrieve_data(ids)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      json_response = JSON.parse(response.body)
      raise YoutubeArchiver::VideoNotFoundError if json_response["items"].empty?

      json_response["items"].map { |json_video| Video.new(json_video) }
    end

    attr_reader :json
    attr_reader :id
    attr_reader :created_at
    attr_reader :title
    attr_reader :language
    attr_reader :duration
    attr_reader :num_views
    attr_reader :num_likes
    attr_reader :num_comments
    attr_reader :live
    attr_reader :video_preview_image_file
    attr_reader :video_file
    attr_reader :made_for_kids
    attr_reader :channel

    def initialize(json_video)
      @json = json_video
      parse(json_video)
    end

    def parse(json_video)
      @id = json_video["id"]
      @created_at = json_video["snippet"]["publishedAt"]
      @title = json_video["snippet"]["title"]
      @channel_id = json_video["snippet"]["channelId"]
      @language = json_video["snippet"]["defaultAudioLanguage"]
      @duration = json_video["contentDetails"]["duration"]
      @live = json_video["snippet"]["liveBroadcastContent"] == "live"
      @num_views = json_video["statistics"]["viewCount"]
      @num_likes = json_video["statistics"]["likeCount"]
      @num_comments = json_video["statistics"]["commentCount"]
      @video_preview_image_file = YoutubeArchiver.retrieve_media(json_video["snippet"]["thumbnails"]["high"]["url"])
      @video_file = download_video
      @made_for_kids = json_video["status"]["madeForKids"]
      @channel = Channel.lookup(@channel_id).first
    end

    def download_video
      return if @live

      filename = "#{YoutubeArchiver.temp_storage_location}/#{SecureRandom.uuid}.mp4"
      line = Terrapin::CommandLine.new("yt-dlp", "-f :filetype -o :filename :url")

      puts "Downloading video #{@id} @ #{Time.now}"
      line.run(filename:,
               filetype: "mp4",
               url: "https://www.youtube.com/watch?v=#{@id}")
      puts "Finished downloading video #{@id} @ #{Time.now}"
      filename
    end

    def self.retrieve_data(ids)
      api_key = ENV["YOUTUBE_API_KEY"]
      youtube_base_url = "https://youtube.googleapis.com/youtube/v3/videos/"
      params = {
        "part": "contentDetails,snippet,statistics,status",
        "id": ids.join(","),
        "key": api_key
      }

      response = video_lookup(youtube_base_url, params)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      response
    end

    def self.video_lookup(url, params)
      options = {
        method: "get",
        params:
      }

      request = Typhoeus::Request.new(url, options)
      response = request.run
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      response
    end
  end
end
