require 'logger'

module SwaggerYard
  class Logger < ::Logger
    def self.instance(pipe = STDOUT)
      @logger ||= new(pipe)
    end

    def initialize(pipe, *args)
      super(pipe, *args)
      self.level = DEBUG
      self.formatter = method(:format_log)
    end

    def format_log(sev, time, prog, msg)
      "[SwaggerYard-#{sev.downcase}]: #{msg}\n"
    end

  end
end
