# frozen_string_literal: true

require "test_helper"
require "date"

class VideoTest < MiniTest::Test
  def teardown
    cleanup_temp_folder
  end

  def test_that_a_scraped_youtube_video_has_proper_attributes
    youtube_video = Youtubearchiver::Video.lookup("T3UVKJsTz5g").first

    assert_instance_of Youtubearchiver::Video, youtube_video

    assert_equal youtube_video.id, "T3UVKJsTz5g"
    assert_equal youtube_video.title, "Reviewing Injury Reserve's By the Time I Get to Phoenix in 10 seconds or less"
    refute youtube_video.live
    assert_equal youtube_video.duration, "PT10S"
    assert_equal youtube_video.language, "en-US"
    assert_equal youtube_video.channel_id, "UCyPVt0WxkrpUXOVUq0Hqtxw"
    assert_not_nil youtube_video.author

    assert youtube_video.num_views.to_i > 40_000
    assert youtube_video.num_likes.to_i > 3_000
    assert youtube_video.num_comments.to_i > 100

    assert_not_nil youtube_video.video_preview_image_file_name
    assert_not_nil youtube_video.video_file_name
  end

  def test_handles_youtube_shorts
    youtube_video = Youtubearchiver::Video.lookup("cipFChOXDBM").first

    assert_instance_of Youtubearchiver::Video, youtube_video
    assert_not_nil youtube_video.title

    assert_not_nil youtube_video.author
    assert_equal youtube_video.author.id, "UCWheC07UYzRWXsv9yUnZJFw"
  end

  def test_handles_live_youtube_videos
    youtube_video = Youtubearchiver::Video.lookup("nDDzUyGvloE").first

    assert_instance_of Youtubearchiver::Video, youtube_video
    assert youtube_video.live
    assert_not_nil youtube_video.title
    assert_nil youtube_video.video_file_name

    assert_not_nil youtube_video.author
    assert_equal youtube_video.author.id, "UCGv9D6jI_5qb12RzoEU4aEA"
  end

  def test_raises_exception_for_nonexistent_videos
    assert_raises Youtubearchiver::VideoNotFoundError do
      Youtubearchiver::Video.lookup("abcde12345")
    end
  end
end
