# frozen_string_literal: true

require "test_helper"
require "date"

class VideoTest < Minitest::Test
  def teardown
    cleanup_temp_folder
  end


  def test_that_a_scraped_youtube_video_has_proper_attributes
    youtube_video = YoutubeArchiver::Video.lookup("T3UVKJsTz5g").first

    assert_instance_of YoutubeArchiver::Video, youtube_video

    assert_equal youtube_video.id, "T3UVKJsTz5g"
    assert_equal youtube_video.title, "Reviewing Injury Reserve's By the Time I Get to Phoenix in 10 seconds or less"
    assert_not youtube_video.live
    assert_equal youtube_video.duration, 10
    assert_equal youtube_video.language, "en-US"
    assert_not_nil youtube_video.channel
    assert_equal "UCyPVt0WxkrpUXOVUq0Hqtxw", youtube_video.channel.id
    assert_equal youtube_video.channel, youtube_video.user
    assert_nil youtube_video.screenshot_file

    assert youtube_video.num_views.to_i > 40_000
    assert youtube_video.num_likes.to_i > 3_000
    assert youtube_video.num_comments.to_i > 100

    assert_not_nil youtube_video.video_preview_image_file
    assert_not_nil youtube_video.video_file
  end

  def test_handles_youtube_shorts
    youtube_video = YoutubeArchiver::Video.lookup("cipFChOXDBM").first

    assert_instance_of YoutubeArchiver::Video, youtube_video
    assert_not_nil youtube_video.title

    assert_not_nil youtube_video.channel
    assert_equal "UCWheC07UYzRWXsv9yUnZJFw", youtube_video.channel.id
  end

  # Make sure we don't try to download an active live stream
  def test_handles_live_youtube_videos
    youtube_video = YoutubeArchiver::Video.lookup("21X5lGlDOfg").first

    assert_instance_of YoutubeArchiver::Video, youtube_video
    assert youtube_video.live
    assert_not_nil youtube_video.title
    assert_nil youtube_video.video_file

    assert_not_nil youtube_video.channel
    assert_equal "UCLA_DiR1FfKNvjuUpBHmylQ", youtube_video.channel.id
  end

  def test_raises_exception_for_unavailable_videos
    assert_raises YoutubeArchiver::VideoNotFoundError do
      YoutubeArchiver::Video.lookup("abcde12345")
    end
  end

  def test_other_url
    youtube_video = YoutubeArchiver::Video.lookup("fNQQ14k0LGw").first
    assert_instance_of YoutubeArchiver::Video, youtube_video
  end
end
