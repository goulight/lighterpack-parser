# frozen_string_literal: true

module LighterpackParser
  # Parser for extracting item data from Lighterpack HTML elements.
  class ItemParser
    # Parse a single item element and return an Item object.
    #
    # @param element [Nokogiri::XML::Element] The item HTML element
    # @return [Item, nil] The parsed item, or nil if name is missing
    def parse(element)
      name = extract_name(element)
      return nil unless name

      weight_data = extract_weight(element)
      quantity = extract_quantity(element)
      description = extract_description(element)
      image_url = extract_image_url(element)
      consumable = extract_consumable_flag(element)
      worn = extract_worn_flag(element)

      # Calculate per-item weight
      weight_per_item = weight_data[:weight_grams]

      # Calculate total weights
      total_weight = weight_per_item * quantity

      # In Lighterpack, if an item is consumable, the consumable_weight is always the full weight
      # Calculate total consumable weight (per item * quantity)
      total_consumable_weight = consumable ? weight_per_item * quantity : nil

      # In Lighterpack, if an item is worn, only the first item is worn (worn_quantity = 1)
      # regardless of total quantity
      worn_quantity = worn ? 1 : nil
      total_worn_weight = worn ? weight_per_item * 1 : nil

      Item.new(
        name: name,
        description: description,
        weight: weight_per_item,
        total_weight: total_weight,
        quantity: quantity,
        image_url: image_url,
        consumable: consumable,
        total_consumable_weight: total_consumable_weight,
        worn: worn,
        worn_quantity: worn_quantity,
        total_worn_weight: total_worn_weight
      )
    end

    private

    def extract_name(element)
      # Item name is in span.lpName
      name_elem = element.at_css('span.lpName')
      return name_elem.text.strip if name_elem

      nil
    end

    def extract_weight(element)
      # Lighterpack stores weight in milligrams in input.lpMG
      mg_input = element.at_css('input.lpMG')
      if mg_input && mg_input['value']
        # Convert from milligrams to grams
        weight_grams = mg_input['value'].to_f / 1000.0
        return { weight_grams: weight_grams, original_unit: 'g' }
      end

      # Fallback: try to get from span.lpWeight and unit
      weight_elem = element.at_css('span.lpWeight')
      unit_elem = element.at_css('span.lpDisplay, select.lpUnit option[selected]')

      if weight_elem
        weight_value = weight_elem.text.strip.to_f
        unit = 'g' # default

        if unit_elem
          unit_text = unit_elem.text.strip.downcase
          unit = unit_text if %w[oz lb g kg].include?(unit_text)
        end

        weight_grams = GramConverter.to_grams(weight_value, unit)
        return { weight_grams: weight_grams, original_unit: unit }
      end

      { weight_grams: 0.0, original_unit: 'g' }
    end

    def extract_quantity(element)
      # Quantity is in span.lpQtyCell
      qty_elem = element.at_css('span.lpQtyCell')
      if qty_elem
        qty_text = qty_elem.text.strip
        return qty_text.to_i if qty_text.match?(/^\d+$/)
      end

      # Check qty attribute
      qty_attr = element['qty']
      return qty_attr.to_i if qty_attr

      1 # Default quantity
    end

    def extract_description(element)
      # Description is in span.lpDescription
      desc_elem = element.at_css('span.lpDescription')
      return desc_elem.text.strip if desc_elem && !desc_elem.text.strip.empty?

      nil
    end

    def extract_image_url(element)
      # Image URL is in img.lpItemImage
      img = element.at_css('img.lpItemImage')
      if img && img['src']
        # Decode HTML entities
        url = img['src'].gsub('&#x2F;', '/').gsub('&#x3D;', '=')
        return url
      end

      # Also check href attribute
      if img && img['href']
        url = img['href'].gsub('&#x2F;', '/').gsub('&#x3D;', '=')
        return url
      end

      nil
    end

    # rubocop:disable Naming/PredicateMethod
    def extract_consumable_flag(element)
      # Check for consumable icon with lpActive class (only active items have lpActive)
      # Try CSS selector first - Nokogiri should handle multiple classes
      consumable_active = element.at_css('i.lpSprite.lpConsumable.lpActive')
      return true if consumable_active

      # Fallback: check class attribute directly
      consumable_icon = element.at_css('i.lpSprite.lpConsumable')
      return false unless consumable_icon

      class_attr = consumable_icon['class'].to_s
      # Check if lpActive appears in the class string (handles extra spaces)
      return true if class_attr.include?('lpActive')

      # Explicitly return false to ensure boolean type
      false
    end
    # rubocop:enable Naming/PredicateMethod

    # rubocop:disable Naming/PredicateMethod
    def extract_worn_flag(element)
      # Check for worn icon with lpActive class (only active items have lpActive)
      # Try CSS selector first - Nokogiri should handle multiple classes
      worn_active = element.at_css('i.lpSprite.lpWorn.lpActive')
      return true if worn_active

      # Fallback: check class attribute directly
      worn_icon = element.at_css('i.lpSprite.lpWorn')
      return false unless worn_icon

      class_attr = worn_icon['class'].to_s
      # Check if lpActive appears in the class string (handles extra spaces)
      return true if class_attr.include?('lpActive')

      # Explicitly return false to ensure boolean type
      false
    end
    # rubocop:enable Naming/PredicateMethod
  end
end
