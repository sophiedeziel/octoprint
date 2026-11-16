# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Information regarding the target of the current print job.
    #
    # The attributes follow the OctoPrint 2.0 shape on every server: a field the server leaves out (or sends as
    # `null` on 1.x) is `nil`.
    #
    # @example Access job information
    #   job = Octoprint::Job.get
    #   info = job.information
    #   puts "File: #{info.file.display_name}"
    #   puts "Estimated time: #{info.estimated_print_time} seconds"
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#sec-api-datamodel-jobs-job
    class Information
      include AutoInitializable
      include Deserializable

      # @!attribute [r] file
      #   @return [Job::File, nil] The file that is the target of the current print job. Its attributes are
      #     `nil` when no file is selected.
      auto_attr :file, type: Job::File

      # @!attribute [r] estimated_print_time
      #   @return [Float, nil] The estimated print time for the file, in seconds
      auto_attr :estimated_print_time, type: Types::NilableFloat

      # @!attribute [r] last_print_time
      #   @return [Float, nil] The print time of the last successful print of the file, in seconds.
      #     Only filled in by 1.x servers (1.11.8 takes it from the file's print statistics). OctoPrint 2.0
      #     dropped it from the job information, so it's always `nil` on 2.0 servers, whatever the API version.
      auto_attr :last_print_time, type: Types::NilableFloat

      # @!attribute [r] average_print_time
      #   @return [Float, nil] The average print time of the successful prints of the file, in seconds.
      #     Like {#last_print_time}, only filled in by 1.x servers and always `nil` on 2.0 servers.
      auto_attr :average_print_time, type: Types::NilableFloat

      # @!attribute [r] filament
      #   @return [Hash, nil] Information regarding the estimated filament usage, per tool
      #     (e.g. `{ tool0: { length: 60.0, volume: 0.0 } }`). Empty or `nil` when no file is selected.
      auto_attr :filament, type: Types::NilableHash

      # @!attribute [r] user
      #   @return [String, nil] The user who started the current job
      auto_attr :user, type: String

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        nested :file, Job::File
      end
    end
  end
end
