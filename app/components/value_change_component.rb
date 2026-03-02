class ValueChangeComponent < ViewComponent::Base
  def initialize(change:)
    @change = change
    @value_change = value_change
  end

  def value_change
    return if @change.blank?
    return if @change == 0

    if @change > 0
      "+#{@change}"
    else
      @change.to_s.gsub("-", "−")
    end
  end
end
