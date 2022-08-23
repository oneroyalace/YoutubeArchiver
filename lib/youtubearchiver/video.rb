# frozen_string_literal: true

require "securerandom"

require "byebug"
require "terrapin"

module YoutubeArchiver
  class Video
    def self.lookup(ids = [])
      # raise YoutubeArchiver::YoutubeApiError if rand > 0.5 # randomly raises a RetryableError
      ids = [ids] unless ids.is_a?(Array)

      response = retrieve_data(ids)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      json_response = JSON.parse(response.body)
      raise YoutubeArchiver::VideoNotFoundError if json_response["items"].empty?

      json_response["items"].map { |video_hash| Video.new(video_hash) }
    rescue YoutubeArchiver::VideoNotFoundError
      []
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
      @duration = video_hash["contentDetails"]["duration"]
      @live = video_hash["snippet"]["liveBroadcastContent"] == "live"
      @num_views = video_hash["statistics"]["viewCount"]
      @num_likes = video_hash["statistics"]["likeCount"]
      @num_comments = video_hash["statistics"]["commentCount"]
      @video_preview_image_file = YoutubeArchiver.retrieve_media(video_hash["snippet"]["thumbnails"]["high"]["url"])
      @video_file = download_video
      @made_for_kids = video_hash["status"]["madeForKids"]
      @channel = Channel.lookup(@channel_id).first
      @user = @channel # Yes, a Youtube User is technically different than a YouTube channel, but we can ignore that to fit with our existing taxonomy
      @screenshot_file = nil
    end

    def download_video
      return if @live

      filename = "#{YoutubeArchiver.temp_storage_location}/youtube_media_#{SecureRandom.uuid}.mp4"
      line = Terrapin::CommandLine.new("yt-dlp", "-f :filetype -o :filename :url")

      puts "Downloading video #{@id} @ #{Time.now}"
      line.run(filename:,
               filetype: "mp4",
               url: "https://www.youtube.com/watch?v=#{@id}")
      puts "Finished downloading video #{@id} @ #{Time.now}"
      filename
    rescue
      raise VideoDownloadError # Retryable error
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
  end
end
