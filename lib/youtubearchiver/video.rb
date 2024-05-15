# frozen_string_literal: true

require "securerandom"
require "logger"
require "byebug"
require "terrapin"

module YoutubeArchiver
  class Video
    @@youtube_logger = Logger.new(STDOUT)
    @@youtube_logger.level = Logger::INFO
    @@youtube_logger.datetime_format = "%Y-%m-%d %H:%M:%S"

    def self.lookup(ids = [])
      ids = [ids] unless ids.is_a?(Array)

      response = retrieve_data(ids)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      json_response = JSON.parse(response.body)
      raise YoutubeArchiver::VideoNotFoundError if json_response["items"].empty?

      json_response["items"].map { |video_hash| Video.new(video_hash) }
    # rescue YoutubeArchiver::VideoNotFoundError
    #   []
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
    attr_reader :user
    attr_accessor :screenshot_file # written in hypatia

    def initialize(video_hash)
      @json = video_hash
      parse(video_hash)
    end

    def parse(video_hash)
      @id = video_hash["id"]
      @created_at = video_hash["snippet"]["publishedAt"]
      @title = video_hash["snippet"]["title"]
      @channel_id = video_hash["snippet"]["channelId"]
      @language = video_hash["snippet"]["defaultAudioLanguage"]
      @duration = Video.convert_video_length_to_seconds(video_hash["contentDetails"]["duration"])
      @live = video_hash["snippet"]["liveBroadcastContent"] == "live"
      @num_views = video_hash["statistics"]["viewCount"]
      @num_likes = video_hash["statistics"]["likeCount"]
      @num_comments = video_hash["statistics"]["commentCount"]
      @video_preview_image_file = YoutubeArchiver.retrieve_media(video_hash["snippet"]["thumbnails"]["high"]["url"])
      @video_file = download_video
      @made_for_kids = video_hash["status"]["madeForKids"]
      @channel = Channel.lookup(@channel_id).first
      @user = @channel # Yes, a Youtube User is technically different than a YouTube channel, but we can ignore that.
      @screenshot_file = nil
    end

    def download_video
      return if @live

      @@youtube_logger.debug("YoutubeArchiver started downloading video with id: #{@id}")

      start_time = Time.now
      filename = "#{YoutubeArchiver.temp_storage_location}/youtube_media_#{SecureRandom.uuid}.mp4"
      line = Terrapin::CommandLine.new("yt-dlp", "-f :filetype -o :filename :url")

      line.run(filename:,
               filetype: "mp4",
               url: "https://www.youtube.com/watch?v=#{@id}")

      @@youtube_logger.debug("YoutubeArchiver finished downloading video with id: #{@id}")
      @@youtube_logger.debug("Save location: #{filename}")
      @@youtube_logger.debug("Time to download: #{(Time.now - start_time).round(3)} seconds")

      filename
    rescue Terrapin::ExitStatusError => e # yt-dlp command returns a non-zero exit status
      raise VideoDownloadError.new(e.message) # Retryable error
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

      response
    end

    def self.video_lookup(url, params)
      options = {
        method: "get",
        params:
      }

      request = Typhoeus::Request.new(url, options)
      response = request.run

      raise YoutubeArchiver::YoutubeApiError, "Invalid response code #{response.code}" if response.code > 500 # Retryable (downstream) error
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" if response.code > 400

      response
    end

    # Convert a YouTube duration string to number of seconds
    # A duration string of "PT0H4M32S" signifies a length of 4 minutes and 32 seconds
    def self.convert_video_length_to_seconds(duration_string)
      if /PT((\d+)H)?((\d+)M)?((\d+)S)?/ =~ duration_string  # Use regex to capture num_hours, num_minutes, num_seconds
        $2.to_i * 3600 + $4.to_i * 60 + $6.to_i # To convert to seconds, sum(num_hours*3600, num_minutes*60, num_seconds*1)
      else
        0
      end
    end
  end
end
