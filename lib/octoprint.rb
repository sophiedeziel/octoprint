# typed: true
# frozen_string_literal: true

require "active_support/all"
require "pry"
require "zeitwerk"
require "sorbet-runtime"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/tapioca")
loader.setup

# Load Tapioca compiler if available
require_relative "tapioca/dsl/compilers/auto_initializable" if defined?(Tapioca)

# Welcome to the Octoprint Gem!
#
# This gem is still under development.
# @attr [Octoprint::Client] client      The configured API client
module Octoprint
  class << self
    extend T::Sig
    # Configure the API client with the server's address and key
    #
    # @param [String] host      Server's API version
    # @param [String] api_key   Server's version
    # @return [true]
    sig { params(host: String, api_key: String).void }
    def configure(host:, api_key:)
      self.client = Client.new(host: host, api_key: api_key)

      nil
    end

    # The API client used for the requests
    # @returns [Client]
    sig { returns(T.nilable(Client)) }
    def client
      Thread.current[:client]
    end

    # Sets the API client used for the requests
    # @param [Client] client
    def client=(client)
      Thread.current[:client] = client
    end
  end
end
