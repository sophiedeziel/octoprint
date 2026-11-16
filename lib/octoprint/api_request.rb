# typed: true
# frozen_string_literal: true

module Octoprint
  # One API call made by a resource, before it is sent.
  #
  # Resources build these through {BaseResource.fetch_resource}, {BaseResource.post} and friends. A resource's
  # legacy converter (see {LegacyConverter}) receives it and can return a modified copy with `#with`.
  #
  # @example Rename a body key for the 1.x API
  #   request.with(body: request.body.merge(command: "fake_ack"))
  #
  # @!attribute [r] http_method
  #   @return [Symbol] `:get`, `:post`, `:put`, `:patch` or `:delete`
  # @!attribute [r] path
  #   @return [String] The path, without the query string
  # @!attribute [r] query
  #   @return [Hash{Symbol => Object}] Query parameters
  # @!attribute [r] body
  #   @return [Hash{Symbol => Object}, nil] Request body
  # @!attribute [r] headers
  #   @return [Hash{Symbol => Object}] Extra request headers
  # @!attribute [r] options
  #   @return [Hash{Symbol => Object}] Client options, e.g. `force_multipart`
  class ApiRequest
    #: Symbol
    attr_reader :http_method

    #: String
    attr_reader :path

    #: Hash[Symbol, untyped]
    attr_reader :query

    #: Hash[Symbol, untyped]?
    attr_reader :body

    #: Hash[Symbol, untyped]
    attr_reader :headers

    #: Hash[Symbol, untyped]
    attr_reader :options

    # @param http_method [Symbol]
    # @param path [String]
    # @param query [Hash{Symbol => Object}]
    # @param body [Hash{Symbol => Object}, nil]
    # @param headers [Hash{Symbol => Object}]
    # @param options [Hash{Symbol => Object}]
    #: (
    #|   http_method: Symbol,
    #|   path: String,
    #|   ?query: Hash[Symbol, untyped],
    #|   ?body: Hash[Symbol, untyped]?,
    #|   ?headers: Hash[Symbol, untyped],
    #|   ?options: Hash[Symbol, untyped]
    #| ) -> void
    def initialize(http_method:, path:, query: {}, body: nil, headers: {}, options: {})
      @http_method = http_method
      @path = path
      @query = query
      @body = body
      @headers = headers
      @options = options
      freeze
    end

    # A copy of the request with some attributes changed
    #
    # @example
    #   request.with(path: "/api/printer/sd")
    #
    # @param changes [Hash{Symbol => Object}] New values, by attribute name
    # @return [ApiRequest]
    # @raise [ArgumentError] for an unknown attribute
    #: (**untyped) -> ApiRequest
    def with(**changes)
      T.unsafe(self.class).new(**to_h, **changes)
    end

    # The request's attributes
    #
    # @return [Hash{Symbol => Object}]
    #: -> Hash[Symbol, untyped]
    def to_h
      { http_method: http_method, path: path, query: query, body: body, headers: headers, options: options }
    end

    # Two requests are equal when all their attributes are
    #
    # @param other [Object]
    # @return [Boolean]
    #: (untyped) -> bool
    def eql?(other) = self == other

    # Hash code, consistent with {#eql?}
    #
    # @return [Integer]
    #: -> Integer
    def hash = to_h.hash

    # Two requests are equal when all their attributes are
    #
    # @param other [Object]
    # @return [Boolean]
    #: (untyped) -> bool
    def ==(other)
      return false unless other.is_a?(ApiRequest)

      other.to_h == to_h
    end

    # The path with the query string, as sent to the server
    #
    # @return [String]
    #: -> String
    def full_path
      return path if query.empty?

      "#{path}?#{Faraday::Utils.build_query(query)}"
    end
  end
end
