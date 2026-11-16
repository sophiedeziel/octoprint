# typed: true
# frozen_string_literal: true

module Octoprint
  class Settings
    # Converts the 1.x settings API to the OctoPrint 2.0 key names. See {LegacyConverter}.
    #
    # Responses of `GET /api/settings` and `POST /api/settings` are renamed up to 2.0:
    # - `feature.auto_uppercase_blacklist` → `feature.auto_uppercase_blocklist`
    # - `server.plugin_blacklist` → `server.plugin_blocklist`
    # - the `serial` settings move to `printer_connection`, `feature` and `plugins.serial_connector`
    #   (see {Legacy::Serial})
    #
    # Settings updates (`POST /api/settings`) that use the 2.0 names, spelled like the server does
    # (`autoUppercaseBlocklist`, `pluginBlocklist`, `printerConnection`, ...), are renamed back to the 1.x names.
    # Keys the converter doesn't know are sent unchanged.
    module Legacy
      extend LegacyConverter

      # Settings renamed inside a section, in responses: 1.x name => 2.0 name
      RESPONSE_RENAMES = {
        feature: { auto_uppercase_blacklist: :auto_uppercase_blocklist },
        server: { plugin_blacklist: :plugin_blocklist }
      }.freeze

      # Settings renamed inside a section, in updates: 2.0 name => 1.x name, as the server spells them
      REQUEST_RENAMES = {
        feature: { autoUppercaseBlocklist: :autoUppercaseBlacklist },
        server: { pluginBlocklist: :pluginBlacklist }
      }.freeze

      SETTINGS_PATH = "/api/settings"
      private_constant :SETTINGS_PATH

      class << self
        # Renames a 2.0-style settings update to the 1.x names
        #
        # @param request [ApiRequest]
        # @return [ApiRequest]
        #: (ApiRequest) -> ApiRequest
        def to_request(request)
          body = request.body
          return request unless request.http_method == :post && request.path == SETTINGS_PATH && body

          settings = body.deep_symbolize_keys
          rename_sections(settings, REQUEST_RENAMES)
          request.with(body: Serial.to_legacy(settings))
        end

        # Renames the 1.x settings to the 2.0 names
        #
        # @param response [Object]
        # @param request [ApiRequest]
        # @return [Object]
        #: (untyped, ApiRequest) -> untyped
        def from_response(response, request)
          return response unless request.path == SETTINGS_PATH && response.is_a?(Hash)

          settings = response.deep_dup
          rename_sections(settings, RESPONSE_RENAMES)
          Serial.from_legacy(settings)
        end

        private

        #: (Hash[Symbol, untyped], Hash[Symbol, Hash[Symbol, Symbol]]) -> void
        def rename_sections(settings, renames)
          renames.each do |section, keys|
            values = settings[section]
            next unless values.is_a?(Hash)

            keys.each { |from, to| values[to] = values.delete(from) if values.key?(from) }
          end
        end
      end
    end
  end
end
