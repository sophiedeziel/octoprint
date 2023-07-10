# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # References relevant to this file, left out in abridged version
    class Refs < T::Struct
      prop :resource, String
      prop :download, T.nilable(String), default: nil
      prop :model, T.nilable(String), default: nil
    end
  end
end
