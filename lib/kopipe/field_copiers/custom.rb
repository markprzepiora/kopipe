module Kopipe
  module FieldCopiers
    module Custom
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def copies(&block)
          add_copier(&block)
        end
      end
    end
  end
end
