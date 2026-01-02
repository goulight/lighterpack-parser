# frozen_string_literal: true

require 'nokogiri'
require 'httparty'

module LighterpackParser
  # Main parser for extracting data from Lighterpack list HTML pages.
  #
  # Orchestrates the parsing process by coordinating ListParser, CategoryParser,
  # and ItemParser to extract structured data from Lighterpack HTML.
  class Parser
    def initialize(html: nil, url: nil)
      @html = if url
                fetch_html(url)
              elsif html
                html
              else
                raise ArgumentError, 'Either html or url must be provided'
              end
      @item_parser = ItemParser.new
      @category_parser = CategoryParser.new
      @list_parser = ListParser.new
    end

    def parse
      doc = Nokogiri::HTML(@html)
      @list_parser.parse(doc, category_parser: @category_parser, item_parser: @item_parser)
    end

    private

    def fetch_html(url)
      response = HTTParty.get(url, timeout: 30)
      raise "Failed to fetch URL: #{response.code}" unless response.success?

      response.body
    end
  end
end
