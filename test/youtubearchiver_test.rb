# frozen_string_literal: true

require "test_helper"

class YoutubeArchiverTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert_not_nil ::YoutubeArchiver::VERSION
  end
end
