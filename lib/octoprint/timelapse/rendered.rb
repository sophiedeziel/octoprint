# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # A rendered timelapse file.
    #
    # Has the shared {FileAttributes} (+name+, +size+, +bytes+, +date+, +extra+), plus the
    # download paths and the modification timestamp.
    #
    # @example
    #   file = Octoprint::Timelapse.get.files.first
    #   file.name      # => "benchy_20261115.mp4"
    #   file.size      # => "2.0MB"
    #   file.bytes     # => 2097152
    #   file.url       # => "/downloads/timelapse/benchy_20261115.mp4"
    #   file.thumbnail # => "/downloads/timelapse/benchy_20261115.mp4.thumb.jpg"
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html#rendered-timelapse
    class Rendered
      include AutoInitializable
      include Deserializable
      include FileAttributes

      # @!attribute [r] timestamp
      #   @return [Float, nil] The modification date as a Unix timestamp
      auto_attr :timestamp, type: Float

      # @!attribute [r] url
      #   @return [String] The path to download the file
      auto_attr :url, type: String

      # @!attribute [r] thumbnail
      #   @return [String, nil] The path to download the thumbnail, if there is one
      auto_attr :thumbnail, type: String

      auto_initialize!

      # The modification date as a Time
      #
      # @example
      #   Octoprint::Timelapse.get.files.first.modification_time # => 2026-11-15 00:52:35 -0500
      #
      # @return [Time, nil]
      #: -> Time?
      def modification_time
        Time.at(timestamp) if timestamp
      end
    end
  end
end
