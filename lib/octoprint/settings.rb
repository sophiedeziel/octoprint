# typed: true
# frozen_string_literal: true

module Octoprint
  # The Settings API allows retrieval and saving of OctoPrint settings,
  # regeneration of the system-wide API key, and fetching template data.
  #
  # The settings use the OctoPrint 2.0 key names whatever the server version. With the 1.x API (the default),
  # {Settings::Legacy} renames the 1.x settings:
  #
  # | 1.x setting                         | 2.0 setting (what the gem returns)                       |
  # |-------------------------------------|----------------------------------------------------------|
  # | `serial.autoconnect`                | `printer_connection.autoconnect`                         |
  # | `serial.notify_suppressed_commands` | `feature.notify_suppressed_commands`                     |
  # | other `serial` settings             | `plugins.serial_connector` (2.0 serial connector shape)  |
  # | `feature.auto_uppercase_blacklist`  | `feature.auto_uppercase_blocklist`                       |
  # | `server.plugin_blacklist`           | `server.plugin_blocklist`                                |
  #
  # 1.x settings without a 2.0 equivalent are kept: `serial.port`, `serial.baudrate`, `serial.port_options` and
  # `serial.baudrate_options` (under `plugins.serial_connector`), `api.key` and `system.events`.
  #
  # Updates sent with {.save} use the 2.0 names too, and are renamed back for 1.x servers.
  #
  # @see https://docs.octoprint.org/en/dev/api/settings.html OctoPrint Settings API Documentation
  #
  # @example Get current settings
  #   settings = Octoprint::Settings.get
  #   puts settings[:appearance][:name]
  #
  # @example Update settings
  #   Octoprint::Settings.save(appearance: { color: "blue" })
  #
  # @example Regenerate API key
  #   new_key = Octoprint::Settings.regenerate_api_key
  #   puts "New API key: #{new_key}"
  class Settings < BaseResource
    resource_path("/api/settings")

    # Retrieves the current settings from the OctoPrint server.
    #
    # This method fetches all current OctoPrint settings. The response is returned
    # as a Hash containing the entire settings structure, with snake_case Symbol keys
    # and the OctoPrint 2.0 key names (see {Settings}).
    #
    # OctoPrint 2.0 filters the settings by the user's permissions, whatever the API version: a value
    # the user isn't allowed to read is `nil` (or `[]` for lists, `{}` for some sections). Expect nil
    # values when the API key doesn't belong to an admin. OctoPrint 1.11 returns every value.
    #
    # @example Get current settings
    #   settings = Octoprint::Settings.get
    #
    #   # Access appearance settings
    #   puts settings[:appearance][:name]
    #
    #   # Access feature flags
    #   puts settings[:feature][:temperature_graph]
    #
    # @example Read the printer connection settings (1.x `serial` settings)
    #   settings = Octoprint::Settings.get
    #   settings.dig(:printer_connection, :autoconnect)                       # => false
    #   settings.dig(:plugins, :serial_connector, :timeout, :communication)   # => 30.0
    #   settings.dig(:plugins, :serial_connector, :error_handling)            # => "disconnect"
    #
    # @example Settings hidden from a user without the SETTINGS permission (OctoPrint 2.0)
    #   settings = Octoprint::Settings.get
    #   settings.dig(:server, :online_check, :host) # => nil
    #
    # @return [Hash] The current settings as a hash
    # @raise [Octoprint::Exceptions::Error] if the request fails
    # @raise [Octoprint::Exceptions::AuthenticationError] if lacking SETTINGS_READ permission
    #: -> Hash[Symbol, untyped]
    def self.get
      fetch_resource(deserialize: false)
    end

    # Retrieves the webcam settings as a typed object.
    #
    # Handles both the multi-webcam settings shape of OctoPrint 1.9+ and the legacy
    # `webcam` keys of older versions. See {Settings::Webcam.from_settings} to build
    # it from a settings hash you already fetched.
    #
    # @example Get the webcam stream URL
    #   webcam = Octoprint::Settings.webcam
    #   puts webcam.stream_url if webcam.enabled
    #
    # @return [Settings::Webcam] The webcam settings
    # @raise [Octoprint::Exceptions::Error] if the request fails
    # @raise [Octoprint::Exceptions::AuthenticationError] if lacking SETTINGS_READ permission
    #: -> Settings::Webcam
    def self.webcam
      Webcam.from_settings(get)
    end

    # Saves settings to the OctoPrint server.
    #
    # This method updates OctoPrint settings with the provided values.
    # You can provide either a full settings object or partial updates.
    # The server will merge the provided settings with existing ones.
    #
    # The keys are sent as they are given, so spell them like the server does (camelCase, e.g.
    # `temperatureGraph`). Use the OctoPrint 2.0 names: for 1.x servers, `printerConnection.autoconnect`,
    # `plugins.serial_connector`, `feature.notifySuppressedCommands`, `feature.autoUppercaseBlocklist` and
    # `server.pluginBlocklist` are renamed to their 1.x names (see {Settings::Legacy}).
    #
    # OctoPrint 2.0 asks for a recent login before it changes some settings (see {.reauth_required}).
    #
    # @example Update appearance settings
    #   updated = Octoprint::Settings.save(
    #     appearance: {
    #       color: "blue",
    #       name: "My OctoPrint"
    #     }
    #   )
    #
    # @example Update multiple settings
    #   updated = Octoprint::Settings.save(
    #     appearance: { color: "green" },
    #     feature: { temperatureGraph: false }
    #   )
    #
    # @example Update the printer connection settings, on 1.x and 2.0 servers
    #   Octoprint::Settings.save(
    #     printerConnection: { autoconnect: true },
    #     plugins: { serial_connector: { timeout: { communication: 45 } } }
    #   )
    #
    # @param settings [Hash] The settings to update (can be partial)
    # @return [Hash] The updated settings
    # @raise [Octoprint::Exceptions::Error] if the request fails
    # @raise [Octoprint::Exceptions::AuthenticationError] if lacking SETTINGS permission
    #: (Hash[Symbol, untyped] settings) -> Hash[Symbol, untyped]
    def self.save(settings)
      post(params: settings)
    end

    # Regenerates the system-wide API key.
    #
    # This method generates a new system-wide API key. This requires admin rights.
    # Note that after calling this method, the current API key will be invalidated
    # and you'll need to use the new key for subsequent requests.
    #
    # @example Regenerate API key
    #   result = Octoprint::Settings.regenerate_api_key
    #   new_key = result[:api_key]
    #   puts "New API key: #{new_key}"
    #
    # @return [Hash] Hash containing the new API key ({ api_key: "new_key_value" })
    # @raise [Octoprint::Exceptions::Error] if the request fails
    # @raise [Octoprint::Exceptions::AuthenticationError] if lacking admin rights
    #: -> Hash[Symbol, String]
    def self.regenerate_api_key
      post(path: "/api/settings/apikey")
    end

    # Fetches template data from the OctoPrint server.
    #
    # This method retrieves template component identifiers used by OctoPrint's UI.
    # This requires admin rights and is primarily used for UI customization.
    #
    # Note: This endpoint is marked as beta in the OctoPrint API and may be subject
    # to changes in future versions.
    #
    # @example Fetch template data
    #   templates = Octoprint::Settings.fetch_templates
    #   templates.each do |component, identifiers|
    #     puts "#{component}: #{identifiers.inspect}"
    #   end
    #
    # @return [Hash] Template component identifiers
    # @raise [Octoprint::Exceptions::Error] if the request fails
    # @raise [Octoprint::Exceptions::AuthenticationError] if lacking admin rights
    #: -> Hash[Symbol, untyped]
    def self.fetch_templates
      fetch_resource("templates", deserialize: false)
    end

    # Lists the settings that need a recent login to be changed (OctoPrint 2.0 API only).
    #
    # OctoPrint 2.0 asks the user to log in again before it saves some sensitive settings (server
    # commands, system actions, webcam ffmpeg commands, event subscriptions, ...). The result mirrors the
    # settings tree, with snake_case keys like {.get}, and `true` on every setting that needs it.
    #
    # @example Check whether a setting needs a recent login
    #   requirements = Octoprint::Settings.reauth_required
    #   requirements.dig(:server, :commands) # => true
    #   requirements # => { access_control: { default_reauthentication_timeout: true },
    #                #      plugins: { eventmanager: { subscriptions: true } }, server: { commands: true }, ... }
    #
    # @return [Hash] The settings that need a recent login, as a tree of `true` leaves
    # @raise [Octoprint::Exceptions::UnsupportedFeatureError] with the 1.x API, before any request
    # @raise [Octoprint::Exceptions::Error] if the request fails
    #: -> Hash[Symbol, untyped]
    def self.reauth_required
      require_feature!(:reauth_required)
      fetch_resource("reauthReq", deserialize: false).fetch(:requirements)
    end
  end
end
