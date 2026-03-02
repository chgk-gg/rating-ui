class APIController < ActionController::Base
  rescue_from ActiveRecord::StatementInvalid, with: :show_model_errors

  DEFAULT_PAGE_SIZE = 500

  def page
    (params[:page] || 1).to_i
  end

  def offset
    (page - 1) * page_size
  end

  def page_size
    (params[:page_size] || DEFAULT_PAGE_SIZE).to_i
  end

  def page_metadata(all_items_count)
    {
      current_page: page,
      pages: (all_items_count.to_f / page_size).ceil,
      all_items_count:
    }
  end

  def show_model_errors(exception)
    if current_model.nil?
      render_error_json(error: InModel::MISSING_MODEL_ERROR)
    else
      render_error_json(error: exception)
    end
  end

  def render_error_json(error:)
    render json: {error:}, status: :bad_request
  end

  def render_paged_json(metadata:, items:, all_items_count:)
    render json: metadata.merge(page_metadata(all_items_count)).merge({items:}), status: :ok
  end

  def render_json(metadata:, items:)
    render json: metadata.merge({items:}), status: :ok
  end
end
