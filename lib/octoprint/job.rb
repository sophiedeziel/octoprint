# typed: true
# frozen_string_literal: true

module Octoprint
  # Information about the current print job.
  #
  # The model follows the OctoPrint 2.0 response shape whatever the server version: fields the server leaves
  # out are `nil`. With the 1.x API, {Job::Legacy} drops the `null` fields of the 1.x response the same way.
  #
  # @example Get current job
  #   job = Octoprint::Job.get
  #   puts "State: #{job.state}"
  #   puts "File: #{job.information.file.display_name}"
  #   puts "Progress: #{job.progress.completion}%"
  #
  # @see https://docs.octoprint.org/en/master/api/job.html
  class Job < BaseResource
    include AutoInitializable
    include Deserializable

    resource_path("/api/job")

    # @!attribute [r] information
    #   @return [Job::Information, nil] Information about the target file (the API's `job` field)
    auto_attr :information, type: Information

    # @!attribute [r] progress
    #   @return [Job::Progress, nil] Information about print progress
    auto_attr :progress, type: Progress

    # @!attribute [r] state
    #   @return [String, nil] Current state of the job (e.g. `"Operational"`, `"Printing"`, `"Offline"`)
    auto_attr :state, type: String

    # @!attribute [r] error
    #   @return [String, nil] The error message, when the printer is in an error state. Sent by 2.0 servers only.
    auto_attr :error, type: String

    # @!attribute [r] extra
    #   @return [Hash] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      nested :progress, Progress

      transform do |data|
        job = data.delete(:job)
        data[:information] = Information.deserialize(job) if job
      end
    end

    # Retrieve information about the current job.
    #
    # @example Get current job
    #   job = Octoprint::Job.get
    #   puts "State: #{job.state}"
    #
    # @return [Job] Current job information
    # @raise [Octoprint::Exceptions::Error] if the request fails
    #: -> Job
    def self.get
      fetch_resource
    end

    # Issues a job command.
    #
    # @param command [String] The command to issue (start, cancel, restart, pause)
    # @param options [Hash] Additional command parameters
    # @option options [String] :action The action for the pause command (pause, resume, toggle)
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or job state doesn't match
    #
    # @example Start a print job
    #   Octoprint::Job.issue_command(command: "start")
    #
    # @example Pause with a specific action
    #   Octoprint::Job.issue_command(command: "pause", options: { action: "pause" })
    #: (command: String, ?options: Hash[Symbol, untyped]) -> untyped
    def self.issue_command(command:, options: {})
      params = { command: command }.merge(options)
      post(params: params)
    end

    # Start printing the currently selected file.
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or no file is selected
    #
    # @example
    #   Octoprint::Job.start
    #: -> untyped
    def self.start
      issue_command(command: "start")
    end

    # Cancel the current print job.
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or not printing
    #
    # @example
    #   Octoprint::Job.cancel
    #: -> untyped
    def self.cancel
      issue_command(command: "cancel")
    end

    # Restart the current print job from the beginning. Requires the job to be paused.
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or job is not paused
    #
    # @example
    #   Octoprint::Job.restart
    #: -> untyped
    def self.restart
      issue_command(command: "restart")
    end

    # Pause the current print job.
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or not printing
    #
    # @example
    #   Octoprint::Job.pause
    #: -> untyped
    def self.pause
      issue_command(command: "pause", options: { action: "pause" })
    end

    # Resume the current print job.
    #
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::ConflictError] if the printer is not operational or not paused
    #
    # @example
    #   Octoprint::Job.resume
    #: -> untyped
    def self.resume
      issue_command(command: "pause", options: { action: "resume" })
    end
  end
end
