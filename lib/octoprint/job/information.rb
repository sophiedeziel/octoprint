# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the target of the current print job.
    #
    # Octoprint's API doc: https://docs.octoprint.org/en/master/api/datamodel.html#sec-api-datamodel-jobs-job
    #
    # @attr [Hash]        file                    The file that is the target of the current print job
    # @attr [Float | nil] estimated_print_time    The estimated print time for the file, in seconds.
    # @attr [Float | nil] last_print_time         The print time of the last print of the file, in seconds.
    # @attr [Hash | nil]  filament                Information regarding the estimated filament usage of the print job
    #
    # @example
    #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           options = Octoprint::Job.get.information
    #
    #           options.file #=> "whistle_v2.gcode"
    #           options.estimated_print_time #=>  8811
    #           options.last_print_time #=>  nil
    #           options.filament #=>  {tool0: {length: 810, volume: 5.36}}
    class Information
      include AutoInitializable

      auto_attr :file, type: Hash
      auto_attr :estimated_print_time, type: Float
      auto_attr :last_print_time, type: Float
      auto_attr :filament, type: Hash

      auto_initialize!
    end
  end
end
