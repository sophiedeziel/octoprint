# typed: true
# frozen_string_literal: true

module Octoprint
  class Logs
    # Individual log file representation
    #
    # Represents a single log file on the OctoPrint server with its metadata,
    # including size, modification date, and download/resource references.
    #
    # @example Working with log file information
    #   logs = Octoprint::Logs.list
    #   log_file = logs.files.first
    #
    #   puts log_file.name              # => "octoprint.log"
    #   puts log_file.size              # => 1048576 (in bytes)
    #   puts log_file.modification_time # => 2023-12-31 12:00:00 UTC
    #   puts log_file.to_s              # => "octoprint.log (1048576 bytes, modified: 2023-12-31 12:00:00 UTC)"
    #
    # @example Accessing download and resource URLs
    #   log_file = logs.files.first
    #   if log_file.refs
    #     download_url = log_file.refs.download  # Direct download URL
    #     resource_url = log_file.refs.resource  # API resource URL
    #   end
    class LogFile
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :name, type: String, nilable: false
      auto_attr :size, type: Integer, nilable: false
      auto_attr :date, type: Integer, nilable: false
      auto_attr :refs, type: References

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :refs, References
      end

      # Returns a human-readable string representation of the log file
      #
      # @return [String]
      sig { returns(String) }
      def to_s
        "#{self.class.name} (#{size} bytes, modified: #{Time.at(date)})"
      end

      # Convert Unix timestamp to Time object
      #
      # @return [Time] The file date as a Time object
      sig { returns(Time) }
      def modification_time
        Time.at(date)
      end
    end
  end
end
