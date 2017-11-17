require 'date'
require_relative 'base_client'
require 'rest-client'

class AdopsReportScrapper::RevcontentClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date < Date.today
    false
  end

  private

  def init_client
  end

  def before_quit_with_error
  end

  def scrap
    date_str = @date.strftime('%Y-%m-%d')

    headers = { cache_control: 'no-cache' }

    response = RestClient.post 'https://api.revcontent.io/oauth/token', { grant_type: 'client_credentials', client_id: @login, client_secret: @secret }, headers
    data = JSON.parse response
    token = data['access_token']

    headers = { authorization: "Bearer #{token}", content_type: :json, cache_control: 'no-cache' }

    data = []

    %w(desktoplg desktop tablet mobile unknown).each do |device|
      response = RestClient.get "https://api.revcontent.io/stats/api/v1.0/widgets?date_from=#{date_str}&date_to=#{date_str}&device=#{device}", headers
      _data = JSON.parse response
      _data = _data['data']
      _data.each { |datum| datum['device'] = device }
      data += _data
    end

    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end
end