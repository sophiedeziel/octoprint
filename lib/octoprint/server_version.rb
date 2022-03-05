# frozen_string_literal: true

module Octoprint
  # Version informations about the server
  #
  # @attr [String] api      Server's API version
  # @attr [String] server   Server's version
  # @attr [String] text     server version including the prefix `Octoprint`
  #
  # @example
  #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #           version = Octoprint::ServerVersion.get
  #           version.api #=> "0.1"
  #           version.server= #=> "1.7.3"
  #           version.text #=> "text"
  class ServerVersion < BaseResource
    resource_path("/api/version")
    attr_reader :api, :server, :text

    def initialize(args = {})
      @api    = args["api"]
      @server = args["server"]
      @text   = args["text"]
      super()
    end

    # Retrieve information regarding server and API version.
    #
    # @option options [Octoprint::Client] :client the API client to use
    # @return [ServerVersion]
    #
    # @example
    #           version = Octoprint::ServerVersion.get
    #           version.api #=> "0.1"
    #           version.server= #=> "1.7.3"
    #           version.text #=> "text"
  end
end
