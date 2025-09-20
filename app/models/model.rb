# frozen_string_literal: true

class Model < ApplicationRecord
  include PlayerQueries
  include ReleaseQueries
  include TeamQueries
  include TournamentQueries

  has_many :true_dls, dependent: :destroy

  def cache_namespace
    name
  end
end
