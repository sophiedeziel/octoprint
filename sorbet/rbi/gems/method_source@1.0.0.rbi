# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `method_source` gem.
# Please instead update this file by running `bin/tapioca gem method_source`.

# source://method_source//lib/method_source.rb#127
class Method
  include ::MethodSource::SourceLocation::MethodExtensions
  include ::MethodSource::MethodExtensions
end

# source://method_source//lib/method_source/version.rb#1
module MethodSource
  extend ::MethodSource::CodeHelpers

  class << self
    # source://method_source//lib/method_source.rb#38
    def comment_helper(source_location, name = T.unsafe(nil)); end

    # source://method_source//lib/method_source.rb#66
    def extract_code(source_location); end

    # source://method_source//lib/method_source.rb#51
    def lines_for(file_name, name = T.unsafe(nil)); end

    # source://method_source//lib/method_source.rb#23
    def source_helper(source_location, name = T.unsafe(nil)); end

    # source://method_source//lib/method_source.rb#59
    def valid_expression?(str); end
  end
end

# source://method_source//lib/method_source/code_helpers.rb#3
module MethodSource::CodeHelpers
  # source://method_source//lib/method_source/code_helpers.rb#52
  def comment_describing(file, line_number); end

  # source://method_source//lib/method_source/code_helpers.rb#66
  def complete_expression?(str); end

  # source://method_source//lib/method_source/code_helpers.rb#20
  def expression_at(file, line_number, options = T.unsafe(nil)); end

  private

  # source://method_source//lib/method_source/code_helpers.rb#92
  def extract_first_expression(lines, consume = T.unsafe(nil), &block); end

  # source://method_source//lib/method_source/code_helpers.rb#106
  def extract_last_comment(lines); end
end

# source://method_source//lib/method_source/code_helpers.rb#124
module MethodSource::CodeHelpers::IncompleteExpression
  class << self
    # source://method_source//lib/method_source/code_helpers.rb#137
    def ===(ex); end

    # source://method_source//lib/method_source/code_helpers.rb#149
    def rbx?; end
  end
end

# source://method_source//lib/method_source/code_helpers.rb#125
MethodSource::CodeHelpers::IncompleteExpression::GENERIC_REGEXPS = T.let(T.unsafe(nil), Array)

# source://method_source//lib/method_source/code_helpers.rb#133
MethodSource::CodeHelpers::IncompleteExpression::RBX_ONLY_REGEXPS = T.let(T.unsafe(nil), Array)

# source://method_source//lib/method_source.rb#72
module MethodSource::MethodExtensions
  # source://method_source//lib/method_source.rb#121
  def comment; end

  # source://method_source//lib/method_source.rb#109
  def source; end

  class << self
    # source://method_source//lib/method_source.rb#79
    def included(klass); end
  end
end

# source://method_source//lib/method_source/source_location.rb#2
module MethodSource::ReeSourceLocation
  # source://method_source//lib/method_source/source_location.rb#5
  def source_location; end
end

# source://method_source//lib/method_source/source_location.rb#10
module MethodSource::SourceLocation; end

# source://method_source//lib/method_source/source_location.rb#11
module MethodSource::SourceLocation::MethodExtensions
  # source://method_source//lib/method_source/source_location.rb#40
  def source_location; end

  private

  # source://method_source//lib/method_source/source_location.rb#26
  def trace_func(event, file, line, id, binding, classname); end
end

# source://method_source//lib/method_source/source_location.rb#54
module MethodSource::SourceLocation::ProcExtensions
  # source://method_source//lib/method_source/source_location.rb#74
  def source_location; end
end

# source://method_source//lib/method_source/source_location.rb#81
module MethodSource::SourceLocation::UnboundMethodExtensions
  # source://method_source//lib/method_source/source_location.rb#101
  def source_location; end
end

# source://method_source//lib/method_source.rb#16
class MethodSource::SourceNotFoundError < ::StandardError; end

# source://method_source//lib/method_source/version.rb#2
MethodSource::VERSION = T.let(T.unsafe(nil), String)

# source://method_source//lib/method_source.rb#137
class Proc
  include ::MethodSource::SourceLocation::ProcExtensions
  include ::MethodSource::MethodExtensions
end

# source://method_source//lib/method_source.rb#132
class UnboundMethod
  include ::MethodSource::SourceLocation::UnboundMethodExtensions
  include ::MethodSource::MethodExtensions
end
