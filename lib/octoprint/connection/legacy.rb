# typed: true
# frozen_string_literal: true

module Octoprint
  class Connection
    # Converts the 1.x connection API to the OctoPrint 2.0 shapes. See {LegacyConverter}.
    #
    # - `GET /api/connection`: the old `port` and `baudrate` become the `serial` connector and its parameters,
    #   and the old `ports`, `baudrates` and preferences become a single `serial` entry in `options.connectors`.
    # - `connect`: the `serial` connector's `parameters` are sent as the old `port` and `baudrate`.
    # - `repair` is sent as the old `fake_ack`.
    module Legacy
      extend LegacyConverter

      # Name of the serial connector in the 2.0 API, which 1.x doesn't report
      SERIAL_NAME = "Serial Connection"

      class << self
        # @param request [ApiRequest] The 2.0-style request
        # @return [ApiRequest] The 1.x request
        #: (ApiRequest) -> ApiRequest
        def to_request(request)
          body = request.body
          return request if body.nil?

          case body[:command]
          when "connect" then request.with(body: legacy_connect(body))
          when "repair" then request.with(body: body.merge(command: "fake_ack"))
          else request
          end
        end

        # @param response [Object] The parsed 1.x response
        # @param request [ApiRequest] The 2.0-style request
        # @return [Object] The response in the 2.0 shape
        #: (untyped, ApiRequest) -> untyped
        def from_response(response, request)
          return response unless request.http_method == :get && response.is_a?(Hash)

          {
            current: current(response.fetch(:current, {})),
            options: options(response.fetch(:options, {}))
          }
        end

        private

        #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def legacy_connect(body)
          parameters = body[:parameters] || {}
          body.except(:connector, :parameters).merge(parameters.slice(:port, :baudrate))
        end

        #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def current(current)
          parameters = current.slice(:port, :baudrate).compact
          {
            state: current[:state],
            connector: parameters.empty? ? nil : SERIAL,
            parameters: parameters,
            capabilities: nil,
            profile: current[:printer_profile]
          }
        end

        #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def options(options)
          {
            connectors: [
              { connector: SERIAL, name: SERIAL_NAME,
                parameters: { port: options[:ports] || [], baudrate: options[:baudrates] || [] } }
            ],
            preferred_connector: {
              connector: SERIAL,
              parameters: { port: options[:port_preference], baudrate: options[:baudrate_preference] }
            },
            preferred_profile: options[:printer_profile_preference],
            profiles: options[:printer_profiles] || [],
            autoconnect: options[:autoconnect]
          }
        end
      end
    end
  end
end
