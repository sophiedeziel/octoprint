# typed: true
# frozen_string_literal: true

require "sorbet-runtime"
require "time"

module Octoprint
  class Files
    # File information
    #
    # `origin` is {Location::Printer} for files on the printer's storage, whatever the server version: {Files::Legacy}
    # renames the 1.x `sdcard` origin. OctoPrint 2.0 doesn't report `md5_hash` (nil).
    class File
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
      # The file's `hash` from OctoPrint 1.x: a SHA-1 digest of its content, despite the name. Always nil on
      # OctoPrint 2.0, which no longer reports a digest of the file (with or without the API version header).
      auto_attr :md5_hash, type: String
      auto_attr :size, type: Integer
      auto_attr :userdata, type: Hash
      auto_attr :children, type: File, array: true
      auto_attr :prints, type: Hash
      auto_attr :statistics, type: Hash
      # User who uploaded the file (OctoPrint 1.11 and 2.0, nil for printer files)
      auto_attr :user, type: String
      auto_attr :extra, type: Hash

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :refs, Refs
        nested :origin, Location
        array :children, File
        rename display: :display_name, hash: :md5_hash, date: :date_timestamp
      end

      # Convert Unix timestamp to Time object
      #
      # @return [Time, nil] The file date as a Time object, or nil if no timestamp
      #: -> Time?
      def date
        return nil unless date_timestamp

        Time.at(date_timestamp)
      end
    end
  end
end
