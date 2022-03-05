# frozen_string_literal: true

require "faraday"
require "pry"

module Octoprint
  # The API client object
  #
  # @attr [String] uri
  # @attr [String] api_key
  class Client
    attr_reader :host, :api_key, :client

    def initialize(host:, api_key:)
      raise MissingCredentials if host.nil? || api_key.nil?

      @host    = host
      @api_key = api_key
      @client = Faraday.new(host) do |client|
        client.headers["Authorization"] = "Bearer #{api_key}" unless api_key.nil?
      end
    end

    def request(path, http_method: :get, params: {})
      response = client.public_send(http_method, path, **params)

      raise AuthenticationError if response.status == 403

      JSON.parse(response.body)
    end
  end
end
