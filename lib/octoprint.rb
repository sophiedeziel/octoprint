# frozen_string_literal: true

require_relative "octoprint/version"
require "octoprint/client"

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
module Octoprint
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class MissingCredentials < Error; end

  class << self
    attr_reader :client

    # Configure the API client with the server's address and key
    def configure(host:, api_key:)
      @client = Client.new(host: host, api_key: api_key)

      true
    end
  end
end
