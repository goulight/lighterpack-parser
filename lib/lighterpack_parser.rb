# frozen_string_literal: true

require_relative 'lighterpack_parser/version'
require_relative 'lighterpack_parser/parser'

module LighterpackParser
  # Convenience method to parse a Lighterpack URL
  def self.parse_url(url)
    Parser.new(url: url).parse
  end
end
