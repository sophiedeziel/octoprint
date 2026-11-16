# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Converts the 1.x printer state API to the 2.0 shape.
    #
    # OctoPrint 2.0 renamed the printer's SD card to printer storage. The 1.x API (and OctoPrint 2.0 without the
    # version header) calls it `sd`, both in the response of `GET /api/printer` and in its `exclude` parameter:
    #
    # - {.to_request} excludes `sd` when the request excludes `storage`
    # - {.from_response} renames the `sd` key of the response to `storage`
    #
    # @example
    #   Octoprint::Printer::Legacy.from_response({ sd: { ready: true } }, request) # => { storage: { ready: true } }
    module Legacy
      extend LegacyConverter

      # Fields of the printer state renamed by the 2.0 API: 2.0 name => 1.x name
      LEGACY_FIELDS = { "storage" => "sd" }.freeze

      # Keys of the 1.x printer state renamed by the 2.0 API: 1.x key => 2.0 key
      RESPONSE_KEYS = LEGACY_FIELDS.to_h { |field, legacy_field| [legacy_field.to_sym, field.to_sym] }.freeze

      # Excludes `sd` instead of `storage`.
      #
      # @example
      #   request = Octoprint::ApiRequest.new(http_method: :get, path: "/api/printer",
      #                                       query: { exclude: "temperature,storage" })
      #   Octoprint::Printer::Legacy.to_request(request).query # => { exclude: "temperature,sd" }
      #
      # @param request [ApiRequest] The request with 2.0 field names
      # @return [ApiRequest] The request with 1.x field names
      #: (ApiRequest) -> ApiRequest
      def self.to_request(request)
        exclude = request.query[:exclude]
        return request unless exclude.is_a?(String)

        fields = exclude.split(",").map { |field| LEGACY_FIELDS.fetch(field, field) }
        request.with(query: request.query.merge(exclude: fields.join(",")))
      end

      # Renames the `sd` key of the printer state to `storage`.
      #
      # @param response [Object] The parsed 1.x printer state
      # @param _request [ApiRequest] The request with 2.0 field names
      # @return [Object] The printer state with 2.0 field names
      #: (untyped, ApiRequest) -> untyped
      def self.from_response(response, _request)
        return response unless response.is_a?(Hash)

        response.to_h { |key, value| [RESPONSE_KEYS.fetch(key, key), value] }
      end
    end
  end
end
