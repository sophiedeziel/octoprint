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
  end
end
