# frozen_string_literal: true

require "active_support/all"
require "pry"

require_relative "octoprint/version"
require "octoprint/client"
require "octoprint/base_resource"
require "octoprint/connection"
require "octoprint/connection/settings"
require "octoprint/connection/options"
require "octoprint/errors"
require "octoprint/server_information"
require "octoprint/server_version"

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
# @attr [Octoprint::Client] client      The configured API client
module Octoprint
  class << self
    # Configure the API client with the server's address and key
    #
    # @param [String] host      Server's API version
    # @param [String] api_key   Server's version
    # @return [true]
    def configure(host:, api_key:)
      self.client = Client.new(host: host, api_key: api_key)

      true
    end

    def client
      Thread.current[:client]
    end

    def client=(client)
      Thread.current[:client] = client
    end
  end
end
