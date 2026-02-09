# typed: true
# frozen_string_literal: true

require "securerandom"

module Octoprint
  # The Push Updates API provides real-time communication with OctoPrint
  # via SockJS. It allows subscribing to state updates, events, and
  # plugin messages.
  #
  # @see https://docs.octoprint.org/en/master/api/push.html OctoPrint Push Updates API Documentation
  #
  # @example Subscribe to push notifications
  #   push = Octoprint::Push.subscribe
  #   messages = push.receive
  #   push.unsubscribe
  #
  # @example Test push notification connectivity
  #   connected = Octoprint::Push.test
  #   puts connected[:version]
  class Push < BaseResource
    extend T::Sig

    resource_path("/sockjs")

    sig { returns(String) }
    attr_reader :session_id

    sig { returns(String) }
    attr_reader :server_id

    sig { params(session_id: String, server_id: String).void }
    def initialize(session_id:, server_id: "000")
      super()
      @session_id = session_id
      @server_id = server_id
    end

    # Subscribes to push notifications from the OctoPrint server.
    #
    # Opens a SockJS session, authenticates with the configured API key,
    # and sends a subscribe command with the specified filters.
    # Returns a Push instance that can be used to receive messages.
    #
    # @example Subscribe to all updates
    #   push = Octoprint::Push.subscribe
    #   messages = push.receive
    #   push.unsubscribe
    #
    # @example Subscribe to specific events only
    #   push = Octoprint::Push.subscribe(state: false, events: ["PrintDone"], plugins: false)
    #
    # @param state [Boolean, Hash] Subscribe to state updates, or a hash with log/message filters
    # @param events [Boolean, Array<String>] Subscribe to all events (true) or specific event types
    # @param plugins [Boolean, Array<String>] Subscribe to all plugins (true) or specific plugin IDs
    # @param session_id [String] SockJS session ID (auto-generated if not provided)
    # @return [Push] A push session instance for receiving messages
    # @raise [Octoprint::Exceptions::Error] if the connection fails
    sig do
      params(
        state: T.any(T::Boolean, T::Hash[Symbol, T.untyped]),
        events: T.any(T::Boolean, T::Array[String]),
        plugins: T.any(T::Boolean, T::Array[String]),
        session_id: String
      ).returns(Push)
    end
    def self.subscribe(state: true, events: true, plugins: true, session_id: SecureRandom.hex(8))
      push = new(session_id: session_id)
      push.open_session
      push.authenticate
      push.receive # Consume initial connected message
      push.send_subscribe(state: state, events: events, plugins: plugins)
      push
    end

    # Unsubscribes from push notifications.
    #
    # Sends an empty subscribe command to stop receiving all message types.
    #
    # @example Unsubscribe from push notifications
    #   push = Octoprint::Push.subscribe
    #   push.unsubscribe
    #
    # @return [Boolean] true on success
    sig { returns(T::Boolean) }
    def unsubscribe # rubocop:disable Naming/PredicateMethod
      send_command(subscribe: { state: false, events: false, plugins: false })
      true
    end

    # Tests push notification connectivity.
    #
    # Opens a SockJS session, authenticates, and returns the connected
    # message data from the server, which includes version information.
    #
    # @example Test connectivity
    #   connected = Octoprint::Push.test
    #   puts "OctoPrint version: #{connected[:version]}"
    #   puts "Display version: #{connected[:display_version]}"
    #
    # @param session_id [String] SockJS session ID (auto-generated if not provided)
    # @return [Hash] Connected message data including version, branch, and config hashes
    # @raise [Octoprint::Exceptions::Error] if the connection fails
    sig { params(session_id: String).returns(T::Hash[Symbol, T.untyped]) }
    def self.test(session_id: SecureRandom.hex(8))
      push = new(session_id: session_id)
      push.open_session
      push.authenticate
      messages = push.receive
      connected = messages.find { |m| m.key?(:connected) }
      connected&.fetch(:connected) || {}
    end

    # Receives the next batch of messages from the push notification stream.
    #
    # This method blocks until messages are available from the server.
    #
    # @example Receive messages
    #   push = Octoprint::Push.subscribe
    #   messages = push.receive
    #   messages.each { |msg| puts msg.keys }
    #
    # @return [Array<Hash>] Array of parsed message hashes
    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def receive
      response = faraday_client.post(session_path("xhr"))
      parse_sockjs_frame(response.body)
    end

    # Opens the SockJS session.
    #
    # @example Open a session
    #   push = Octoprint::Push.new(session_id: "abc123")
    #   push.open_session
    #
    # @return [Boolean] true if the session was opened successfully
    sig { returns(T::Boolean) }
    def open_session # rubocop:disable Naming/PredicateMethod
      response = faraday_client.post(session_path("xhr"))
      response.body.strip == "o"
    end

    # Authenticates the SockJS session with the configured API key.
    #
    # @example Authenticate
    #   push.authenticate
    #
    # @return [void]
    sig { void }
    def authenticate
      send_command(auth: "_api:#{octoprint_client.api_key}")
    end

    # Sends a subscribe command with the specified message filters.
    #
    # @example Subscribe to state and events
    #   push.send_subscribe(state: true, events: ["PrintDone"], plugins: false)
    #
    # @param state [Boolean, Hash] State update filter
    # @param events [Boolean, Array<String>] Event filter
    # @param plugins [Boolean, Array<String>] Plugin message filter
    # @return [void]
    sig do
      params(
        state: T.any(T::Boolean, T::Hash[Symbol, T.untyped]),
        events: T.any(T::Boolean, T::Array[String]),
        plugins: T.any(T::Boolean, T::Array[String])
      ).void
    end
    def send_subscribe(state: true, events: true, plugins: true)
      send_command(subscribe: { state: state, events: events, plugins: plugins })
    end

    private

    sig { returns(Faraday::Connection) }
    def faraday_client
      octoprint_client.client
    end

    sig { returns(Octoprint::Client) }
    def octoprint_client
      client = Octoprint.client
      raise "No client configured" unless client

      client
    end

    sig { params(transport: String).returns(String) }
    def session_path(transport)
      "/sockjs/#{@server_id}/#{@session_id}/#{transport}"
    end

    sig { params(message: T::Hash[Symbol, T.untyped]).void }
    def send_command(message)
      faraday_client.post(
        session_path("xhr_send"),
        [message.to_json].to_json,
        { "Content-Type" => "application/json" }
      )
    end

    sig { params(body: String).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def parse_sockjs_frame(body)
      return [] if body.empty?
      return [] unless body.start_with?("a")

      messages = JSON.parse(T.must(body[1..]))
      messages.map { |m| m.is_a?(String) ? JSON.parse(m) : m }.map { |m| deep_transform(m) }
    end

    sig { params(obj: T::Hash[String, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def deep_transform(obj)
      obj.deep_transform_keys { |key| key.underscore.to_sym }
    end
  end
end
