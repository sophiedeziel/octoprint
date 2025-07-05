# typed: true
# frozen_string_literal: true

module Octoprint
  # Printer profile management for OctoPrint server configuration
  #
  # This class provides methods to manage printer profiles on the OctoPrint server.
  # Printer profiles define the physical characteristics and capabilities of 3D printers
  # including print volume, extruder configuration, heated bed capabilities, and movement speeds.
  #
  # @example List all printer profiles
  #   profiles = Octoprint::PrinterProfiles.list
  #   profiles.profiles.each do |id, profile|
  #     puts "#{profile.name}: #{profile.model} (#{profile.id})"
  #   end
  #
  # @example Get a specific printer profile
  #   profile = Octoprint::PrinterProfiles.get(identifier: "_default")
  #   puts "Volume: #{profile.volume.width}x#{profile.volume.depth}x#{profile.volume.height}mm"
  #
  # @example Create a new printer profile
  #   profile_data = {
  #     name: "My Custom Printer",
  #     model: "Custom Model",
  #     volume: { width: 200, depth: 200, height: 180 }
  #   }
  #   new_profile = Octoprint::PrinterProfiles.create(profile: profile_data)
  #
  # @example Update an existing printer profile
  #   updates = { name: "Updated Printer Name" }
  #   Octoprint::PrinterProfiles.update(identifier: "custom_printer", profile: updates)
  #
  # @example Delete a printer profile
  #   Octoprint::PrinterProfiles.delete(identifier: "old_printer")
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/1.11.2/api/printerprofiles.html
  class PrinterProfiles < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/printerprofiles")

    auto_attr :profiles, type: Hash, nilable: false
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      transform do |data|
        # Transform the hash of profile_id => profile_info into proper objects
        if data[:profiles].is_a?(Hash)
          data[:profiles] = data[:profiles].transform_values do |profile_info|
            PrinterProfile.deserialize(profile_info)
          end
        end
      end
      collect_extras
    end

    # Fetches the list of available printer profiles
    #
    # @return [PrinterProfiles]
    sig { returns(PrinterProfiles) }
    def self.list
      fetch_resource
    end

    # Fetches a specific printer profile
    #
    # @param [String] identifier    The identifier of the printer profile to retrieve
    #
    # @return [PrinterProfile]
    sig do
      params(identifier: String)
        .returns(PrinterProfile)
    end
    def self.get(identifier:)
      profile_data = fetch_resource(identifier, deserialize: false)
      PrinterProfile.deserialize(profile_data)
    end

    # Creates a new printer profile
    #
    # @param [Hash] profile         The profile data to create
    # @param [String] based_on      Optional. The identifier of the profile to base the new profile on
    #
    # @return [PrinterProfile]
    sig do
      params(profile: T::Hash[Symbol, T.untyped], based_on: T.nilable(String))
        .returns(PrinterProfile)
    end
    def self.create(profile:, based_on: nil)
      params = { profile: profile }
      params[:basedOn] = based_on if based_on

      result = post(params: params)
      # API returns the profile nested under :profile key
      profile_data = result[:profile] || result
      PrinterProfile.deserialize(profile_data)
    end

    # Updates an existing printer profile
    #
    # @param [String] identifier    The identifier of the printer profile to update
    # @param [Hash] profile         The profile data to update
    #
    # @return [PrinterProfile]
    sig do
      params(identifier: String, profile: T::Hash[Symbol, T.untyped])
        .returns(PrinterProfile)
    end
    def self.update(identifier:, profile:)
      path = [@path, identifier].compact.join("/")
      result = patch(path: path, params: { profile: profile })
      # API returns the profile nested under :profile key
      profile_data = result[:profile] || result
      PrinterProfile.deserialize(profile_data)
    end

    # Deletes a printer profile
    #
    # @param [String] identifier    The identifier of the printer profile to delete
    #
    # @return [T.untyped] 204 No Content on success
    sig do
      params(identifier: String)
        .returns(T.untyped)
    end
    def self.delete_profile(identifier:)
      path = [@path, identifier].compact.join("/")
      delete(path: path)
    end

    class << self
      private

      # Sends a PATCH request to the resource's endpoint.
      #
      # @param [String] path      the path of the patch request
      # @param [Hash] params      parameters to the request
      # @param [Hash] headers     headers to the request
      # @param [Hash] options     options
      # @return [Object]
      sig do
        params(
          path: String,
          params: T::Hash[Symbol, T.untyped],
          headers: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, T.untyped]
        )
          .returns(T.untyped)
      end
      def patch(path: @path, params: {}, headers: {}, options: {})
        client.request(
          path,
          http_method: :patch,
          body: params,
          headers: headers,
          options: options
        )
      end
    end
  end
end
