module GeocodeHelper
  extend HttpProxyHelper
  using Refinements::HashTransformations

  GEOCODE_SERVICE_URL ||= ENV.fetch('GEOCODER_SERVICE', 'https://geocoder.driveinformed.com/geocode').freeze

  def self.geocode(loc, options = {})
    force = options.fetch(:force, false)

    return Geokit::GeoLoc.new(success: false) unless loc.present?
    payload = { address: loc, force: force }
    result = post_json(GEOCODE_SERVICE_URL, params: payload, headers: { 'X_CUSTOM_AUTH': ENV.fetch('GEOCODE_TOKEN', nil) }, timeout: 2, disable_proxy: true, raise_if_not_success: true) # rubocop:disable Layout/LineLength
    GeocodeHelper.deserialize_helper(result['geocoded_result'].deep_symbolize_keys)
  rescue HttpProxyHelper::Non200Error, Faraday::TimeoutError, HttpProxyHelper::CustomFaradayError => e
    Honeybadger.notify(e) unless e.message.match?(/request timed out/)
    # Backup in case this new service goes down
    # I expect to be able to remove this eventually, I'm just paranoid [1/22/2021]
    Geokit::Geocoders::GoogleGeocoder.geocode(loc)
  end

  def self.deserialize_helper(obj)
    case obj
    when Hash
      case obj[:class_name]
      when 'Geokit::GeoLoc'
        geo = Geokit::GeoLoc.new
        obj.each do |k, v|
          geo.send("#{k}=", GeocodeHelper.deserialize_helper(v)) if geo.respond_to?("#{k}=")
        end
        geo
      when 'Geokit::Bounds'
        Geokit::Bounds.new(*GeocodeHelper.deserialize_helper(obj.values_at(:ne, :sw)))
      else
        Geokit::LatLng.new(*obj.values_at(:lat, :lng))
      end
    when Array
      obj.map { |sub_obj| GeocodeHelper.deserialize_helper(sub_obj) }
    else
      obj
    end
  end
end
