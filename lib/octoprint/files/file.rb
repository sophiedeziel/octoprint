# typed: true
# frozen_string_literal: true

require "sorbet-runtime"
require "time"

module Octoprint
  class Files
    # File information
    class File
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :name, type: String, nilable: false
      # Display is a reserved keyword in Ruby, so we need to rename it
      auto_attr :display_name, type: String
      auto_attr :origin, type: Location, nilable: false
      auto_attr :path, type: String, nilable: false
      auto_attr :type, type: String
      auto_attr :type_path, type: String, array: true
      auto_attr :refs, type: Refs
      auto_attr :display_layer_progress, type: Hash
      auto_attr :dashboard, type: Hash
      auto_attr :date_timestamp, type: Integer
      auto_attr :gcode_analysis, type: Hash
      auto_attr :md5_hash, type: String
      auto_attr :size, type: Integer
      auto_attr :userdata, type: Hash
      auto_attr :children, type: File, array: true
      auto_attr :prints, type: Hash
      auto_attr :statistics, type: Hash
      auto_attr :extra, type: Hash

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :refs, Refs
        nested :origin, Location
        array :children, File
        rename display: :display_name, hash: :md5_hash, date: :date_timestamp
        collect_extras
      end

      # Convert Unix timestamp to Time object
      #
      # @return [Time, nil] The file date as a Time object, or nil if no timestamp
      sig { returns(T.nilable(Time)) }
      def date
        return nil unless date_timestamp

        Time.at(date_timestamp)
      end
    end
  end
end
