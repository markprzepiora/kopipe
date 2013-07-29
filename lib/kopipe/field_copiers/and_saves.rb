module Kopipe
  module FieldCopiers
    module AndSaves
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def and_saves
          add_copier{ target.save! }
        end

        def and_saves_without_validations
          add_copier{ target.save validate: false }
        end
      end
    end
  end
end
