require 'date'
require_relative 'base_client'
require 'rest-client'

class AdopsReportScrapper::IndexexchangeClient < AdopsReportScrapper::BaseClient
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
    date_str = @date.strftime('%Y-%m-%d')

    response = RestClient.post 'https://auth.indexexchange.com/auth/oauth/token', { 'username' => @login, 'key' => @secret }.to_json, { 'Content-Type' => 'application/json; charset=utf-8' }
    access_token = JSON.parse(response)['data']['accessToken']

    header = { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json; charset=utf-8' }

    response = RestClient.post 'https://api01.indexexchange.com/api/publishers/sites', '', header
    site_tag_map = JSON.parse(response)['data'].map { |e| [e['siteID'], e['name']] }.to_h

    response = RestClient.post 'https://api01.indexexchange.com/api/publishers/stats/earnings/open', { 'filters' => { 'startDate' => date_str, 'endDate' => date_str }, 'aggregation' => 'siteID' }.to_json, header
    data = JSON.parse(response)['data'].each do |datum|
      datum['siteTagName'] = site_tag_map[datum['aggregateID']]
    end

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
