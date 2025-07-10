# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the progress of the current print job.
    #
    # @example Access job progress
    #   job = Octoprint::Job.get
    #   progress = job.progress
    #   puts "Completion: #{progress.completion * 100}%"
    #   puts "Time left: #{progress.print_time_left} seconds"
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#progress-information
    class Progress
      extend T::Sig
      include AutoInitializable
      include Deserializable

      # @!attribute [r] completion
      #   @return [Float] The completion percentage of the current print job
      auto_attr :completion, type: Float

      # @!attribute [r] filepos
      #   @return [Integer] Current position in the file being printed, in bytes
      auto_attr :filepos, type: Integer

      # @!attribute [r] print_time
      #   @return [Float] Time already spent printing, in seconds
      auto_attr :print_time, type: Float

      # @!attribute [r] print_time_left
      #   @return [Float] Estimate of time left to print, in seconds
      auto_attr :print_time_left, type: Float

      # @!attribute [r] print_time_left_origin
      #   @return [String] Origin of the current time left estimate
      auto_attr :print_time_left_origin, type: String

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
