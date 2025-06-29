# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    class OperationResult < T::Struct
      extend T::Sig
      include Deserializable
      
      prop :done, T::Boolean
      prop :effective_select, T.nilable(T::Boolean), default: nil
      prop :effective_print, T.nilable(T::Boolean), default: nil
      prop :files, T.nilable(T::Hash[Location, File]), default: nil
      prop :folder, T.nilable(Folder)

      sig { params(data: T::Hash[Symbol, T.untyped]).returns(OperationResult) }
      def self.deserialize(data)
        deserialize_nested(data, :folder, Files::Folder)
        
        # Handle the special case of files hash with Location keys
        if data[:files]
          new_files = {}
          data[:files].each do |key, value|
            location_key = Location.deserialize(key.to_s)
            new_files[location_key] = Files::File.deserialize(value)
          end
          data[:files] = new_files
        end
        
        new(data)
      end
    end
  end
end
