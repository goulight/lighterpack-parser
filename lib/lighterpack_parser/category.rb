# frozen_string_literal: true

module LighterpackParser
  # Represents a category from a Lighterpack list.
  #
  # @attr_reader [String] name The name of the category
  # @attr_reader [String, nil] description Optional description of the category
  # @attr_reader [Array<Item>] items Array of items in this category
  class Category
    attr_reader :name, :description, :items

    # @param name [String] The name of the category
    # @param description [String, nil] Optional description
    # @param items [Array<Item>] Array of items in this category
    def initialize(name:, description: nil, items: [])
      @name = name
      @description = description
      @items = items
    end

    # Convert to hash for backward compatibility
    # @return [Hash] Hash representation of the category
    def to_h
      {
        name: name,
        description: description,
        items: items.map(&:to_h)
      }
    end
  end
end
