# frozen_string_literal: true

require_relative "octoprint/version"

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
module Octoprint
  class Error < StandardError; end

  class << self
    # Configure the API client with the server's address and key
    def configure(uri:, api_key:); end
  end
end
