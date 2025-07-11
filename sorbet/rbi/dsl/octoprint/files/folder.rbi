# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Octoprint::Files::Folder`.
# Please instead update this file by running `bin/tapioca dsl Octoprint::Files::Folder`.


class Octoprint::Files::Folder
  sig { returns(T.nilable(::String)) }
  def display_name; end

  sig { returns(T.nilable(::String)) }
  def name; end

  sig { returns(T.nilable(::Octoprint::Location)) }
  def origin; end

  sig { returns(T.nilable(::String)) }
  def path; end

  sig { returns(T.nilable(::Octoprint::Files::Refs)) }
  def refs; end
end
