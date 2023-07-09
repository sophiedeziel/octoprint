# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    class OperationResult < T::Struct
      prop :done, T::Boolean
      prop :folder, T.nilable(Folder)
    end
  end
end
