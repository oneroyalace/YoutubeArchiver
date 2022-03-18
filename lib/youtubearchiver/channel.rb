# frozen_string_literal: true

require "byebug"
require "securerandom"

require "youtube-dl"

module YoutubeArchiver
  class Channel
    def self.lookup(ids = [])
      ids = [ids] unless ids.is_a?(Array)

      # ids.each { |id| raise YoutubeArchiver::InvalidIdError unless /\A\d+\z/.match(id) }
      response = retrieve_data(ids)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      json_response = JSON.parse(response.body)
      raise YoutubeArchiver::ChannelNotFoundError if json_response["items"].nil? || json_response["items"].empty?

      json_response["items"].map { |json_channel| Channel.new(json_channel) }
    end

    attr_reader :id
    attr_reader :created_at
    attr_reader :title
    attr_reader :description
    attr_reader :view_count
    attr_reader :subscriber_count
    attr_reader :video_count
    attr_reader :made_for_kids
    attr_reader :channel_image_file_name

    def initialize(json_channel)
      @json = json_channel
      parse(json_channel)
    end

    def parse(json_channel)
      @id = json_channel["id"]
      @created_at = json_channel["snippet"]["publishedAt"]
      @title = json_channel["snippet"]["title"]
      @description = json_channel["snippet"]["description"]
      @view_count = json_channel["statistics"]["viewCount"]
      @subscriber_count = json_channel["statistics"]["subscriberCount"]
      @video_count = json_channel["statistics"]["videoCount"]
      @made_for_kids = json_channel["status"]["madeForKids"]
      @channel_image_file_name = YoutubeArchiver.retrieve_media(json_channel["snippet"]["thumbnails"]["high"]["url"])
    end

    def self.retrieve_data(ids)
      api_key = ENV["YOUTUBE_API_KEY"]
      channel_api_url = "https://youtube.googleapis.com/youtube/v3/channels/"
      params = {
        "part": "snippet,statistics,status",
        "id": ids.join(","),
        "key": api_key
      }

      response = channel_lookup(channel_api_url, params)
      raise YoutubeArchiver::AuthorizationError, "Invalid response code #{response.code}" unless response.code == 200

      response
    end

    def self.channel_lookup(url, params)
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
