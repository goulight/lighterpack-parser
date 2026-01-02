# frozen_string_literal: true

module LighterpackParser
  # Parser for extracting list data from Lighterpack HTML documents.
  class ListParser
    # Parse a Lighterpack HTML document and return a List object.
    #
    # @param doc [Nokogiri::HTML::Document] The parsed HTML document
    # @param category_parser [CategoryParser] The parser to use for extracting categories
    # @param item_parser [ItemParser] The parser to use for extracting items
    # @return [List] The parsed list
    def parse(doc, category_parser:, item_parser:)
      List.new(
        name: extract_name(doc),
        description: extract_description(doc),
        categories: category_parser.parse_all(doc, item_parser: item_parser)
      )
    end

    private

    def extract_name(doc)
      # Lighterpack uses h1.lpListName
      h1 = doc.at_css('h1.lpListName')
      return h1.text.strip if h1

      # Fallback to regular h1
      h1 = doc.at_css('h1')
      return h1.text.strip if h1

      title = doc.at_css('title')
      return title.text.strip if title

      'Untitled List'
    end

    def extract_description(doc)
      # Lighterpack doesn't seem to have a list description in the HTML
      # Could be in meta tags
      meta_desc = doc.at_css('meta[name="description"]')
      return meta_desc['content'] if meta_desc && meta_desc['content']

      nil
    end
  end
end
