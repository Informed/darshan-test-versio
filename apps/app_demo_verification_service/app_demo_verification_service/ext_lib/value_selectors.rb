module ValueSelectors
  def pick_most_recent_date(date1, date2)
    return unless date1.present? || date2.present?
    return date1 unless date2.present?
    return date2 unless date1.present?
    date1.to_date > date2.to_date ? date1 : date2
  end
end
