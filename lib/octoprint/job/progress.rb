# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the progress of the current print job
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/master/api/datamodel.html#progress-information
    #
    # @attr [Float] completion The completion that is the target of the current print job
    # @attr [Integer] filepos  Current position in the file being printed, in bytes from the beginning
    # @attr [Float] print_time  Time already spent printing, in seconds
    # @attr [Float] print_time_left Estimate of time left to print, in seconds
    # @attr [String] print_time_left_origin Origin of the current time left estimate.
    #
    # @example
    #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           options = Octoprint::Job.get.progress
    #
    #           options.completion #=> 0.2298468264184775
    #           options.filepos #=>  337942
    #           options.print_time #=>  276
    #           options.print_time_left #=>  912
    #           options.print_time_left_origin #=>  "estimate"
    class Progress
      include AutoInitializable

      auto_attr :completion, type: Float
      auto_attr :filepos, type: Integer
      auto_attr :print_time, type: Float
      auto_attr :print_time_left, type: Float
      auto_attr :print_time_left_origin, type: String

      auto_initialize!
    end
  end
end
