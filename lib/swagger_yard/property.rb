module SwaggerYard
  #
  # Holds the name and type for a single model property
  #
  class Property
    attr_reader :name, :description

    def self.from_tag(tag)
      name, options_string = tag.name.split(/[\(\)]/)

      options = options_string.to_s.split(',').map(&:strip)

      new(name, tag.types, tag.text, options)
    end

    def initialize(name, types, description, options)
      @name = name
      @description = description
      @required = options.include?('required')
      @nullable = options.include?('nullable')
      @type = Type.from_type_list(types)
    end

    def required?
      @required
    end

    def to_h
      @type.to_h.tap do |h|
        h['description'] = description if description
        if @nullable
          h['x-nullable'] = true
          h['type'] = [h['type'], 'null'] if h['type']
        end
      end
    end
  end
end
