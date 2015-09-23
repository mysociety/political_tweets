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

  def level(number)
    'ocd-division/' + parts[0..number].join('/')
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

  def max_level
    max { |a, b| a.parts.length <=> b.parts.length }.parts.length - 1
  end

  # Need to find the common type which all ids have
  def common_level
    max_level.downto(0) do |level|
      groups = group_by { |id| id.level(level) }
      return level if groups.values.any? { |members| members.length > 1 }
    end
  end
end
