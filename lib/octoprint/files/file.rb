# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # File information
    class File < T::Struct
      prop :name, String
      # Display is a reserved keyword in Ruby, so we need to rename it
      prop :display_name, T.nilable(String), default: nil
      prop :origin, Location
      prop :path, String
      prop :type, T.nilable(String), default: nil
      prop :type_path, T.nilable(T::Array[String]), default: nil
      prop :refs, T.nilable(Refs), default: nil

      def self.deserialize(data)
        data[:refs] = Refs.new(data[:refs]) if data[:refs]
        data[:display_name] = data.delete(:display) if data[:display]
        data[:origin] = Location.deserialize(data[:origin]) if data[:origin]
        new(data)
      end
    end
  end
end
