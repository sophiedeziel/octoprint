# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    class OperationResult < T::Struct
      prop :done, T::Boolean
      prop :effective_select, T.nilable(T::Boolean), default: nil
      prop :effective_print, T.nilable(T::Boolean), default: nil
      prop :files, T.nilable(T::Hash[Location, File]), default: nil
      prop :folder, T.nilable(Folder)

      def self.deserialize(data)
        data[:folder] = Files::Folder.deserialize(data[:folder]) if data[:folder]
        data[:files].clone&.each_key do |key|
          data[:files][Location.deserialize(key.to_s)] = Files::File.deserialize(data[:files].delete(key))
        end
        new(data)
      end
    end
  end
end
