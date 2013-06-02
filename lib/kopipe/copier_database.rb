module Kopipe
  class CopierDatabase
    def initialize(sources_to_targets = {})
      @sources_to_targets = sources_to_targets
    end

    def add(copier)
      @sources_to_targets[copier.source] = copier.target
    end

    def has_source?(source)
      @sources_to_targets.has_key?(source)
    end

    def fetch_target_by_source(source, &block)
      @sources_to_targets.fetch(source, &block)
    end

    def count
      @sources_to_targets.count
    end
  end
end
