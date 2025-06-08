# frozen_string_literal: true

class MaterializedViewsController < ApplicationController
  def recreate_views
    ActiveRecord::Base.connected_to(role: :writing) do
      MaterializedViewsJob.perform_later(params_model)
    end
    redirect_to :root
  end

  def params_model
    Model.find_sole_by(name: params.require(:model))&.name
  end
end
