module Kopipe
  module FieldCopiers
    module HasAndBelongsToMany
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def copies_has_and_belongs_to_many(*options)
          add_copier { copy_has_and_belongs_to_many(*options) }
        end
      end

      def copy_has_and_belongs_to_many(name, options = {})
        copier_class = options[:deep]
        polymorphic  = options[:polymorphic]
        namespace    = options[:namespace]

        source_has_many = source.send(name)
        target_array    = []

        source_has_many.find_each do |source_child|
          target_array << deep_copy(source_child,
                                    copier_class: copier_class,
                                    polymorphic: polymorphic,
                                    namespace: namespace)
        end

        target.send(:"#{name}=", target_array)
      end
    end
  end
end
