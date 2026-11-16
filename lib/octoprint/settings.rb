# typed: true
# frozen_string_literal: true

module Octoprint
  # The Settings API allows retrieval and saving of OctoPrint settings,
  # regeneration of the system-wide API key, and fetching template data.
  #
  # @see https://docs.octoprint.org/en/1.11.2/api/settings.html OctoPrint Settings API Documentation
  #
  # @example Get current settings
  #   settings = Octoprint::Settings.get
  #   puts settings[:appearance][:name]
  #
  # @example Update settings
  #   Octoprint::Settings.save(appearance: { color: "blue" })
  #
  # @example Regenerate the global API key (deprecated, removed in OctoPrint 2.1)
  #   new_key = Octoprint::Settings.regenerate_api_key[:apikey]
  #   puts "New API key: #{new_key}"
  class Settings < BaseResource
    resource_path("/api/settings")

    # Retrieves the current settings from the OctoPrint server.
    #
    # This method fetches all current OctoPrint settings. The response is returned
    # as a Hash containing the entire settings structure.
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
    #     feature: { temperature_graph: false }
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
    # The global API key is deprecated: OctoPrint 2.0 no longer generates one at startup (the `api.key`
    # setting may be empty) and OctoPrint 2.1 removes it. Authenticate with a user or application key
    # instead (see {Access::Users.generate_api_key}).
    #
    # @deprecated The global API key stops working in OctoPrint 2.1. Use a user or application API key.
    #
    # @example Regenerate API key
    #   result = Octoprint::Settings.regenerate_api_key
    #   new_key = result[:apikey]
    #   puts "New API key: #{new_key}"
    #
    # @return [Hash] Hash containing the new API key ({ apikey: "new_key_value" })
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
  end
end
