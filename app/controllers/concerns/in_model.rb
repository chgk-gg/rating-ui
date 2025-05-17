# frozen_string_literal: true

module InModel
  DEFAULT_MODEL = "b"
  MISSING_MODEL_ERROR = "Модели с таким именем нет"

  def self.models_cache
    @models_cache ||= reload_model_cache!
  end

  def self.reload_model_cache!
    @models_cache = Model.all.index_by(&:name)
  end

  def current_model
    model_name = params[:model] || DEFAULT_MODEL
    InModel.models_cache[model_name]
  end

  def show_missing_model_error(_exception)
    render plain: MISSING_MODEL_ERROR, status: :bad_request
  end
end
