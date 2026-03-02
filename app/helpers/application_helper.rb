module ApplicationHelper
  def round_place(place)
    (place.to_i == place) ? place.to_i : place.to_s.gsub(".", ",")
  end

  def round_true_dl(true_dl)
    true_dl&.to_fs(:rounded, precision: 2)
  end
end
