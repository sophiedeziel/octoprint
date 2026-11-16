# typed: true
# frozen_string_literal: true

module Octoprint
  # Base for the converters that let a resource speak the 1.x API with 2.0-shaped models.
  #
  # The gem's models follow the OctoPrint 2.0 response shapes. When a client uses the 1.x API
  # (`api_version: "1.11"`, the default, or `:auto` against a 1.x server), a resource whose 1.x requests or
  # responses differ converts them with a converter named `Legacy`, nested in the resource and stored next to it:
  #
  #   lib/octoprint/connection.rb          -> Octoprint::Connection
  #   lib/octoprint/connection/legacy.rb   -> Octoprint::Connection::Legacy
  #
  # {BaseResource} finds the converter by name (it isn't inherited by subclasses), so adding one doesn't touch
  # BaseResource. Extend this module and override what differs: both methods default to returning their input.
  #
  # - {#to_request} gets the 2.0-style {ApiRequest} the resource built and returns the 1.x request to send
  #   (another path, renamed body keys or query parameters, ...)
  # - {#from_response} gets the parsed 1.x response and the original 2.0-style request, and returns the response
  #   in the 2.0 shape the model deserializes. A `204 No Content` response is `true`.
  #
  # Converters only run for requests made through {BaseResource.fetch_resource}, {BaseResource.post},
  # {BaseResource.put}, {BaseResource.patch} and {BaseResource.delete}.
  #
  # @example lib/octoprint/connection/legacy.rb
  #   module Octoprint
  #     class Connection
  #       # Converts the 1.x connection API to the 2.0 shapes
  #       module Legacy
  #         extend LegacyConverter
  #
  #         def self.to_request(request)
  #           return request unless request.body&.dig(:command) == "repair"
  #
  #           request.with(body: request.body.merge(command: "fake_ack"))
  #         end
  #
  #         def self.from_response(response, request)
  #           return response unless request.http_method == :get
  #
  #           # reshape { current: { port:, baudrate: } } into { current: { connector:, parameters: } }
  #           response
  #         end
  #       end
  #     end
  #   end
  module LegacyConverter
    # Converts a 2.0-style request to the 1.x API. Returns it unchanged by default.
    #
    # @param request [ApiRequest] The request the resource built
    # @return [ApiRequest] The request to send
    #: (ApiRequest) -> ApiRequest
    def to_request(request)
      request
    end

    # Converts a parsed 1.x response to the 2.0 shape. Returns it unchanged by default.
    #
    # @param response [Object] The parsed response (`true` for 204 No Content)
    # @param _request [ApiRequest] The 2.0-style request the resource built, before {#to_request}
    # @return [Object] The response in the 2.0 shape
    #: (untyped, ApiRequest) -> untyped
    def from_response(response, _request)
      response
    end
  end
end
