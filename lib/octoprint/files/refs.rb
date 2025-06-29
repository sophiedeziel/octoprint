# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # References relevant to this file, left out in abridged version
    class Refs
      extend T::Sig
      include AutoInitializable

      auto_attr :resource, type: String
      auto_attr :download, type: String
      auto_attr :model, type: String

      auto_initialize!
    end
  end
end
