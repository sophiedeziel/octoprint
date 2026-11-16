# typed: true
# frozen_string_literal: true

require "erb"

module Octoprint
  # Slicers and slicing profiles of the OctoPrint server.
  #
  # Slicers are provided by plugins (for example the CuraEngine Legacy plugin, with the
  # slicer key +curalegacy+). Each slicer has its own set of slicing profiles, and the content
  # of a profile's {Slicing::Profile#data data} depends on the slicer.
  #
  # Listing requires the +SLICE+ permission. Adding, updating and deleting profiles
  # requires the +SETTINGS+ permission.
  #
  # To slice a file, see {Files.slice}.
  #
  # @example List all slicers and their profiles
  #   Octoprint::Slicing.list.each_value do |slicer|
  #     puts "#{slicer.display_name} (configured: #{slicer.configured?})"
  #     slicer.profiles.each_value { |profile| puts "  - #{profile.display_name}" }
  #   end
  #
  # @example List the profiles of a slicer
  #   profiles = Octoprint::Slicing.profiles(slicer: "curalegacy")
  #   profiles.keys # => [:high_quality, :normal_quality]
  #
  # @example Retrieve a profile with its data
  #   profile = Octoprint::Slicing.get_profile(slicer: "curalegacy", key: "high_quality")
  #   profile.data[:layer_height] # => 0.1
  #
  # @example Add, update and delete a profile
  #   Octoprint::Slicing.add_profile(
  #     slicer: "curalegacy",
  #     key: "draft",
  #     display_name: "Draft",
  #     description: "Fast and ugly",
  #     data: { layer_height: 0.3 }
  #   )
  #   Octoprint::Slicing.update_profile(slicer: "curalegacy", key: "draft", default: true)
  #   Octoprint::Slicing.delete_profile(slicer: "curalegacy", key: "draft")
  #
  # @see https://docs.octoprint.org/en/1.11.2/api/slicing.html OctoPrint Slicing API Documentation
  class Slicing < BaseResource
    resource_path("/api/slicing")

    class << self
      # Lists all slicers and their slicing profiles.
      #
      # @example
      #   slicers = Octoprint::Slicing.list
      #   slicers[:curalegacy].display_name # => "CuraEngine Legacy"
      #
      # @example Only list configured slicers
      #   Octoprint::Slicing.list(configured: true)
      #
      # @param configured [Boolean] Only include the slicers that are configured
      # @return [Hash{Symbol => Slicing::Slicer}] The slicers, by {Slicing::Slicer#key key}.
      #   Empty when no slicer is installed
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SLICE+ permission
      #: (?configured: bool) -> Hash[Symbol, Slicer]
      def list(configured: false)
        response = fetch_resource(deserialize: false, options: configured_option(configured))
        response.values.to_h do |slicer_data|
          slicer = Slicer.deserialize(slicer_data)
          [slicer.key.to_sym, slicer]
        end
      end

      # Lists the slicing profiles of a slicer.
      #
      # The profiles don't include their data. Use {.get_profile} to retrieve it.
      #
      # @example
      #   profiles = Octoprint::Slicing.profiles(slicer: "curalegacy")
      #   profiles[:high_quality].display_name # => "High Quality"
      #
      # @param slicer [String] The slicer's key
      # @param configured [Boolean] Only list the profiles if the slicer is configured
      # @return [Hash{Symbol => Slicing::Profile}] The profiles, by {Slicing::Profile#key key}
      # @raise [Octoprint::Exceptions::NotFoundError] if the slicer doesn't exist, or if +configured+ is true
      #   and the slicer isn't configured
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SLICE+ permission
      #: (slicer: String, ?configured: bool) -> Hash[Symbol, Profile]
      def profiles(slicer:, configured: false)
        response = fetch_resource(profiles_path(slicer), deserialize: false, options: configured_option(configured))
        deserialize_profiles(response)
      end

      # Retrieves a slicing profile, including its data.
      #
      # @example
      #   profile = Octoprint::Slicing.get_profile(slicer: "curalegacy", key: "high_quality")
      #   profile.data # => { layer_height: 0.1, ... }
      #
      # @param slicer [String] The slicer's key
      # @param key [String] The profile's key
      # @return [Slicing::Profile] The profile
      # @raise [Octoprint::Exceptions::NotFoundError] if the slicer or the profile doesn't exist
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SLICE+ permission
      #: (slicer: String, key: String) -> Profile
      def get_profile(slicer:, key:)
        Profile.deserialize(fetch_resource(profile_subpath(slicer, key), deserialize: false))
      end

      # Adds a slicing profile, or replaces it if a profile with this key already exists.
      #
      # The first profile added to a slicer becomes its default profile.
      #
      # @example
      #   profile = Octoprint::Slicing.add_profile(
      #     slicer: "curalegacy",
      #     key: "draft",
      #     display_name: "Draft",
      #     description: "Fast and ugly",
      #     data: { layer_height: 0.3 }
      #   )
      #   profile.resource # => "http://octopi.local/api/slicing/curalegacy/profiles/draft"
      #
      # @param slicer [String] The slicer's key
      # @param key [String] The new profile's key
      # @param data [Hash] The slicer-specific profile settings
      # @param display_name [String, nil] The profile's human-readable name
      # @param description [String, nil] The profile's description
      # @return [Slicing::Profile] The added profile, without its data
      # @raise [Octoprint::Exceptions::NotFoundError] if the slicer doesn't exist
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SETTINGS+ permission
      #: (
      #|   slicer: String,
      #|   key: String,
      #|   ?data: Hash[(Symbol | String), untyped],
      #|   ?display_name: String?,
      #|   ?description: String?
      #| ) -> Profile
      def add_profile(slicer:, key:, data: {}, display_name: nil, description: nil)
        params = { displayName: display_name, description: description, data: data }.compact
        Profile.deserialize(put(path: profile_path(slicer, key), params: params))
      end

      # Updates a slicing profile. Only the given attributes are changed.
      #
      # @example Rename a profile
      #   Octoprint::Slicing.update_profile(slicer: "curalegacy", key: "draft", display_name: "Quick draft")
      #
      # @example Make a profile the slicer's default
      #   Octoprint::Slicing.update_profile(slicer: "curalegacy", key: "draft", default: true)
      #
      # @param slicer [String] The slicer's key
      # @param key [String] The profile's key
      # @param data [Hash, nil] Profile settings to change. Settings left out keep their value
      # @param display_name [String, nil] The new human-readable name
      # @param description [String, nil] The new description
      # @param default [Boolean, nil] true to make this profile the slicer's default
      # @return [Slicing::Profile] The updated profile, without its data
      # @raise [Octoprint::Exceptions::NotFoundError] if the slicer or the profile doesn't exist
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SETTINGS+ permission
      #: (
      #|   slicer: String,
      #|   key: String,
      #|   ?data: Hash[(Symbol | String), untyped]?,
      #|   ?display_name: String?,
      #|   ?description: String?,
      #|   ?default: bool?
      #| ) -> Profile
      def update_profile(slicer:, key:, data: nil, display_name: nil, description: nil, default: nil)
        params = { displayName: display_name, description: description, default: default, data: data }.compact
        Profile.deserialize(patch(path: profile_path(slicer, key), params: params))
      end

      # Deletes a slicing profile.
      #
      # The server reports a success even when the profile doesn't exist.
      #
      # @example
      #   Octoprint::Slicing.delete_profile(slicer: "curalegacy", key: "draft") # => true
      #
      # @param slicer [String] The slicer's key
      # @param key [String] The profile's key
      # @return [true] when the request succeeded
      # @raise [Octoprint::Exceptions::NotFoundError] if the slicer doesn't exist
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +SETTINGS+ permission
      #: (slicer: String, key: String) -> TrueClass
      def delete_profile(slicer:, key:)
        delete(path: profile_path(slicer, key))
      end

      # Builds the profiles from the hash of profile key => profile data returned by the API.
      #
      # The profiles are keyed by their {Slicing::Profile#key key}, as a Symbol. The client underscores
      # the hash keys of every response, so a profile named +high-quality+ is keyed +:"high-quality"+,
      # not +:high_quality+.
      #
      # @api private
      # @param profiles_data [Hash, nil] The profiles data, by key
      # @return [Hash{Symbol => Slicing::Profile}] The profiles, by key. Empty when +profiles_data+ is nil
      #: (Hash[Symbol, untyped]? profiles_data) -> Hash[Symbol, Profile]
      def deserialize_profiles(profiles_data)
        (profiles_data || {}).values.to_h do |profile_data|
          profile = Profile.deserialize(profile_data)
          [profile.key.to_sym, profile]
        end
      end

      private

      #: (String slicer) -> String
      def profiles_path(slicer)
        "#{ERB::Util.url_encode(slicer)}/profiles"
      end

      #: (String slicer, String key) -> String
      def profile_subpath(slicer, key)
        "#{profiles_path(slicer)}/#{ERB::Util.url_encode(key)}"
      end

      #: (String slicer, String key) -> String
      def profile_path(slicer, key)
        "#{@path}/#{profile_subpath(slicer, key)}"
      end

      #: (bool configured) -> Hash[Symbol, bool]
      def configured_option(configured)
        configured ? { configured: true } : {}
      end
    end
  end
end
