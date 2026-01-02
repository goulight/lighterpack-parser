# frozen_string_literal: true

module LighterpackParser
  # Represents a Lighterpack list.
  #
  # @attr_reader [String] name The name of the list
  # @attr_reader [String, nil] description Optional description of the list
  # @attr_reader [Array<Category>] categories Array of categories in this list
  class List
    attr_reader :name, :description, :categories

    # @param name [String] The name of the list
    # @param description [String, nil] Optional description
    # @param categories [Array<Category>] Array of categories in this list
    def initialize(name:, description: nil, categories: [])
      @name = name
      @description = description
      @categories = categories
    end

    # Convert to hash for backward compatibility
    # @return [Hash] Hash representation of the list
    def to_h
      {
        name: name,
        description: description,
        categories: categories.map(&:to_h)
      }
    end
  end
end
