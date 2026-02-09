# typed: true
# frozen_string_literal: true

module Octoprint
  # Information about the current print job.
  #
  # @example Get current job
  #   job = Octoprint::Job.get
  #   puts "State: #{job.state}"
  #   puts "Progress: #{job.progress.percent}%"
  #
  # @see https://docs.octoprint.org/en/master/api/job.html
  class Job < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/job")

    # @!attribute [r] information
    #   @return [Job::Information] Information about the target file
    auto_attr :information, type: Information

    # @!attribute [r] progress
    #   @return [Job::Progress] Information about print progress
    auto_attr :progress, type: Progress

    # @!attribute [r] state
    #   @return [String] Current state of the job
    auto_attr :state, type: String

    # @!attribute [r] error
    #   @return [String, nil] Error message if any
    auto_attr :error, type: String

    # @!attribute [r] extra
    #   @return [Hash] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      transform do |data|
        data[:information] = Information.deserialize(data[:job])
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
    sig { returns(Job) }
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
    sig { params(command: String, options: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
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
    sig { returns(T.untyped) }
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
    sig { returns(T.untyped) }
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
    sig { returns(T.untyped) }
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
    sig { returns(T.untyped) }
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
    sig { returns(T.untyped) }
    def self.resume
      issue_command(command: "pause", options: { action: "resume" })
    end
  end
end
