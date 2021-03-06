class Travelport::Model::HotelProperty < Travelport::Model::Base

  attr_accessor :search_error,
                :property_address,
                :distance,
                :amenities,
                :hotel_chain,
                :hotel_code,
                :hotel_location,
                :name,
                :vendor_location_key,
                :hotel_transportation,
                :reserve_requirement,
                :participation_level,
                :availability,
                :featured_property

  class << self

    # Command: returns an array of HotelProperty matching the search criteria of +location+ and +options+.
    def search_availability(location, options)
      bridge.search_availability(location, options).try(:hotel_search_results) || []
    end

    def bridge
      @bridge ||= Travelport::Bridge::Hotel.new
    end

  end

  # Command: gets hotel rates response given +options+
  def rates(options)
    self.class.bridge.hotel_details(hotel_chain, hotel_code, options).try(:hotel_rate_details) || []
  end
end