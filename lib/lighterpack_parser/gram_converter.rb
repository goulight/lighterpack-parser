# frozen_string_literal: true

module LighterpackParser
  # Simple converter for weight units to grams.
  class GramConverter
    # Conversion factors for weight units to grams.
    CONVERSION_FACTORS = {
      'oz' => 28.3495,
      'lb' => 453.592,
      'g' => 1.0,
      'kg' => 1000.0
    }.freeze

    # Initialize the converter with the source unit.
    #
    # @param source_unit [String] The unit to convert from.
    def initialize(source_unit:)
      @source_unit = source_unit
    end

    # Convert a value from the source unit to grams.
    #
    # @param value [Float] The value to convert..
    # @return [Float] The converted value in grams.
    def convert(value)
      factor = CONVERSION_FACTORS[@source_unit.to_s.downcase] || 1.0
      value * factor
    end

    # Convert a value from a unit to grams.
    #
    # @param value [Float] The value to convert.
    # @param unit [String] The unit to convert from.
    # @return [Float] The converted value in grams.
    def self.to_grams(value, unit)
      new(source_unit: unit).convert(value)
    end
  end
end
