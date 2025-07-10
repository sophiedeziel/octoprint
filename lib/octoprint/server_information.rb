# typed: true
# frozen_string_literal: true

module Octoprint
  # Information about the OctoPrint server.
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
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/server")

    # @!attribute [r] version
    #   @return [String] The server's version number
    auto_attr :version, type: String, nilable: false

    # @!attribute [r] safemode
    #   @return [String, nil] The server's safe mode status
    auto_attr :safemode, type: String

    # @!attribute [r] extra
    #   @return [Hash] Any additional fields returned by the API
    auto_attr :extra, type: Hash

    auto_initialize!

    # Retrieve information regarding server status.
    #
    # @example Get server information
    #   server = Octoprint::ServerInformation.get
    #   puts "Version: #{server.version}"
    #
    # @return [ServerInformation] Server information object
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { returns(ServerInformation) }
    def self.get
      fetch_resource
    end
  end
end
