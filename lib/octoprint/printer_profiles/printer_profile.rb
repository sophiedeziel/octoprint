# typed: true
# frozen_string_literal: true

module Octoprint
  class PrinterProfiles
    # Represents a single printer profile configuration
    #
    # A printer profile contains the physical characteristics and capabilities
    # of a 3D printer, including dimensions, extruder configuration, heated bed
    # capabilities, and movement speeds.
    #
    # @example Access printer profile information
    #   profile = printer_profiles.profiles["_default"]
    #   puts profile.name           # => "Default"
    #   puts profile.model          # => "Generic RepRap Printer"
    #   puts profile.volume.width   # => 200
    class PrinterProfile
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :id, type: String, nilable: false
      auto_attr :name, type: String, nilable: false
      auto_attr :color, type: String, nilable: false
      auto_attr :model, type: String, nilable: false
      auto_attr :default, type: T::Boolean, nilable: false
      auto_attr :current, type: T::Boolean, nilable: false
      auto_attr :resource, type: String, nilable: false
      auto_attr :volume, type: Hash, nilable: false
      auto_attr :heated_bed, type: T::Boolean, nilable: false
      auto_attr :heated_chamber, type: T::Boolean, nilable: false
      auto_attr :axes, type: Hash, nilable: false
      auto_attr :extruder, type: Hash, nilable: false
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        collect_extras
      end
    end
  end
end
