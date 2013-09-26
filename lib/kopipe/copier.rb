require 'active_support/core_ext/class'
require 'active_support/core_ext/module'
require 'kopipe/copier_database'
require 'kopipe/field_copiers/all'

module Kopipe
  class Copier
    # Copier#source is the object to be copied.
    attr_reader :source

    # Copier#target is the object into which the copy is to be performed.
    attr_reader :target

    # Copier.copiers is an array of procs to be executed in order to copy the
    # source object.
    class_attribute :copiers
    self.copiers = []

    # Include various pre-defined copiers to handle common operations.
    include FieldCopiers::Custom
    include FieldCopiers::Attributes
    include FieldCopiers::BelongsTo
    include FieldCopiers::HasAndBelongsToMany
    include FieldCopiers::AndSaves

    # Public: Initialize a new Copier.
    #
    # source - The "source" ActiveRecord::Base object to be copied.
    # target - The "target" object into which the source should be copied.
    #          (default: source.class.new)
    # db     - A CopierDatabase object used to keep track of already-copied
    #          objects. As part of the public interface, this should generally
    #          never be specified explicitly. (default: CopierDatabase.new)
    #
    # Examples
    #
    #   class FooCopier < Kopipe::Copier; end
    #   foo = Foo.find(1)
    #
    #   copier = FooCopier.new(foo)
    #   # The above results in copier.target == Foo.new
    #
    #   target_foo = Foo.new(name: "Bar")
    #   copier     = FooCopier.new(foo, target: target_foo)
    #   # The above results in copier.target equal to target_foo
    def initialize(source, target: nil, db: CopierDatabase.new)
      @db     = db
      @source = source
      @target = target
      @target ||= source.class.new

      @db.add(self)
    end

    # Public: Copy the source object.
    #
    # Returns the duplicated object.
    def copy!
      self.copiers.each do |block|
        self.instance_eval(&block)
      end
      target
    end

    # Private: Add a copier to be run when copying the current subclass (and
    # children) of Kopipe::Copier. Although not actually private, this should
    # only be called by copiers defined in FieldCopiers.
    #
    # Returns the new list of copiers.
    def self.add_copier(&block)
      self.copiers += [block]
    end

    private

    # Private: Fetch or create a copy of another record in the system.
    #
    # source       - The object to be copied.
    # copier_class - The Kopipe::Copier subclass to use to copy the source
    #                object. Can be specified as the class itself or with a
    #                string. Ignored if :polymorphic => true.
    #                (default: IdentityCopier)
    # polymorphic  - If true, determine copier_class dynamically by looking up
    #                "#{source.class.name}Copier"
    # namespace    - When :polymorphic => true, optionally look up the copier
    #                class under the given module. (default: false)
    # block        - An optional block that can be used to specify the target
    #                object to be built. This block will only be executed if
    #                the source object has not already been marked as copied.
    #                Its return value will be used as the target parameter to
    #                the copier class initializer.
    #
    # Examples
    #
    #   bar_copy = deep_copy(@source.bar, copier_class: BarCopier) { @target.build_bar }
    #   # The above may be part of a FooCopier, where a Foo belongs to a Bar.
    #   # This would either fetch the previously-copied Bar, or copy it into
    #   # @target.build_bar using BarCopier if it has not yet been copied.
    def deep_copy(source, copier_class: nil, polymorphic: false, namespace: false, &block)
      return nil if source.nil?

      if polymorphic
        copier_class = get_polymorphic_copier_class(source, namespace)
      else
        copier_class = get_constant(copier_class) { IdentityCopier }
      end

      @db.fetch_target_by_source(source) do
        target = target = block.call if block
        copier_class.new(source, db: @db, target: target).copy!
      end
    end

    def shallow_copy(source)
      deep_copy(source, copier_class: IdentityCopier)
    end

    def get_polymorphic_copier_class(source, namespace = nil)
      get_constant("#{source.class}Copier", namespace)
    end

    def get_constant(const, namespace = nil)
      if namespace
        namespace = get_constant(namespace)
      else
        namespace = self.class.parent
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

  # A 'No-Op' copier that does nothing to the source object, except simply add
  # it to the database to mark it as copied.
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
