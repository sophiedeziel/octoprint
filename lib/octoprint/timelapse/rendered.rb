# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # A rendered timelapse file.
    #
    # @example
    #   file = Octoprint::Timelapse.list.files.first
    #   file.name      # => "benchy_20261115.mp4"
    #   file.size      # => "2.0MB"
    #   file.bytes     # => 2097152
    #   file.url       # => "/downloads/timelapse/benchy_20261115.mp4"
    #   file.thumbnail # => "/downloads/timelapse/benchy_20261115.mp4.thumb.jpg"
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html#rendered-timelapse
    class Rendered
      extend T::Sig
      include AutoInitializable
      include Deserializable

      # @!attribute [r] name
      #   @return [String] The file name
      auto_attr :name, type: String

      # @!attribute [r] size
      #   @return [String] The formatted file size, e.g. "2.0MB"
      auto_attr :size, type: String

      # @!attribute [r] bytes
      #   @return [Integer] The file size in bytes
      auto_attr :bytes, type: Integer

      # @!attribute [r] date
      #   @return [String] The formatted modification date, e.g. "2026-11-15 00:52"
      auto_attr :date, type: String

      # @!attribute [r] timestamp
      #   @return [Float, nil] The modification date as a Unix timestamp
      auto_attr :timestamp, type: Float

      # @!attribute [r] url
      #   @return [String] The path to download the file
      auto_attr :url, type: String

      # @!attribute [r] thumbnail
      #   @return [String, nil] The path to download the thumbnail, if there is one
      auto_attr :thumbnail, type: String

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # The modification date as a Time
      #
      # @example
      #   Octoprint::Timelapse.list.files.first.modification_time # => 2026-11-15 00:52:35 -0500
      #
      # @return [Time, nil]
      sig { returns(T.nilable(Time)) }
      def modification_time
        Time.at(timestamp) if timestamp
      end
    end
  end
end
