# typed: true
# frozen_string_literal: true

module Octoprint
  # The Wizard API allows retrieval of registered wizard dialog data
  # and completion of wizard dialogs.
  #
  # @see https://docs.octoprint.org/en/master/api/wizard.html OctoPrint Wizard API Documentation
  #
  # @example Get wizard data
  #   wizards = Octoprint::Wizard.get
  #   wizards.each do |name, data|
  #     puts "#{name}: required=#{data[:required]}, ignored=#{data[:ignored]}"
  #   end
  #
  # @example Complete wizard dialog
  #   Octoprint::Wizard.finish(handled: ["corewizard", "softwareupdate"])
  class Wizard < BaseResource
    extend T::Sig

    resource_path("/api/setup/wizard")

    # Retrieves registered wizard data from the OctoPrint server.
    #
    # Returns a Hash mapping wizard identifiers to wizard data entries.
    # Each entry contains details about whether the wizard is required,
    # ignored, its version, and plugin-specific details.
    #
    # @example Get wizard data
    #   wizards = Octoprint::Wizard.get
    #   wizards.each do |name, data|
    #     puts "#{name}: required=#{data[:required]}"
    #   end
    #
    # @return [Hash] Wizard data keyed by wizard identifier
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { returns(T::Hash[Symbol, T.untyped]) }
    def self.get
      fetch_resource(deserialize: false)
    end

    # Completes a wizard dialog by reporting which wizards were handled.
    #
    # Triggers the on_wizard_finish method across all registered wizard
    # plugins, passing information about which wizards were handled
    # versus skipped.
    #
    # @example Complete specific wizards
    #   Octoprint::Wizard.finish(handled: ["corewizard", "softwareupdate"])
    #
    # @param handled [Array<String>] List of wizard identifiers that were processed (not skipped)
    # @return [T::Boolean] true on success (204 No Content)
    # @raise [Octoprint::Exceptions::Error] if the request fails
    sig { params(handled: T::Array[String]).returns(T.untyped) }
    def self.finish(handled:)
      post(params: { handled: handled })
    end
  end
end
