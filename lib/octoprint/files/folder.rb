# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # A folder in the file system
    class Folder < T::Struct
      prop :name, String
      # Display is a reserved keyword in Ruby, so we need to rename it
      prop :display_name, T.nilable(String), default: nil
      prop :origin, String
      prop :path, String
      prop :refs, Refs

      def self.deserialize(data)
        data[:refs] = Refs.new(data[:refs]) if data[:refs]
        data[:display_name] = data.delete(:display) if data[:display]
        new(data)
      end
    end
  end
end
