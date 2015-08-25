require 'test_helper'
require 'ocd_division_id'

describe OcdDivisionId do
  describe '#types' do
    subject { OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county') }
    it 'returns the type requested' do
      assert_equal 'us', subject.types[:country]
      assert_equal 'ky', subject.types[:state]
      assert_equal 'bourbon_county', subject.types[:county]
    end
  end

  describe '#id_for' do
    let(:id) { 'ocd-division/country:us/state:ky/county:bourbon_county' }
    subject { OcdDivisionId.new(id) }
    it 'returns part of the division id' do
      assert_equal id, subject.id_for(:county)
      assert_equal 'ocd-division/country:us/state:ky', subject.id_for(:state)
      assert_equal 'ocd-division/country:us', subject.id_for(:country)
    end
  end
end
