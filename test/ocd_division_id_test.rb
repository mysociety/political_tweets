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

  describe '#level' do
    let(:id) { 'ocd-division/country:us/state:ky/county:bourbon_county' }
    subject { OcdDivisionId.new(id) }
    it 'returns the requested level of the id' do
      assert_equal id, subject.level(2)
      assert_equal 'ocd-division/country:us/state:ky', subject.level(1)
      assert_equal 'ocd-division/country:us', subject.level(0)
    end
  end
end

describe OcdDivsionIdSet do
  describe '#max_level' do
    it 'returns the max level in all ids' do
      ids = %w(
        ocd-division/country:ht/departement:sud/arrondissement:port-salut/circonscription:1
        ocd-division/country:ht/departement:sud/arrondissement:port-salut
        ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:1
        ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:2
        ocd-division/country:ht/departement:nord-est
      ).map { |id| OcdDivisionId.new(id) }
      set = OcdDivsionIdSet.new(*ids)
      assert_equal 3, set.max_level
    end
  end

  it 'picks the common member in the set' do
    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:wyandotte_county')
    set = OcdDivsionIdSet.new(id, id2)
    assert_equal 1, set.common_level

    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id3 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:adair_county')
    set = OcdDivsionIdSet.new(id, id2, id3)
    assert_equal 2, set.common_level

    id = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id2 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:bourbon_county')
    id3 = OcdDivisionId.new('ocd-division/country:us/state:ky/county:adair_county')
    id4 = OcdDivisionId.new('ocd-division/country:us/state:ky/boobar:adair_county')
    set = OcdDivsionIdSet.new(id, id2, id3, id4)
    assert_equal 2, set.common_level

    ids = %w(
      ocd-division/country:ht/departement:sud/arrondissement:port-salut/circonscription:1
      ocd-division/country:ht/departement:sud/arrondissement:port-salut/circonscription:2
      ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:1
      ocd-division/country:ht/departement:sud/arrondissement:côteaux/circonscription:2
      ocd-division/country:ht/departement:nord-est/arrondissement:fort-liberté/circonscription:1
    ).map { |id| OcdDivisionId.new(id) }
    set = OcdDivsionIdSet.new(*ids)
    assert_equal 2, set.common_level
  end
end
