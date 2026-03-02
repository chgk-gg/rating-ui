class TrueDlsController < ApplicationController
  def recalculate
    TrueDLForRecentTournamentsJob.perform_later(params_model, 30)
    redirect_to :root
  end

  def params_model
    params.require(:model)
  end
end
