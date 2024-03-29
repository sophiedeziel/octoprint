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
      attr_reader :completion, :filepos, :print_time, :print_time_left, :print_time_left_origin

      def initialize(**kwargs)
        @completion                 = kwargs[:completion]
        @filepos                    = kwargs[:filepos]
        @print_time                 = kwargs[:print_time]
        @print_time_left            = kwargs[:print_time_left]
        @print_time_left_origin     = kwargs[:print_time_left_origin]
      end
    end
  end
end
