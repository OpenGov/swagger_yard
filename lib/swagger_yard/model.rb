module SwaggerYard
  #
  # Carries id (the class name) and properties for a referenced
  #   complex model object as defined by swagger schema
  #
  class Model
    attr_reader :id, :discriminator, :inherits

    def self.from_yard_object(yard_object)
      new.tap do |model|
        model.parse_tags(yard_object)
      end
    end

    def self.mangle(name)
      name.gsub(/[^[:alnum:]_]+/, '_')
    end

    def initialize
      @properties = []
      @inherits = []
    end

    def valid?
      !id.nil?
    end

    def parse_tags(yard_object)
      yard_object.tags.each do |tag|
        if tag.nil?
          SwaggerYard.config.logger.fatal("Yard Object has a nil tag in file `#{yard_object.file}` near line #{yard_object.line}")
          next
        end

        case tag.tag_name
        when 'model'
          @id = Model.mangle(tag.text)
        when 'property'
          @properties << Property.from_tag(tag)
        when 'discriminator'
          prop = Property.from_tag(tag)
          @properties << prop
          @discriminator ||= prop.name
        when 'inherits'
          @inherits << Model.mangle(tag.text)
        else
          SwaggerYard.config.logger.warn("Tag, #{tag.tag_name} not recognized in file `#{yard_object.file}` near line #{yard_object.line}")
        end
      end

      self
    end

    def inherits_references
      @inherits.map do |name|
        {
          '$ref' => "#/definitions/#{name}"
        }
      end
    end

    def to_h
      h = {
        'type' => 'object',
        'properties' => Hash[@properties.map { |p| [p.name, p.to_h] }]
      }

      h['required'] = @properties.select(&:required?).map(&:name) if @properties.detect(&:required?)
      h['discriminator'] = @discriminator if @discriminator

      # Polymorphism
      h = { 'allOf' => inherits_references + [h] } unless @inherits.empty?

      # Description
      h['description'] = @description if @description

      h
    end
  end
end
