module Kopipe
  module FieldCopiers
    module HasMany
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def copies_has_many(*options)
          add_copier { copy_has_many(*options) }
        end
      end

      def copy_has_many(name, options = {})
        copier_class = options[:deep]
        polymorphic  = options[:polymorphic]
        namespace    = options[:namespace]

        source_has_many = source.send(name)
        target_has_many = target.send(name)

        source_has_many.find_each do |source_child|
          target_child = deep_copy(source_child,
                                   copier_class: copier_class,
                                   polymorphic: polymorphic,
                                   namespace: namespace) {
            if polymorphic
              target_has_many.build type: source_child.class.to_s
            else
              target_has_many.build
            end
          }
        end
      end
    end
  end
end
