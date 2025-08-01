# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: {writing: :primary, reading: :replica}
end
