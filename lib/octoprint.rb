# typed: true
# frozen_string_literal: true

require "active_support/all"
require "zeitwerk"
require "sorbet-runtime"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/tapioca")
loader.setup

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
# @attr [Octoprint::Client] client      The configured API client
module Octoprint
  class << self
    # Configure the API client with the server's address and key
    #
    # @example
    #   Octoprint.configure(host: "http://octopi.local", api_key: "key", open_timeout: 2, timeout: 3)
    #
    # @example Use the OctoPrint 2.0 API
    #   Octoprint.configure(host: "http://octopi.local", api_key: "key", api_version: "2.0")
    #
    # @param [String] host                  Server's host address
    # @param [String] api_key               Server's API key
    # @param [Numeric, nil] open_timeout    Seconds to wait for the connection to open. nil falls back to `timeout`
    # @param [Numeric, nil] timeout         Seconds to wait for a read or a write. nil: adapter default (60s)
    # @param [String, Symbol] api_version   `"1.11"` (default), `"2.0"` or `:auto`. See {ApiVersion}
    # @return [nil]
    # @raise [ArgumentError] if api_version isn't one of the accepted values
    #: (
    #|   host: String,
    #|   api_key: String,
    #|   ?open_timeout: Numeric?,
    #|   ?timeout: Numeric?,
    #|   ?api_version: (String | Symbol)
    #| ) -> void
    def configure(host:, api_key:, open_timeout: Client::DEFAULT_OPEN_TIMEOUT, timeout: Client::DEFAULT_TIMEOUT,
                  api_version: ApiVersion::DEFAULT)
      self.client = Client.new(host: host, api_key: api_key, open_timeout: open_timeout, timeout: timeout,
                               api_version: api_version)

      nil
    end

    # The API client used for the requests
    # @return [Client, nil]
    #: -> Client?
    def client
      Thread.current[:client]
    end

    # Sets the API client used for the requests
    # @param [Client] client
    def client=(client)
      Thread.current[:client] = client
    end
  end

  # Alias for backward compatibility
  # @deprecated Use Octoprint::Access::User instead
  User = Access::User
end
