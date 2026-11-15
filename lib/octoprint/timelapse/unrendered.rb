# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # An unrendered timelapse job: the snapshots of a print, not yet rendered to a video.
    #
    # @example
    #   job = Octoprint::Timelapse.list(unrendered: true).unrendered.first
    #   job.name       # => "cube_20261115"
    #   job.count      # => 342
    #   job.size       # => "12.3MB"
    #   job.processing # => false
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html#unrendered-timelapse
    class Unrendered
      extend T::Sig
      include AutoInitializable
      include Deserializable

      # @!attribute [r] name
      #   @return [String] The name of the job
      auto_attr :name, type: String

      # @!attribute [r] count
      #   @return [Integer, nil] The number of snapshots
      auto_attr :count, type: Integer

      # @!attribute [r] size
      #   @return [String] The formatted size of all snapshots, e.g. "12.3MB"
      auto_attr :size, type: String

      # @!attribute [r] bytes
      #   @return [Integer] The size of all snapshots in bytes
      auto_attr :bytes, type: Integer

      # @!attribute [r] date
      #   @return [String] The formatted creation date of the job, e.g. "2026-11-15 00:52"
      auto_attr :date, type: String

      # @!attribute [r] recording
      #   @return [Boolean] Whether the job is still recording
      auto_attr :recording, type: Types::Boolean

      # @!attribute [r] rendering
      #   @return [Boolean] Whether the job is being rendered
      auto_attr :rendering, type: Types::Boolean

      # @!attribute [r] processing
      #   @return [Boolean] Whether the job is recording or rendering
      auto_attr :processing, type: Types::Boolean

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
