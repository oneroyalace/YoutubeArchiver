# frozen_string_literal: true

require "test_helper"
require "date"

class ChannelTest < MiniTest::Test
  def teardown
    cleanup_temp_folder
  end

  def test_that_a_scraped_youtube_channel_has_proper_attributes
    youtube_channel = YoutubeArchiver::Channel.lookup("UC_x5XG1OV2P6uZZ5FSM9Ttw").first

    assert_instance_of YoutubeArchiver::Channel, youtube_channel

    assert_equal youtube_channel.id, "UC_x5XG1OV2P6uZZ5FSM9Ttw"
    assert_equal "Google for Developers", youtube_channel.title
    assert_not_nil youtube_channel.description

    assert youtube_channel.view_count.to_i > 100_000_000
    assert youtube_channel.subscriber_count.to_i > 2_000_000
    assert youtube_channel.video_count.to_i > 5000

    assert_not_nil youtube_channel.channel_image_file
  end

  def test_raises_exception_for_nonexistent_videos
    assert_raises YoutubeArchiver::ChannelNotFoundError do
      YoutubeArchiver::Channel.lookup("abcde12345")
    end
  end
end
