require 'date'
require_relative 'base_client'

class AdopsReportScrapper::AnyclipClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 4
    false
  end

  private

  def login
    @client.driver.headers = { 'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36' }
    @client.visit 'https://partners.anyclip-media.com/#/signin'
    sleep 10
    return if @client.find_all(:xpath, '//*[text()="Network Activity Report"]').count > 0
    @client.fill_in 'Username', :with => @login
    @client.fill_in 'Password', :with => @secret
    @client.find(:xpath, '//*[text()="LOG IN"]').click
    begin
      @client.find :xpath, '//*[text()="Network Activity Report"]'
    rescue Exception => e
      raise e, 'anyclip login error'
    end
  end

  def scrap
    date_str = @date.strftime '%Y-%m-%d'
    @client.visit "https://partners.anyclip-media.com/#/report?dimension=trafficChannel&endDate=#{date_str}T23%3A59%3A59%2B00%3A00&sortAsc=false&sortBy=cost&startDate=#{date_str}T00%3A00%3A00%2B00%3A00&type=supply-partner-traffic-channel"
    sleep 10
    @data = []
    @data << @client.find_all(:css, '.sr-collection--header .col').map { |cell| cell.text }
    raw_data = @client.find_all(:css, '.sr-collection--row-item .col').map { |cell| cell.text }
    (raw_data.count/6).times do |i|
      si = raw_data.count/6+i*5
      @data << [raw_data[i]] + raw_data[si, 5]
    end
  end
end