# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Converts the 1.x Files API to the 2.0 shapes. See {LegacyConverter}.
    #
    # Requests:
    # - The `printer` storage is called `sdcard` in 1.x: `/api/files/printer/...` is sent as `/api/files/sdcard/...`.
    #
    # Responses:
    # - `origin: "sdcard"`, `sdcard` keys and `/files/sdcard/` in `refs` URLs become `printer`.
    # - `GET /api/files` (`{files, free, total}`) is split by origin into storages:
    #   `{local: {key, files, usage: {free, total}}, printer: {key, files}}`. `printer` is only there when it has files.
    # - `GET /api/files/<storage>` (`{files, free, total}`) becomes `{key, files, usage: {free, total}}`.
    # - An upload's `files: {local: {...}}` becomes `file: {...}`, the entry of the storage it was uploaded to.
    #
    # The 1.x API has no storage `name` or `capabilities`: they stay nil.
    #
    # @note OctoPrint 2.0 answers 404 to `/api/files/sdcard` even without the API version header, and OctoPrint 1.11
    #   answers 404 to `/api/files/printer`. A client pinned to the 1.11 API (the default) can't tell them apart, so
    #   it uses the 1.11 path. Use `api_version: :auto` or `"2.0"` to reach the printer's storage on an OctoPrint 2.0
    #   server. The local storage works with every combination.
    module Legacy
      extend LegacyConverter

      # Path of the Files API, before the storage
      FILES_PATH = "/api/files"

      # Name of the printer's storage in the 1.x API
      LEGACY_PRINTER = Location::LEGACY_PRINTER

      # Name of the printer's storage in the 2.0 API
      PRINTER = Location::Printer.serialize

      # A printer storage segment in a 2.0-style path: /api/files/printer, /api/files/printer/...
      PRINTER_PATH = %r{\A#{FILES_PATH}/#{PRINTER}(?=/|\z)}

      # A printer storage segment in a 1.x URL: .../files/sdcard/... (refs.resource, refs.download)
      LEGACY_PRINTER_URL = %r{/files/#{LEGACY_PRINTER}(?=/|\z)}

      class << self
        # Sends the `printer` storage as `sdcard`
        #
        # @param request [ApiRequest]
        # @return [ApiRequest]
        #: (ApiRequest) -> ApiRequest
        def to_request(request)
          return request unless request.path.match?(PRINTER_PATH)

          request.with(path: request.path.sub(PRINTER_PATH, "#{FILES_PATH}/#{LEGACY_PRINTER}"))
        end

        # Renames `sdcard` to `printer`, and reshapes listings and upload results
        #
        # @param response [Object] The parsed 1.x response
        # @param request [ApiRequest] The 2.0-style request
        # @return [Object]
        #: (untyped, ApiRequest) -> untyped
        def from_response(response, request)
          response = rename_printer(response)
          return response unless response.is_a?(Hash)
          return storages(response) if request.http_method == :get && request.path == FILES_PATH

          storage = storage_of(request)
          return response unless storage

          reshape_storage_response(request.http_method, storage, response)
        end

        private

        # Reshapes a response to a request on a whole storage: a listing or an upload
        #
        #: (Symbol, String, Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def reshape_storage_response(http_method, storage, response)
          return storage_data(storage, response) if http_method == :get
          return upload_result(storage, response) if http_method == :post && response[:files].is_a?(Hash)

          response
        end

        # The storage of a request on a whole storage (`/api/files/<storage>`), nil for a file or folder
        #
        #: (ApiRequest) -> String?
        def storage_of(request)
          request.path[%r{\A#{FILES_PATH}/([^/]+)/?\z}, 1]
        end

        # Renames the 1.x printer storage everywhere in a response
        #
        #: (untyped) -> untyped
        def rename_printer(value)
          case value
          when Hash
            value.to_h do |key, item|
              [key == LEGACY_PRINTER.to_sym ? PRINTER.to_sym : key, rename_printer_value(key, item)]
            end
          when Array then value.map { |item| rename_printer(item) }
          else value
          end
        end

        #: (Symbol, untyped) -> untyped
        def rename_printer_value(key, value)
          return PRINTER if key == :origin && value == LEGACY_PRINTER
          return rename_printer(value) unless key == :refs && value.is_a?(Hash)

          value.transform_values do |url|
            url.is_a?(String) ? url.sub(LEGACY_PRINTER_URL, "/files/#{PRINTER}") : url
          end
        end

        # `{files, free, total}` for every storage, split by origin
        #
        #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def storages(response)
          files = Array(response[:files])
          by_origin = files.group_by { |file| file[:origin] || Location::Local.serialize }
          by_origin[Location::Local.serialize] ||= []

          by_origin.to_h do |origin, origin_files|
            usage = origin == Location::Local.serialize ? response.slice(:free, :total) : {}
            [origin.to_sym, storage_data(origin, usage.merge(files: origin_files))]
          end
        end

        # One storage's `{files, free, total}`
        #
        #: (String, Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def storage_data(storage, response)
          usage = response.slice(:free, :total).compact
          data = response.except(:free, :total).merge(key: storage)
          data[:usage] = usage unless usage.empty?
          data
        end

        # `files: {<storage>: entry}` becomes `file: entry`
        #
        #: (String, Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
        def upload_result(storage, response)
          files = response[:files]
          file = files.fetch(storage.to_sym) { files.values.first }
          response.except(:files).merge(file: file)
        end
      end
    end
  end
end
