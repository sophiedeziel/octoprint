# frozen_string_literal: true

module Octoprint
  # Use these operations to query the currently selected file and start/cancel/restart/pause the actual print job.
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/job.html
  #
  # @attr [String] job       Information regarding the target of the current print job
  # @attr [String] progress  Information regarding the progress of the current print job
  # @attr [String] state     A textual representation of the current state of the job or connection, e.g. “Operational”,
  #                            “Printing”, “Pausing”, “Paused”, “Cancelling”, “Error”, “Offline”, “Offline after error”,
  #                            “Opening serial connection”, … – please note that this list is not exhaustive!
  # @attr [String] error     Any error message for the job or connection, only set if there has been an error.
  #
  # @example
  #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #           job = Octoprint::Job.get
  #           job.state #=> "Printing"
  class Job < BaseResource
    resource_path("/api/job")
    attr_reader :job, :progress, :state, :error

    def initialize(job:, progress:, state:, error: nil)
      @job = job
      @progress = progress
      @state = state
      @error = error
      super()
    end

    # Retrieve information about the current job (if there is one).
    #
    # @return [Job]
    #
    # @example
    #           job = Octoprint::Job.get
    #           job.job #=> "0.1"
    #           job.server= #=> "1.7.3"
    #           job.text #=> "OctoPrint 1.7.3"
    def self.get
      fetch_resource
    end
  end
end
