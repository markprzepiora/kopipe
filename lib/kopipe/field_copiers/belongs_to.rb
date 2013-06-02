module Kopipe
  module FieldCopiers
    module BelongsTo
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def copies_belongs_to(*options)
          add_copier { copy_belongs_to(*options) }
        end
      end

      def copy_belongs_to(name, options = {})
        source_belongs_to = source.send(name)
        target_belongs_to = deep_copy(source_belongs_to, copier_class: options[:deep]) {
          target.send(:"build_#{name}")
        }
        target.send :"#{name}=", target_belongs_to
      end
    end
  end
end
