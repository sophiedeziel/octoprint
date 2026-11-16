# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    class Storage
      # Converts the printer storage API to the 1.x SD card API.
      #
      # OctoPrint 1.x has no `/api/printer/storage`: the same state and commands live at `/api/printer/sd`.
      # The responses have the same shape (`{ ready: Boolean }`, or 204 No Content for commands), so only the
      # path changes.
      #
      # @example
      #   request = Octoprint::ApiRequest.new(http_method: :get, path: "/api/printer/storage")
      #   Octoprint::Printer::Storage::Legacy.to_request(request).path # => "/api/printer/sd"
      module Legacy
        extend LegacyConverter

        # Path of the printer storage API
        PATH = "/api/printer/storage"

        # Path of the same API in OctoPrint 1.x
        LEGACY_PATH = "/api/printer/sd"

        # Sends the request to `/api/printer/sd`.
        #
        # @param request [ApiRequest] The request made to `/api/printer/storage`
        # @return [ApiRequest] The same request, made to `/api/printer/sd`
        #: (ApiRequest) -> ApiRequest
        def self.to_request(request)
          return request unless request.path.start_with?(PATH)

          request.with(path: request.path.sub(PATH, LEGACY_PATH))
        end
      end
    end
  end
end
