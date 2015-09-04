class OcdDivisionId
  class InvalidDivisionId < StandardError; end

  attr_reader :division_id
  attr_reader :types
  attr_reader :parts

  def initialize(division_id)
    @division_id = division_id
    raise InvalidDivisionId unless valid?
    @parts = division_id.split('/')[1..-1]
    @types = {}
    @parts.each do |type_pair|
      type, type_id = type_pair.split(':')
      @types[type.to_sym] = type_id
    end
  end

  alias :to_s :division_id

  def valid?
    division_id.respond_to?(:split) &&
      division_id.split('/').first == 'ocd-division'
  end

  def id_for(type)
    return unless types.keys.include?(type)
    id = 'ocd-division'
    types.each do |type_name, type_id|
      id += "/#{[type_name, type_id].join(':')}"
      break if type_name == type
    end
    id
  end
end

class OcdDivsionIdSet
  include Enumerable

  def initialize(*ids)
    @ids = ids
  end

  def each
    @ids.each { |id| yield id }
  end

  # Need to find the common type which all ids have
  def common_type
    known_types = []
    each { |id| known_types.push(*id.types.keys) }
    known_types.uniq.reverse.find do |type|
      groups = group_by { |id| id.id_for(type) }
      groups.values.any? { |members| members.length > 1 }
    end
  end
end
