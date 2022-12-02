module ValueFormatters
  def self.format_date(date)
    return '' unless date.present?
    date = date.to_date if date.is_a? String
    date.strftime('%m/%d/%Y')
  end

  def self.to_bool(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end
end
