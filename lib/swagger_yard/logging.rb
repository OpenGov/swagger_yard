require 'logger'

module SwaggerYard
  class Logger < ::Logger
    def self.instance(pipe = STDOUT)
      @logger ||= new(pipe)
    end

    def initialize(pipe, *args)
      super(pipe, *args)
      self.level = @configuration.present? ? @configuration.log_level : FATAL  
      self.formatter = method(:format_log)
    end

    def format_log(sev, time, prog, msg)
      "[SwaggerYard-#{sev.downcase}]: #{msg}\n"
    end

  end
end
