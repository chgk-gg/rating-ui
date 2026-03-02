class PlaceChangeComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(place:, previous_place:)
    @place = place
    @previous_place = previous_place
    @difference = place_difference
  end

  def place_difference
    return if @place.blank?
    return if @previous_place.blank?
    return if @place == @previous_place

    if @previous_place > @place
      "↑#{round_place(@previous_place - @place)}"
    else
      "↓#{round_place(@place - @previous_place)}"
    end
  end
end
