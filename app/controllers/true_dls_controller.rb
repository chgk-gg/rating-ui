# frozen_string_literal: true

class TrueDlsController < ApplicationController
  def recalculate
    ActiveRecord::Base.connected_to(role: :writing) do
      TrueDLForAllTournamentsJob.perform_later(params_model)
    end
    redirect_to :root
  end

  def params_model
    params.require(:model)
  end
end
