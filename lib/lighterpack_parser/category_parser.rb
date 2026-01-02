# frozen_string_literal: true

module LighterpackParser
  # Parser for extracting category data from Lighterpack HTML documents.
  class CategoryParser
    # Parse all categories from a Lighterpack HTML document.
    #
    # @param doc [Nokogiri::HTML::Document] The parsed HTML document
    # @param item_parser [ItemParser] The parser to use for extracting items
    # @return [Array<Category>] Array of extracted categories
    def parse_all(doc, item_parser:)
      categories = []

      # Lighterpack structure: ul.lpCategories > li.lpCategory
      doc.css('ul.lpCategories > li.lpCategory').each do |category_element|
        category = parse(category_element, item_parser: item_parser)
        categories << category if category
      end

      categories
    end

    # Parse a single category element.
    #
    # @param category_element [Nokogiri::XML::Element] The category HTML element
    # @param item_parser [ItemParser] The parser to use for extracting items
    # @return [Category, nil] The parsed category, or nil if name is missing
    def parse(category_element, item_parser:)
      # Category name is in h2.lpCategoryName
      category_header = category_element.at_css('h2.lpCategoryName')
      return nil unless category_header

      category_name = category_header.text.strip
      return nil if category_name.empty?

      # Description is typically in the category name itself (in parentheses)
      description = extract_description(category_name)

      # Find items in this category
      items = extract_items(category_element, item_parser: item_parser)

      Category.new(
        name: category_name,
        description: description,
        items: items
      )
    end

    private

    def extract_items(category_element, item_parser:)
      items = []

      # Items are in ul.lpItems within the category
      items_list = category_element.at_css('ul.lpItems')
      return items unless items_list

      # Extract items (skip header row)
      items_list.css('li.lpItem').each do |item_element|
        item = item_parser.parse(item_element)
        items << item if item
      end

      items
    end

    def extract_description(category_name)
      # Description is often in parentheses in the category name
      # e.g., "Big 3 (Pack, Tent, Sleep System)"
      match = category_name.match(/\(([^)]+)\)/)
      return match[1] if match

      nil
    end
  end
end
