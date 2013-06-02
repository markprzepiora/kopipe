module Kopipe
  module FieldCopiers
    module Attributes
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def copies_attributes(*names)
          add_copier { copy_attributes(names) }
        end
      end

      def copy_attributes(keys)
        keys.each do |key|
          target.send(:"#{key}=", source.send(key))
        end
      end
    end
  end
end
