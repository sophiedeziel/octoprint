# frozen_string_literal: true

require_relative "octoprint/version"
require "octoprint/client"
require "octoprint/errors"

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
# @attr [Octoprint::Client] client      The configured API client
module Octoprint
  class << self
    attr_reader :client

    # Configure the API client with the server's address and key
    #
    # @param [String] host      Server's API version
    # @param [String] api_key   Server's version
    # @return [true]
    def configure(host:, api_key:)
      @client = Client.new(host: host, api_key: api_key)

      true
    end
  end
end
