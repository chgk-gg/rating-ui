class HealthcheckController < ApplicationController
  def ping
    head :ok
  end
end
