module SwaggerYard
  class Authorization
    attr_reader :pass_as, :key
    attr_writer :name

    def self.from_yard_object(yard_object)
      new(yard_object.types.first, yard_object.name, yard_object.text)
    end

    def initialize(type, pass_as, key)
      @type = type
      @pass_as = pass_as
      @key = key
    end

    # the spec suggests most auth names are just the type of auth
    def name
      @name ||= [@pass_as, @key].join('_').downcase.tr('-', '_')
    end

    def type
      case @type
      when 'api_key'
        'apiKey'
      when 'basic_auth'
        'basicAuth'
      end
    end

    def to_h
      { 'type' => type,
        'name' => @key,
        'in'   => @pass_as }
    end
  end
end
