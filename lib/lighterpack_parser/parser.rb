# frozen_string_literal: true

require 'nokogiri'
require 'httparty'

module LighterpackParser
  class Parser
    def initialize(html: nil, url: nil)
      @html = if url
                fetch_html(url)
              elsif html
                html
              else
                raise ArgumentError, 'Either html or url must be provided'
              end
    end

    def parse
      doc = Nokogiri::HTML(@html)

      {
        name: extract_list_name(doc),
        description: extract_list_description(doc),
        categories: extract_categories(doc)
      }
    end

    private

    def fetch_html(url)
      response = HTTParty.get(url, timeout: 30)
      raise "Failed to fetch URL: #{response.code}" unless response.success?
      response.body
    end

    def extract_list_name(doc)
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

    def extract_list_description(doc)
      # Lighterpack doesn't seem to have a list description in the HTML
      # Could be in meta tags
      meta_desc = doc.at_css('meta[name="description"]')
      return meta_desc['content'] if meta_desc && meta_desc['content']

      nil
    end

    def extract_categories(doc)
      categories = []

      # Lighterpack structure: ul.lpCategories > li.lpCategory
      doc.css('ul.lpCategories > li.lpCategory').each do |category_element|
        # Category name is in h2.lpCategoryName
        category_header = category_element.at_css('h2.lpCategoryName')
        next unless category_header

        category_name = category_header.text.strip
        next if category_name.empty?

        # Description is typically in the category name itself (in parentheses)
        description = extract_category_description(category_name)

        # Find items in this category
        items = extract_items_for_category(category_element)

        categories << {
          name: category_name,
          description: description,
          items: items
        }
      end

      categories
    end

    def extract_category_description(category_name)
      # Description is often in parentheses in the category name
      # e.g., "Big 3 (Pack, Tent, Sleep System)"
      match = category_name.match(/\(([^)]+)\)/)
      return match[1] if match

      nil
    end

    def extract_items_for_category(category_element)
      items = []

      # Items are in ul.lpItems within the category
      items_list = category_element.at_css('ul.lpItems')
      return items unless items_list

      # Extract items (skip header row)
      items_list.css('li.lpItem').each do |item_element|
        item = extract_item(item_element)
        items << item if item && item[:name]
      end

      items
    end

    def extract_item(element)
      # Extract item data from the element
      # Lighterpack items have: name, weight, quantity, description, image
      name = extract_item_name(element)
      return nil unless name

      weight_data = extract_weight(element)
      quantity = extract_quantity(element)
      description = extract_item_description(element)
      image_url = extract_image_url(element)
      consumable = extract_consumable_flag(element)
      worn = extract_worn_flag(element)

      {
        name: name,
        description: description,
        weight: weight_data[:weight_grams],
        quantity: quantity,
        image_url: image_url,
        consumable: consumable,
        worn: worn
      }
    end

    def extract_item_name(element)
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
          unit = unit_text if ['oz', 'lb', 'g', 'kg'].include?(unit_text)
        end

        weight_grams = convert_to_grams(weight_value, unit)
        return { weight_grams: weight_grams, original_unit: unit }
      end

      { weight_grams: 0.0, original_unit: 'g' }
    end

    def convert_to_grams(value, unit)
      case unit.downcase
      when 'oz'
        value * 28.3495
      when 'lb'
        value * 453.592
      when 'g'
        value
      when 'kg'
        value * 1000
      else
        value # Default to assuming grams
      end
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

    def extract_item_description(element)
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
      
      false
    end

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
      
      false
    end
  end
end
