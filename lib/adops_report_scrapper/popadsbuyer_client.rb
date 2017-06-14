require 'date'
require_relative 'base_client'
require 'rest-client'

class AdopsReportScrapper::PopadsbuyerClient < AdopsReportScrapper::BaseClient
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
    date_str = @date.strftime('%Y-%m-%d')
    time_zone_id = 'America%2FNew_York'

    response = RestClient.post "https://www.popads.net/api/report_advertiser?key=#{@secret}&zone=#{time_zone_id}&start=#{date_str}%2000%3A00&end=#{date_str}%2023%3A59&groups=campaign,datetime%3Aday", {}

    data = JSON.parse response
    unless data[0]
      @data = []
      return
    end
    data = data['rows']
    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end

  def scrap_hourly
    date_str = @date.strftime('%Y-%m-%d')
    time_zone_id = 'America%2FNew_York'

    response = RestClient.post "https://www.popads.net/api/report_advertiser?key=#{@secret}&zone=#{time_zone_id}&start=#{date_str}%2000%3A00&end=#{date_str}%2023%3A59&groups=datetime%3Ahour", {}

    data = JSON.parse response
    unless data[0]
      @data = []
      return
    end
    data = data['rows']
    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end
end