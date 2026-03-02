class ReindexController < ApplicationController
  def reindex
    ModelIndexer.run

    render plain: "Последний реиндекс: #{Time.zone.now}"
  end
end
