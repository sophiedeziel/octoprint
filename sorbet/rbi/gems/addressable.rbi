# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: false
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/addressable/all/addressable.rbi
#
# addressable-2.8.0

module Addressable
end
module Addressable::VERSION
end
module Addressable::IDNA
  def self.lookup_unicode_combining_class(codepoint); end
  def self.lookup_unicode_compatibility(codepoint); end
  def self.lookup_unicode_composition(unpacked); end
  def self.lookup_unicode_lowercase(codepoint); end
  def self.punycode_adapt(delta, numpoints, firsttime); end
  def self.punycode_basic?(codepoint); end
  def self.punycode_decode(punycode); end
  def self.punycode_decode_digit(codepoint); end
  def self.punycode_delimiter?(codepoint); end
  def self.punycode_encode(unicode); end
  def self.punycode_encode_digit(d); end
  def self.to_ascii(input); end
  def self.to_unicode(input); end
  def self.ucs4_to_utf8(char, buffer); end
  def self.unicode_compose(unpacked); end
  def self.unicode_compose_pair(ch_one, ch_two); end
  def self.unicode_decompose(unpacked); end
  def self.unicode_decompose_hangul(codepoint); end
  def self.unicode_downcase(input); end
  def self.unicode_normalize_kc(input); end
  def self.unicode_sort_canonical(unpacked); end
end
class Addressable::IDNA::PunycodeBadInput < StandardError
end
class Addressable::IDNA::PunycodeBigOutput < StandardError
end
class Addressable::IDNA::PunycodeOverflow < StandardError
end
class Addressable::URI
  def +(uri); end
  def ==(uri); end
  def ===(uri); end
  def absolute?; end
  def authority; end
  def authority=(new_authority); end
  def basename; end
  def default_port; end
  def defer_validation; end
  def display_uri; end
  def domain; end
  def dup; end
  def empty?; end
  def eql?(uri); end
  def extname; end
  def fragment; end
  def fragment=(new_fragment); end
  def freeze; end
  def hash; end
  def host; end
  def host=(new_host); end
  def hostname; end
  def hostname=(new_hostname); end
  def inferred_port; end
  def initialize(options = nil); end
  def inspect; end
  def ip_based?; end
  def join!(uri); end
  def join(uri); end
  def merge!(uri); end
  def merge(hash); end
  def normalize!; end
  def normalize; end
  def normalized_authority; end
  def normalized_fragment; end
  def normalized_host; end
  def normalized_password; end
  def normalized_path; end
  def normalized_port; end
  def normalized_query(*flags); end
  def normalized_scheme; end
  def normalized_site; end
  def normalized_user; end
  def normalized_userinfo; end
  def omit!(*components); end
  def omit(*components); end
  def origin; end
  def origin=(new_origin); end
  def password; end
  def password=(new_password); end
  def path; end
  def path=(new_path); end
  def port; end
  def port=(new_port); end
  def query; end
  def query=(new_query); end
  def query_values(return_type = nil); end
  def query_values=(new_query_values); end
  def relative?; end
  def remove_composite_values; end
  def replace_self(uri); end
  def request_uri; end
  def request_uri=(new_request_uri); end
  def route_from(uri); end
  def route_to(uri); end
  def scheme; end
  def scheme=(new_scheme); end
  def self.convert_path(path); end
  def self.encode(uri, return_type = nil); end
  def self.encode_component(component, character_class = nil, upcase_encoded = nil); end
  def self.escape(uri, return_type = nil); end
  def self.escape_component(component, character_class = nil, upcase_encoded = nil); end
  def self.form_encode(form_values, sort = nil); end
  def self.form_unencode(encoded_value); end
  def self.heuristic_parse(uri, hints = nil); end
  def self.ip_based_schemes; end
  def self.join(*uris); end
  def self.normalize_component(component, character_class = nil, leave_encoded = nil); end
  def self.normalize_path(path); end
  def self.normalized_encode(uri, return_type = nil); end
  def self.parse(uri); end
  def self.port_mapping; end
  def self.unencode(uri, return_type = nil, leave_encoded = nil); end
  def self.unencode_component(uri, return_type = nil, leave_encoded = nil); end
  def self.unescape(uri, return_type = nil, leave_encoded = nil); end
  def self.unescape_component(uri, return_type = nil, leave_encoded = nil); end
  def site; end
  def site=(new_site); end
  def split_path(path); end
  def tld; end
  def tld=(new_tld); end
  def to_hash; end
  def to_s; end
  def to_str; end
  def user; end
  def user=(new_user); end
  def userinfo; end
  def userinfo=(new_userinfo); end
  def validate; end
end
class Addressable::URI::InvalidURIError < StandardError
end
module Addressable::URI::CharacterClasses
end
module Addressable::URI::NormalizeCharacterClasses
end
class Addressable::Template
  def ==(template); end
  def eql?(template); end
  def expand(mapping, processor = nil, normalize_values = nil); end
  def extract(uri, processor = nil); end
  def freeze; end
  def initialize(pattern); end
  def inspect; end
  def join_values(operator, return_value); end
  def keys; end
  def match(uri, processor = nil); end
  def named_captures; end
  def names; end
  def normalize_keys(mapping); end
  def normalize_value(value); end
  def ordered_variable_defaults; end
  def parse_new_template_pattern(pattern, processor = nil); end
  def parse_template_pattern(pattern, processor = nil); end
  def partial_expand(mapping, processor = nil, normalize_values = nil); end
  def pattern; end
  def source; end
  def to_regexp; end
  def transform_capture(mapping, capture, processor = nil, normalize_values = nil); end
  def transform_partial_capture(mapping, capture, processor = nil, normalize_values = nil); end
  def variable_defaults; end
  def variables; end
end
class Addressable::Template::InvalidTemplateValueError < StandardError
end
class Addressable::Template::InvalidTemplateOperatorError < StandardError
end
class Addressable::Template::TemplateOperatorAbortedError < StandardError
end
class Addressable::Template::MatchData
  def [](key, len = nil); end
  def captures; end
  def initialize(uri, template, mapping); end
  def inspect; end
  def keys; end
  def mapping; end
  def names; end
  def post_match; end
  def pre_match; end
  def string; end
  def template; end
  def to_a; end
  def to_s; end
  def uri; end
  def values; end
  def values_at(*indexes); end
  def variables; end
end
