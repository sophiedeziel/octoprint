# frozen_string_literal: true

# Keeps Sorbet's inline RBS signatures out of the generated documentation.
#
# Method signatures are written as `#:` comments (continued with `#|`) right
# above the `def`, so YARD reads them as the last lines of the doc comment
# and would print them in the method description. This parser drops that
# trailing signature block before YARD parses the docstring.
class RbsCommentsDocstringParser < YARD::DocstringParser
  SIGNATURE_LINE = /\A:(\s|$)/
  CONTINUATION_LINE = /\A\|/

  def parse(content, object = nil, handler = nil)
    super(strip_rbs_signature(content), object, handler)
  end

  private

  def strip_rbs_signature(content)
    return content unless content.is_a?(String)

    lines = content.lines
    index = lines.length - 1
    index -= 1 while index >= 0 && lines[index].match?(CONTINUATION_LINE)
    return content unless index >= 0 && lines[index].match?(SIGNATURE_LINE)

    lines[0...index].join.rstrip
  end
end

YARD::Docstring.default_parser = RbsCommentsDocstringParser
