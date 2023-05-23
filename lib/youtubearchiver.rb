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
  @@youtube_logger = Logger.new(STDOUT)
  @@youtube_logger.level = Logger::INFO
  @@youtube_logger.datetime_format = "%Y-%m-%d %H:%M:%S"

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

  def self.extract_file_extension_from_url(url)
    stripped_url = url.split("?").first # remove URL query params
    extension = stripped_url.split(".").last if extension.nil?

    # Do some basic checks so we just empty out if there's something weird in the file extension
    # that could do some harm.
    extension = nil unless /^[a-zA-Z0-9]+$/.match?(extension)
    extension = ".#{extension}" unless extension.nil?
    extension
  end

  def self.retrieve_media(url, extension = nil)
    @@youtube_logger.debug("YoutubeArchiver started downloading media at URL: #{url}")
    start_time = Time.now

    response = Typhoeus.get(url)

    extension = YoutubeArchiver.extract_file_extension_from_url(url)
    temp_file_name = "#{YoutubeArchiver.temp_storage_location}/youtube_media_#{SecureRandom.uuid}#{extension}"

    # We do this in case the folder isn't created yet, since it's a temp folder we'll just do so
    create_temp_storage_location
    File.binwrite(temp_file_name, response.body)

    @@youtube_logger.debug("YoutubeArchiver finished downloading media at URL: #{url}")
    @@youtube_logger.debug("Save location: #{temp_file_name}")
    @@youtube_logger.debug("Time to download: #{(Time.now - start_time).round(3)} seconds")

    temp_file_name
  end

  def self.create_temp_storage_location
    return if File.exist?(YoutubeArchiver.temp_storage_location) && File.directory?(YoutubeArchiver.temp_storage_location)

    FileUtils.mkdir_p YoutubeArchiver.temp_storage_location
  end
end
