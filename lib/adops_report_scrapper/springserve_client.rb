require 'date'
require_relative 'base_client'
require 'rest-client'

class AdopsReportScrapper::SpringserveClient < AdopsReportScrapper::BaseClient
  private

  def init_client
    fail 'please specify springserve account_id' unless @options['account_id']
    @account_id = @options['account_id']
  end

  def before_quit_with_error
  end

  def scrap
    date_str = @date.strftime('%Y-%m-%d')

    response = RestClient.post "https://video.springserve.com/api/v0/auth", email: @login, password: @secret
    data = JSON.parse response
    token = data['token']

    headers = { content_type: :json, accept: :json, authorization: token }

    response = RestClient.post "https://video.springserve.com/api/v0/report", { timezone: 'America/New_York', date_range: 'Yesterday', interval: 'cumulative', dimensions: ['country', 'supply_tag_id'], account_id: @account_id }.to_json, headers
    data = JSON.parse response
    header = data[0].keys
    @data = [header]
    @data += data.map do |datum|
      header.map { |key| datum[key] }
    end
  end
end