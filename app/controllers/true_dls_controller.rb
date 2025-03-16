# frozen_string_literal: true

class TrueDlsController < ApplicationController
  def recalculate
    TrueDLForAllTournamentsJob.perform_later(params_model)
    redirect_to :root
  end

  def params_model
    params.require(:model)
  end
end
