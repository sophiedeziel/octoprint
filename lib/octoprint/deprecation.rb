# typed: true
# frozen_string_literal: true

module Octoprint
  # Warns about deprecated gem methods, once per method and process.
  #
  # @example
  #   Octoprint::Deprecation.warn_once("Connection.fake_ack", "use Connection.repair instead")
  #   # [octoprint] Connection.fake_ack is deprecated: use Connection.repair instead
  module Deprecation
    @warned = Set.new
    @mutex = Mutex.new

    class << self
      # Prints a deprecation warning, unless one was already printed for this name
      #
      # @param name [String] What is deprecated, e.g. `"Connection.fake_ack"`
      # @param advice [String] What to use instead
      # @return [void]
      #: (String, String) -> void
      def warn_once(name, advice)
        first = @mutex.synchronize { @warned.add?(name) }
        return unless first

        Kernel.warn("[octoprint] #{name} is deprecated: #{advice}")
      end

      # Forgets the warnings already printed, so they print again. Meant for tests.
      #
      # @return [void]
      #: -> void
      def reset!
        @mutex.synchronize { @warned.clear }
      end
    end
  end
end
