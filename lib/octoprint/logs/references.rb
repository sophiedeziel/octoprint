# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Logs
    # References relevant to this log file
    #
    # Contains URLs for accessing the log file through different endpoints,
    # including direct download and API resource access.
    #
    # @example Accessing log file URLs
    #   log_file = Octoprint::Logs.list.files.first
    #   refs = log_file.refs
    #
    #   puts refs.resource  # => "http://octoprint.local/plugin/logging/logs/octoprint.log"
    #   puts refs.download  # => "http://octoprint.local/downloads/logs/octoprint.log"
    class References
      extend T::Sig
      include AutoInitializable

      auto_attr :resource, type: String
      auto_attr :download, type: String

      auto_initialize!
    end
  end
end
