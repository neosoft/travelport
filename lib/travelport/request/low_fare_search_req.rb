module Travelport::Request
  class LowFareSearchReq < Base

    attr_accessor :sectors
    attr_accessor :adults
    attr_accessor :children
    attr_accessor :infants
    attr_accessor :cabin
    attr_accessor :provider_code

    default_for :adults, 1
    default_for :infants, 1
    default_for :children, 1
    default_for :provider_code, '1G'
    default_for :cabin, 'Economy'
    default_for :xmlns, 'http://www.travelport.com/schema/air_v36_0'
    default_for :xmlns_common, 'http://www.travelport.com/schema/common_v36_0'

    validates_presence_of :sectors
    validates_presence_of :adults

    validates_inclusion_of :cabin, in:[nil, 'Economy', 'Bussines', 'Premium Economy', 'First']

    validate :each_sector

    def request_body
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.BillingPointOfSaleInfo('OriginApplication' => billing_point_of_sale, 'xmlns' => xmlns_common)
          sectors.each do |sector|
            xml.SearchAirLeg {
              xml.SearchOrigin {
                xml.CityOrAirport('Code' => sector[:from], 'xmlns' => xmlns_common)
              }
              xml.SearchDestination {
                xml.CityOrAirport('Code' => sector[:to], 'xmlns' => xmlns_common)
              }
              xml.SearchDepTime('PreferredTime' => sector[:at].strftime('%Y-%m-%d'))
              unless cabin.nil?
                xml.AirLegModifiers {
                  xml.PreferredCabins {
                    xml.CabinClass('Type' => cabin, 'xmlns' => xmlns_common)
                  }
                }
              end
            }
          end
          xml.AirSearchModifiers {
            xml.PreferredProviders {
              if provider_code.is_a?(Array)
                provider_code.each {|code| xml.Provider('Code' => code, 'xmlns' => xmlns_common)}
              else
                xml.Provider('Code' => provider_code, 'xmlns' => xmlns_common)
              end

            }
          }
          adults.times { xml.SearchPassenger('Code' => 'ADT', 'xmlns' => xmlns_common)}
          children.times { xml.SearchPassenger('Code' => 'CNN', 'Age' => 10, 'xmlns' => xmlns_common)} unless children.nil?
          infants.times { xml.SearchPassenger('Code' => 'INF', 'Age' => 1, 'xmlns' => xmlns_common)} unless infants.nil?
        }
      end
      builder.doc.root.children.to_xml
    end

    def request_attributes
      super.except('Sectors', 'Cabin', 'Xmlns', 'Adults', 'Children', 'Infants', 'ProviderCode').update(:xmlns => xmlns)
    end

    protected
    def each_sector
      errors.add(:sectors, "can't be empty") if sectors.nil? || sectors.empty?
      sectors.each do |sector|
        errors.add(:sectors, "#{sector.inspect} should contain attribute :from") if sector[:from].nil?
        errors.add(:sectors, "#{sector.inspect} should contain attribute :to") if sector[:to].nil?
        errors.add(:sectors, "#{sector.inspect} should contain attribute :at") if sector[:at].nil?
        unless sector[:at].nil?
          errors.add(:sectors, "#{sector.inspect} attribute :at should be instance of Time") unless sector[:at].kind_of?(Time)
        end
      end unless sectors.nil?
    end
  end
end
