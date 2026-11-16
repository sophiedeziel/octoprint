# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the progress of the current print job.
    #
    # Every attribute is `nil` when no job is running: OctoPrint 2.0 leaves out empty fields, and the 1.x
    # responses are converted the same way (see {Job::Legacy}).
    #
    # @example Access job progress
    #   job = Octoprint::Job.get
    #   progress = job.progress
    #   puts "Completion: #{progress.completion}%"
    #   puts "Time left: #{progress.print_time_left} seconds"
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#progress-information
    class Progress
      include AutoInitializable
      include Deserializable

      # @!attribute [r] completion
      #   @return [Float, nil] The completion percentage of the current print job, from 0 to 100
      auto_attr :completion, type: Float

      # @!attribute [r] filepos
      #   @return [Integer, nil] Current position in the file being printed, in bytes
      auto_attr :filepos, type: Integer

      # @!attribute [r] print_time
      #   @return [Integer, nil] Time already spent printing, in seconds
      auto_attr :print_time, type: Integer

      # @!attribute [r] print_time_left
      #   @return [Integer, nil] Estimate of time left to print, in seconds
      auto_attr :print_time_left, type: Integer

      # @!attribute [r] print_time_left_origin
      #   @return [String, nil] Origin of the current time left estimate (e.g. `"analysis"`, `"average"`,
      #     `"linear"`, `"estimate"`)
      auto_attr :print_time_left_origin, type: String

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
