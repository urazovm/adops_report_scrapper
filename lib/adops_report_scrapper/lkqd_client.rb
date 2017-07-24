require 'date'
require_relative 'base_client'
require 'securerandom'

class AdopsReportScrapper::LkqdClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 7
    false
  end

  private

  def login
    @client.visit 'https://ui.lkqd.com/login'
    @client.fill_in 'Username', :with => @login
    @client.fill_in 'Password', :with => @secret
    @client.click_button 'Sign In'
    begin
      @client.find :xpath, '//*[text()="Run Report"]'
    rescue Exception => e
      raise e, 'Lkqd login error'
    end
    cookies = @client.driver.cookies
    @client = HTTPClient.new
    @client.cookie_manager.cookies = cookies.values.map do |cookie|
      cookie = cookie.instance_variable_get(:@attributes)
      HTTP::Cookie.new cookie
    end
  end

  def scrap
    @date_str = @date.strftime('%Y-%m-%d')

    header = {
      'Content-Type': 'application/json'
    }
    body = {
      'whatRequest': 'breakdown',
      'uuid': SecureRandom.uuid,
      'reportFormat': 'JSON',
      'includeSummary': true,
      'dateRangeType': 'CUSTOM',
      'startDate': @date_str,
      'endDate': @date_str,
      'timeDimension': 'OVERALL',
      'timezone': 'America/New_York',
      'reportType': ['DOMAIN'],
      'environmentIds': [1,2,3,4],
      'filters': [],
      'metrics': ["OPPORTUNITIES", "IMPRESSIONS", "REVENUE", "CLICKS", "COMPLETED_VIEWS"],
      'sort': [{'field':'REVENUE','order':'desc'}],
      'offset': 0,
      'limit': 200
    }
    response = @client.post('https://ui-api.lkqd.com/reports', header: header, body: body.to_json)
    data = JSON.parse(response.body)
    data = data['data']['entries']

    @data = []
    return if data.count == 0

    # flatten the dimensions and merge to top level of datum
    data = data.map { |datum| datum.merge(datum['dimensions'].map { |d| [d['dimensionId'].downcase, d['name']] }.to_h) }
    data = data.each { |datum| datum.delete('dimensions') }

    header = data[0].keys
    @data = [header]
    @data += data.map { |datum| header.map { |key| datum[key].is_a?(Hash) ? datum[key]['value'] : datum[key] } }
  end
end
