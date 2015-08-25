class OcdDivisionId
  class InvalidDivisionId < StandardError; end

  attr_reader :division_id
  attr_reader :types

  def initialize(division_id)
    @division_id = division_id
    raise InvalidDivisionId unless valid?
    parts = division_id.split('/')[1..-1]
    @types = {}
    parts.each do |type_pair|
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
