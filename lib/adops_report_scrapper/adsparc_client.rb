require 'date'
require_relative 'base_client'

class AdopsReportScrapper::AdsparcClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 2
    false
  end

  private

  def login
    @client.visit 'http://publisher.adsparc.com/login.php'
    @client.fill_in 'Email', :with => @login
    @client.fill_in 'Password', :with => @secret
    @client.click_button 'Login'
    begin
      @client.find :xpath, '//*[text()="Logout"]'
    rescue Exception => e
      raise e, 'Adsparc login error'
    end
  end

  def scrap
    request_report
    extract_data_from_report
  end

  def request_report
    sleep 5
    url = @client.find(:css, '#iframe').base.attributes['src']
    @client.visit url
    sleep 5
    @client.find(:css, '#topCalendar').click
    @client.find(:xpath, '//*[text()="Month to date "]').click
    @client.find(:xpath, '//*[text()="Last 7 Days"]').click
    @client.click_button 'Apply'
    sleep 0.5
    wait_for_loading
  end

  def extract_data_from_report
    header = @client.find(:xpath, '//*[contains(@class, "widget-item") and .//*[text()="Publisher Earnings Report - by Day"]]//table/thead/tr').find_css('td,th').map { |td| td.visible_text }
    @data = [header]
    date_str = @date.strftime '%d %b %Y'
    rows = @client.find_all(:xpath, "//*[contains(@class, \"widget-item\") and .//*[text()=\"Publisher Earnings Report - by Day\"]]//table/tbody/tr[./td[text()=\"#{date_str}\"]]")
    rows = rows.to_a
    @data.concat(rows.map { |tr| tr.find_css('td,th').map { |td| td.visible_text } })
  end

  def wait_for_loading
    30.times do |_i| # wait 5 min
      begin
        @client.find(:xpath, '//*[text()="Day"]')
        break
      rescue Exception => e
        sleep 10
      end
    end
  end
end