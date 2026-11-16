# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # An unrendered timelapse job: the snapshots of a print, not yet rendered to a video.
    #
    # Has the shared {FileAttributes} (+name+, +size+, +bytes+, +date+, +extra+), plus the
    # snapshot count and processing state. +size+, +bytes+ and +date+ cover all the snapshots.
    #
    # @example
    #   job = Octoprint::Timelapse.get(unrendered: true).unrendered.first
    #   job.name       # => "cube_20261115"
    #   job.count      # => 342
    #   job.size       # => "12.3MB"
    #   job.processing # => false
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html#unrendered-timelapse
    class Unrendered
      include AutoInitializable
      include Deserializable
      include FileAttributes

      # @!attribute [r] count
      #   @return [Integer, nil] The number of snapshots
      auto_attr :count, type: Integer

      # @!attribute [r] recording
      #   @return [Boolean] Whether the job is still recording
      auto_attr :recording, type: Types::Boolean

      # @!attribute [r] rendering
      #   @return [Boolean] Whether the job is being rendered
      auto_attr :rendering, type: Types::Boolean

      # @!attribute [r] processing
      #   @return [Boolean] Whether the job is recording or rendering
      auto_attr :processing, type: Types::Boolean

      auto_initialize!
    end
  end
end
