# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # A folder in the file system
    class Folder < T::Struct
      prop :name, String
      prop :origin, String
      prop :path, String
      prop :refs, T::Hash[Symbol, String]
    end
  end
end
