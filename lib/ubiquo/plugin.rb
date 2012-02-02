module Ubiquo
  class Plugin

    cattr_accessor :registered

    self.registered ||= {}

    def self.register(name, options = { },  &block)
      engine = (options[:plugin] || name.to_s.classify.constantize)::Engine
      Ubiquo::Settings.create_context(name)
      Ubiquo::Settings.context(name, &block)
      self.registered[name] = engine
    end

    def self.registered?(name)
      registered.include?(name)
    end

    def self.registered_plugins
      registered.keys
    end

    def self.registered_engines
      registered.values
    end

    def setting(*args)
      Ubiquo::Settings.add(args)
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
