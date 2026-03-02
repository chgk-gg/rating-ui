class Paging
  attr_reader :from, :to, :items_count

  def initialize(items_count:, from:, to:)
    @items_count = items_count
    @from = from
    @to = to
  end

  def display?
    (@to - @from + 1) < @items_count
  end

  def per_page
    return 100 if (to - from + 1) == 0

    to - from + 1
  end

  def last_page
    (items_count / per_page) + 1
  end
end
