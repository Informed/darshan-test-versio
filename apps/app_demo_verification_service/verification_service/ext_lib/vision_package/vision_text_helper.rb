module VisionPackage
  module VisionTextHelper
    def text_to_dollar_amount(amount_str)
      return unless amount_str.present?
      amount_str = clean_decimal_numbers(amount_str)
      dollar_str = convert_periods_and_commas_if_necessary(amount_str.tr(' ', '')).gsub(/[$,sS_*:]/, '')
      negative_dollar_str?(dollar_str) ? -dollar_str.gsub(/[()]/, '').to_f : dollar_str.to_f
    end

    def negative_dollar_str?(str)
      str.end_with?('-') || str.match?(/\(.*\)$/)
    end

    def text_to_hourly_rate(str)
      str.tr(':', '.').to_f.round(2)
    end

    def text_to_hours(str)
      str = str.gsub(/[a-z]/i, '')
      return str.to_f.round(2) unless str.include?(':') || str.to_f > 200 || str.to_i.zero?
      str = convert_colon_to_period(str).to_f
      str.round(2) if str < 200
    end

    def convert_colon_to_period(str)
      return str unless str.include?(':')
      segmented = str.split(':')
      segmented.second.to_f > 59 ? str.tr(':', '.').to_f.round(2).to_s : (segmented.first.to_f + segmented.second.to_f.fdiv(60)).round(2).to_s # rubocop:disable Layout/LineLength
    end

    def clean_decimal_numbers(str)
      [' ', ':', '-'].each do |delimiter|
        last_index = str.rindex(delimiter)
        return "#{str.first(last_index)}.#{str.last(2)}" if last_index&.positive? && (last_index + 3) == str.length
      end
      str
    end

    def convert_periods_and_commas_if_necessary(str)
      first_pass = convert_periods_to_commas(convert_commas_to_periods(str)).tr(';', ',')
      # We've already converted all but the last period. If we still need to,
      # (e.g. there was only one and it's followed by 3 digits), this will do it
      first_pass.match?(/^\$\d{1,3}\.\d{3}$/) ? first_pass.tr('.', ',') : first_pass
    end

    # Converts all the periods except the last one to comma
    def convert_periods_to_commas(str)
      last_index = str.rindex('.')
      last_index.present? ? str[0...last_index].tr('.', ',') + str[last_index...str.length] : str
    end

    # Converts the cents following comma to a period
    def convert_commas_to_periods(str)
      cent_separator = /[,\_]/
      return str unless str.match?(/#{cent_separator}\d{2}[)-]?$/)
      last_index = str.rindex(cent_separator)
      str[0...last_index] + str[last_index...str.length].gsub(cent_separator, '.')
    end

    def text_to_date(text)
      if text.match?(/[a-z]/i)
        match_data = text.match(Regexp.union(RegexConstants::DDMONTHYY, RegexConstants::MONTHDDYY))
        if match_data.present?
          begin
            return Date.parse(match_data.values_at('month', 'day', 'year').join('-'))
          rescue ArgumentError
            nil
          end
        end
      end
      match_data = text.match(RegexConstants::ALL_DATE)
      generate_date(*match_data.values_at('month', 'day', 'year')) if match_data.present?
    end

    def partial_text_to_date(text, compare_date)
      year = compare_date.year
      match = text.match(RegexConstants::CAPTURE_MMDD)
      date = generate_date(match[1], match[2], year) if match.present?
      date ||= Date.parse("#{text} #{year}") if text.match?(RegexConstants::MONTHDD)
      return if date.nil?

      year_start = 3
      year_end = 10
      month = compare_date.month
      month_diff = (date.month - month).abs

      date += 1.years if month >= year_end && month_diff > 6
      date -= 1.years if month <= year_start && month_diff > 6
      date
    rescue
      nil
    end

    def generate_date(m, d, y)
      m, d, y = [m, d, y].map { |x| x.to_s.upcase.tr('O', '0').tr('B', '8').tr('S', '5') }
      y_pattern = y.to_i < 100 ? 'y' : 'Y'
      Date.strptime("#{m.to_i}-#{d.to_i}-#{y.to_i}", "%m-%d-%#{y_pattern}")
    rescue
      nil
    end

    def text_to_int(str)
      str.gsub(/\.|\,/i, '').to_i unless str.match?(/[a-zA-Z]/i)
    end

    def text_to_ssn(text)
      ssn = text.gsub(/\D/, '')
      return ssn if ssn.size == 9 || ssn.size == 4
      return if ssn.size > 13
      match_data = text.match(RegexConstants::CAPTURE_FULL_SSN)
      match_data&.values_at(1, 2, 3)&.join
    end

    def text_to_vin(text)
      vin = text.gsub(/[ØO]/, '0').tr('I', '1')
      vin[8] = '5' if vin[8] == 'S'
      vin
    end

    def text_to_percent(text)
      text = text.tr('%', '')
      text_to_dollar_amount(text)
    end

    def text_to_odometer(text)
      odometer = text_to_dollar_amount(text.tr('.', ','))
      odometer.to_i if finite?(odometer)
    end

    def finite?(text)
      text.infinite?.nil?
    end
  end
end
