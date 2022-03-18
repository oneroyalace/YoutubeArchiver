# frozen_string_literal: true

require "test_helper"
require "date"

class ChannelTest < MiniTest::Test
  def teardown
    cleanup_temp_folder
  end

  def test_that_a_scraped_youtube_channel_has_proper_attributes
    youtube_channel = Youtubearchiver::Channel.lookup("UC_x5XG1OV2P6uZZ5FSM9Ttw").first

    assert_instance_of Youtubearchiver::Channel, youtube_channel

    assert_equal youtube_channel.id, "UC_x5XG1OV2P6uZZ5FSM9Ttw"
    assert_equal youtube_channel.title, "Google Developers"
    assert_not_nil youtube_channel.description

    assert youtube_channel.view_count.to_i > 100_000_000
    assert youtube_channel.subscriber_count.to_i > 2_000_000
    assert youtube_channel.video_count.to_i > 5000

    assert_not_nil youtube_channel.channel_image_file_name
  end

  def test_raises_exception_for_nonexistent_videos
    assert_raises Youtubearchiver::ChannelNotFoundError do
      Youtubearchiver::Channel.lookup("abcde12345")
    end
  end
end
