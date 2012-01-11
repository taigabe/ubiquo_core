module Ubiquo
  class Plugin

    cattr_accessor :registered

    self.registered ||= {}

    def self.register(name, &block)
      Ubiquo::Config.create_context(name)
      Ubiquo::Config.context(name, &block)
      self.registered[name] = name
    end

  end

  class PluginSpec

    class MissingName < StandardError; end
    class MissingVersion < StandardError; end

    attr_accessor :name, :version, :url, :desc, :dependencies

    def initialize(&block)
      @url = @desc = ''
      @dependencies = {}
      yield self
      raise MissingName unless name
      raise MissingVersion unless version
    end
  end
end
