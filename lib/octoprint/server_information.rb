# frozen_string_literal: true

module Octoprint
  # Informations about the server.
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/server.html
  #
  # @attr [String] version  Server's version
  # @attr [String|nil] safemode Server's version
  #
  # @example
  #           Octoprint.configure(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
  #
  #           server = Octoprint::ServerInformation.get
  #           server.version= #=> "1.7.3"
  #           server.safemode #=> "incomplete_startup"
  class ServerInformation < BaseResource
    resource_path("/api/server")
    attr_reader :version, :safemode

    def initialize(version:, safemode:)
      @version = version
      @safemode = safemode
      super()
    end

    # Retrieve information regarding server status.
    #
    # @option options [Octoprint::Client] :client the API client to use
    # @return [ServerInformation]
    #
    # @example
    #           client = Octoprint::Client.new(host: 'https://octopi.local/', api_key: 'j98G2nsJq...')
    #
    #           server = Octoprint::ServerInformation.get(client: client)
    #           server.version= #=> "1.7.3"
    #           server.safemode #=> "incomplete_startup"
    def get(options = {})
      super(options: options)
    end
  end
end
