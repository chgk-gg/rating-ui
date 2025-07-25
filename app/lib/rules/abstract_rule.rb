# frozen_string_literal: true

module Rules
  class AbstractRule
    def self.description
      raise NotImplementedError, "You must implement the description method in a subclass"
    end

    def self.offenders
      raise NotImplementedError, "You must implement the offenders method in a subclass"
    end

    def self.message
      "#{description}:\n#{offenders}"
    end
  end
end
