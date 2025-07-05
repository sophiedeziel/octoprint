# typed: true
# frozen_string_literal: true

module Octoprint
  # Log file management API
  #
  # This class provides methods to manage log files on the OctoPrint server.
  # The logging functionality allows you to retrieve information about available
  # log files and delete them when needed for maintenance or cleanup purposes.
  #
  # Log files contain important debugging and operational information from the
  # OctoPrint server, including printer communication logs, error messages,
  # and system events.
  #
  # @example List all available log files
  #   logs = Octoprint::Logs.list
  #   puts "Available log files (#{logs.files.length}):"
  #   logs.files.each do |log_file|
  #     puts "- #{log_file.name}: #{log_file.size} bytes, modified #{log_file.modification_time}"
  #   end
  #   puts "Free disk space: #{logs.free} bytes" if logs.free
  #
  # @example Access log file details and references
  #   logs = Octoprint::Logs.list
  #   log_file = logs.files.first
  #   puts "Log file: #{log_file.name}"
  #   puts "Size: #{log_file.size} bytes"
  #   puts "Last modified: #{log_file.modification_time}"
  #   if log_file.refs
  #     puts "Download URL: #{log_file.refs.download}"
  #     puts "Resource URL: #{log_file.refs.resource}"
  #   end
  #
  # @example Delete old log files
  #   logs = Octoprint::Logs.list
  #   old_logs = logs.files.select { |log| log.name.match?(/\.log\.\d+$/) }
  #   old_logs.each do |log_file|
  #     success = Octoprint::Logs.delete_file(filename: log_file.name)
  #     puts success ? "Deleted #{log_file.name}" : "Failed to delete #{log_file.name}"
  #   end
  #
  # @example Check disk space and cleanup if needed
  #   logs = Octoprint::Logs.list
  #   if logs.free && logs.free < 100_000_000 # Less than 100MB free
  #     puts "Low disk space detected (#{logs.free} bytes free)"
  #     # Delete archived log files to free space
  #     archived_logs = logs.files.select { |log| log.name.include?('.gz') }
  #     archived_logs.each do |log_file|
  #       Octoprint::Logs.delete_file(filename: log_file.name)
  #       puts "Deleted archived log: #{log_file.name}"
  #     end
  #   end
  #
  # OctoPrint's API doc: https://docs.octoprint.org/en/1.11.2/bundledplugins/logging.html
  class Logs < BaseResource
    extend T::Sig
    include Deserializable
    include AutoInitializable

    resource_path("/plugin/logging/logs")

    auto_attr :files, type: LogFile, array: true, nilable: false
    auto_attr :free, type: Integer

    auto_initialize!

    # Configure deserialization
    deserialize_config do
      array :files, LogFile
    end

    # Retrieves a list of available log files
    #
    # @return [Logs] List of log files with metadata
    #
    # @example
    #   logs = Octoprint::Logs.list
    #   logs.files.each { |file| puts "#{file.name}: #{file.size} bytes" }
    #   puts "Free space: #{logs.free} bytes"
    sig { returns(Logs) }
    def self.list
      fetch_resource
    end

    # Deletes a specific log file
    #
    # @param [String] filename The name of the log file to delete
    # @return [T::Boolean] True if deletion was successful
    #
    # @example
    #   result = Octoprint::Logs.delete_file(filename: "octoprint.log.1")
    #   puts "Deleted successfully" if result
    sig { params(filename: String).returns(T::Boolean) }
    def self.delete_file(filename:)
      path = [@path, filename].compact.join("/")
      delete(path: path)
    end
  end
end
