# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the target of the current print job.
    #
    # @example Access job information
    #   job = Octoprint::Job.get
    #   info = job.information
    #   puts "File: #{info.file[:name]}"
    #   puts "Estimated time: #{info.estimated_print_time} seconds"
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#sec-api-datamodel-jobs-job
    class Information
      extend T::Sig
      include AutoInitializable
      include Deserializable

      # @!attribute [r] file
      #   @return [Hash] The file that is the target of the current print job
      auto_attr :file, type: Hash

      # @!attribute [r] estimated_print_time
      #   @return [Float, nil] The estimated print time for the file, in seconds
      auto_attr :estimated_print_time, type: Types::NilableFloat

      # @!attribute [r] last_print_time
      #   @return [Float, nil] The print time of the last print of the file, in seconds
      auto_attr :last_print_time, type: Types::NilableFloat

      # @!attribute [r] filament
      #   @return [Hash, nil] Information regarding the estimated filament usage
      auto_attr :filament, type: Types::NilableHash

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
