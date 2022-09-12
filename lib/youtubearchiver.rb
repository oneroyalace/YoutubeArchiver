# frozen_string_literal: true

require "json"
require "typhoeus"
require "byebug"
require "securerandom"
require "helpers/configuration"

require "fileutils"
require_relative "youtubearchiver/version"
require_relative "youtubearchiver/video"
require_relative "youtubearchiver/channel"

module YoutubeArchiver
  extend Configuration

  class Error < StandardError
    def initialize(msg = "Encountered an error scraping YouTube")
      super
    end
  end

  class RetryableError < StandardError; end

  class YoutubeApiError < RetryableError
    def initialize(msg = "Encountered a downstream YouTube API error")
      super
    end
  end

  class VideoDownloadError < RetryableError
    def initialize(msg = "Encountered an error during video downloading")
      super
    end
  end

  class AuthorizationError < Error; end
  class VideoNotFoundError < Error; end
  class ChannelNotFoundError < Error; end

  define_setting :temp_storage_location, "tmp/youtubearchiver"

  def self.retrieve_media(url, extension = nil)
    response = Typhoeus.get(url)

    # Get the file extension if it's in the file
    stripped_url = url.split("?").first
    extension = stripped_url.split(".").last if extension.nil?

    # Do some basic checks so we just empty out if there's something weird in the file extension
    # that could do some harm.
    unless extension.empty?
      extension = nil unless /^[a-zA-Z0-9]+$/.match?(extension)
      extension = ".#{extension}" unless extension.nil?
    end

    temp_file_name = "#{YoutubeArchiver.temp_storage_location}/youtube_media_#{SecureRandom.uuid}#{extension}"

    # We do this in case the folder isn't created yet, since it's a temp folder we'll just do so
    create_temp_storage_location
    File.binwrite(temp_file_name, response.body)
    temp_file_name
  end

  def self.create_temp_storage_location
    return if File.exist?(YoutubeArchiver.temp_storage_location) && File.directory?(YoutubeArchiver.temp_storage_location)

    FileUtils.mkdir_p YoutubeArchiver.temp_storage_location
  end
end
