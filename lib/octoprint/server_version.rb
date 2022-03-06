# frozen_string_literal: true

module Octoprint
  # Version informations about the server
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/version.html
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
  #           version.text #=> "OctoPrint 1.7.3"
  class ServerVersion < BaseResource
    resource_path("/api/version")
    attr_reader :api, :server, :text

    def initialize(api:, server:, text:)
      @api = api
      @server = server
      @text = text
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
    #           version.text #=> "OctoPrint 1.7.3"
    def get(options = {})
      super(options: options)
    end
  end
end
