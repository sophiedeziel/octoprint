# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # Attributes shared by rendered and unrendered timelapses ({Timelapse::Rendered} and
    # {Timelapse::Unrendered}).
    #
    # Including this module declares the following attributes on the including class:
    #
    # - +name+ [String] The name of the timelapse file or job
    # - +size+ [String] The formatted size, e.g. "2.0MB"
    # - +bytes+ [Integer] The size in bytes
    # - +date+ [String] The formatted date, e.g. "2026-11-15 00:52"
    # - +extra+ [Hash, nil] Any additional fields returned by the API
    #
    # The including class declares its own attributes, then calls +auto_initialize!+. It should also
    # include AutoInitializable and Deserializable itself, so Sorbet sees +auto_attr+ on it.
    #
    # @example
    #   class Rendered
    #     include AutoInitializable
    #     include Deserializable
    #     include FileAttributes
    #
    #     auto_attr :url, type: String
    #
    #     auto_initialize!
    #   end
    module FileAttributes
      extend T::Sig

      # Declares the shared timelapse attributes on the including class.
      #
      # @param base [Class] The including class
      # @return [void]
      sig { params(base: Module).void }
      def self.included(base)
        super

        klass = T.unsafe(base)
        klass.include AutoInitializable
        klass.include Deserializable
        klass.auto_attr :name, type: String
        klass.auto_attr :size, type: String
        klass.auto_attr :bytes, type: Integer
        klass.auto_attr :date, type: String
        klass.auto_attr :extra, type: Hash
      end
    end
  end
end
