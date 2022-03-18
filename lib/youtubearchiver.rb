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

module Youtubearchiver
  extend Configuration

  class Error < StandardError; end
  class AuthorizationError < Error; end
  class VideoNotFoundError < Error; end
  class ChannelNotFoundError < Error; end

  define_setting :temp_storage_location, "tmp/youtubearchiver"

  def self.retrieve_media(url)
    response = Typhoeus.get(url)

    # Get the file extension if it's in the file
    extension = url.split(".").last
    # Do some basic checks so we just empty out if there's something weird in the file extension
    # that could do some harm.
    unless extension.empty?
      extension = nil unless /^[a-zA-Z0-9]+$/.match?(extension)
      extension = ".#{extension}" unless extension.nil?
    end

    temp_file_name = "#{Youtubearchiver.temp_storage_location}/#{SecureRandom.uuid}#{extension}"

    # We do this in case the folder isn't created yet, since it's a temp folder we'll just do so
    create_temp_storage_location
    File.binwrite(temp_file_name, response.body)
    temp_file_name
  end

  def self.create_temp_storage_location
    return if File.exist?(Youtubearchiver.temp_storage_location) && File.directory?(Youtubearchiver.temp_storage_location)

    FileUtils.mkdir_p Youtubearchiver.temp_storage_location
  end
end
