require 'active_support/core_ext/class'
require 'kopipe/copier_database'
require 'kopipe/field_copiers/all'

module Kopipe
  class Copier
    attr_reader :source
    attr_reader :target
    attr_reader :db

    class_attribute :copiers
    self.copiers = []

    def self.add_copier(&block)
      self.copiers += [block]
    end

    include FieldCopiers::Attributes
    include FieldCopiers::Custom
    include FieldCopiers::BelongsTo
    include FieldCopiers::HasAndBelongsToMany

    def initialize(source, target: nil, db: CopierDatabase.new)
      @db     = db
      @source = source
      @target = target
      @target ||= yield if block_given?
      @target ||= source.class.new

      db.add(self)
    end

    def copy!
      self.copiers.each do |block|
        self.instance_eval(&block)
      end
      target
    end

    def self.and_saves
      add_copier{ target.save! }
    end

    private

    def deep_copy(source, copier_class: nil, polymorphic: false, namespace: nil, &block)
      return nil if source.nil?

      if polymorphic
        copier_class = get_polymorphic_copier_class(source, namespace)
      else
        copier_class = get_constant(copier_class) { IdentityCopier }
      end

      db.fetch_target_by_source(source) do
        copier_class.new(source, db: db, &block).copy!
      end
    end

    def shallow_copy(source)
      deep_copy(source)
    end

    def get_polymorphic_copier_class(source, namespace = nil)
      get_constant("#{source.class}Copier", namespace)
    end

    def get_constant(const, namespace = nil)
      if namespace
        namespace = get_constant(namespace)
      else
        namespace = Object
      end

      if const.is_a? String
        namespace.const_get(const)
      elsif const
        const
      else
        yield if block_given?
      end
    end
  end

  class IdentityCopier < Copier
    def initialize(source, **options)
      options.delete :target
      super(source, target: source, **options)
    end

    def copy!
      target
    end
  end
end
