# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'spec_helper'

RSpec.describe LighterpackParser::Item do
  subject(:item) do
    described_class.new(
      name: 'Trail runners',
      description: 'Worn on approach',
      weight: 320.5,
      total_weight: 641.0,
      quantity: 2,
      image_url: 'https://example.com/item.png',
      consumable: true,
      total_consumable_weight: 641.0,
      worn: true,
      worn_quantity: 1,
      total_worn_weight: 320.5
    )
  end

  describe 'predicate helpers' do
    it 'keeps the boolean reader methods available as predicates' do
      expect(item.worn?).to be(true)
      expect(item.consumable?).to be(true)
    end
  end

  describe '#to_h' do
    it 'returns the same public hash representation' do
      expect(item.to_h).to eq(
        name: 'Trail runners',
        description: 'Worn on approach',
        weight: 320.5,
        total_weight: 641.0,
        quantity: 2,
        image_url: 'https://example.com/item.png',
        consumable: true,
        total_consumable_weight: 641.0,
        worn: true,
        worn_quantity: 1,
        total_worn_weight: 320.5
      )
    end
  end

  describe 'loading the file' do
    it 'does not emit method redefinition warnings' do
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        '-w',
        '-I',
        File.expand_path('../lib', __dir__),
        '-e',
        'require "lighterpack_parser/item"'
      )

      aggregate_failures do
        expect(status.success?).to be(true), stdout + stderr
        expect(stderr).not_to include('method redefined')
        expect(stderr).not_to include('previous definition of')
      end
    end
  end
end
