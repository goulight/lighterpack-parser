# frozen_string_literal: true

require_relative 'lighterpack_parser/version'
require_relative 'lighterpack_parser/gram_converter'
require_relative 'lighterpack_parser/item'
require_relative 'lighterpack_parser/category'
require_relative 'lighterpack_parser/list'
require_relative 'lighterpack_parser/item_parser'
require_relative 'lighterpack_parser/category_parser'
require_relative 'lighterpack_parser/list_parser'
require_relative 'lighterpack_parser/parser'

# Parser for extracting data from Lighterpack list HTML pages.
#
# Provides classes and methods to parse Lighterpack list HTML and extract
# structured data including list information, categories, and items with their
# properties (weight, quantity, consumable status, etc.).
module LighterpackParser
  # Convenience method to parse a Lighterpack URL
  def self.parse_url(url)
    Parser.new(url: url).parse
  end
end
