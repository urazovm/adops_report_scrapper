require 'date'
require_relative 'base_client'
require 'rest-client'

class AdopsReportScrapper::AdsupplybuyerClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date < (Date.today + 1)
    false
  end

  def init_client
  end

  def before_quit_with_error
  end

  private

  def scrap
    if @options[:hourly]
      scrap_hourly
    else
      scrap_daily
    end
  end

  def scrap_daily
    date_str = @date.strftime('%-m/%-d/%Y')
    time_zone_id = 'Eastern Standard Time'

    response = RestClient.post "https://ui.adsupply.com/PublicPortal/Advertiser/#{@login}/Report/Export", SqlCommandId: '', ExportToExcel: 'False', IsOLAP: 'False', DateFilter: date_str, TimeZoneId: time_zone_id, Grouping: '1', 'DimAdvertiser.Value': "#{@login}~", 'DimAdvertiser.IsActive': 'True', 'DimMedia.Value': '', 'DimMedia.IsActive': 'True', ApiKey: @secret

    data = JSON.parse response
    unless data[0]
      @data = []
      return
    end
    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end

  def scrap_hourly
    date_str = @date.strftime('%-m/%-d/%Y')
    time_zone_id = 'Eastern Standard Time'

    response = RestClient.post "https://ui.adsupply.com/PublicPortal/Advertiser/#{@login}/Report/Export", SqlCommandId: '', ExportToExcel: 'False', IsOLAP: 'False', DateFilter: date_str, TimeZoneId: time_zone_id, Grouping: '0', ApiKey: @secret

    data = JSON.parse response
    unless data[0]
      @data = []
      return
    end
    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end
end