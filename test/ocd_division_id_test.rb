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

describe OcdDivsionIdSet do
  it 'picks the common member in the set' do
    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:wyandotte_county')
    set = OcdDivsionIdSet.new(id, id2)
    assert_equal :state, set.common_type

    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id3 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:adair_county')
    set = OcdDivsionIdSet.new(id, id2, id3)
    assert_equal :county, set.common_type

    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id3 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:adair_county')
    id4 = OcdDivisionId.new('ocd-division/country:us/state:ky/boobar:adair_county')
    set = OcdDivsionIdSet.new(id, id2, id3, id4)
    assert_equal :state, set.common_type

    ids = %w(
      ocd-division/country:ht/departement:sud/arrondissement:port-salut/circonscription:1
      ocd-division/country:ht/departement:sud/arrondissement:port-salut/circonscription:2
      ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:1
      ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:2
      ocd-division/country:ht/departement:nord-est/arrondissement:fort-liberté/circonscription:1
    ).map { |id| OcdDivisionId.new(id) }
    set = OcdDivsionIdSet.new(*ids)
    assert_equal :arrondissement, set.common_type
  end
end
