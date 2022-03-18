# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "youtubearchiver"

require "minitest/autorun"

def cleanup_temp_folder
  FileUtils.rm_r("tmp") if File.exist?("tmp") && File.directory?("tmp")
end

require "minitest/assertions"
module Minitest::Assertions
  def assert_not_nil(object)
    assert object.nil? == false, "Expected a non-nil object but received nil"
  end
end
