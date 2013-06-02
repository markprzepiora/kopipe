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
      end
    end
  end
end
