require 'date'
require_relative 'base_client'
require 'selenium-webdriver'

class AdopsReportScrapper::SovrnClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 7
    false
  end

  def init_client
    Capybara.register_driver :selenium do |app|
      profile = Selenium::WebDriver::Firefox::Profile.new
      @download_dir = '/tmp/sovrn'
      profile['browser.download.dir'] = @download_dir
      clean_up_download_dir
      profile['browser.download.folderList'] = 2
      profile['browser.helperApps.neverAsk.saveToDisk'] = 'application/octet-stream'
      Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
    end
    @client = Capybara::Session.new(:selenium)
  end

  private

  def login
    @client.visit 'https://meridian.sovrn.com/#welcome'
    sleep 1
    if @client.find_all(:css, '#user-menu-trigger').count > 0
      @client.find_all(:css, '#user-menu-trigger').first.click
      sleep 1
      @client.find(:xpath, '//li[@data-value="logout"]').click
    end
    if @client.find_all(:xpath, '//*[contains(text(),"Go to Login")]').count > 0
      @client.find(:xpath, '//*[contains(text(),"Go to Login")]').click
      sleep 1
    end
    @client.fill_in 'login_username', :with => @login
    @client.fill_in 'login_password', :with => @secret
    @client.click_link 'Log In'
    sleep 5

    begin
      @client.find :xpath, '//*[text()="Account"]'
    rescue Exception => e
      raise e, 'sovrn login error'
    end
  end

  def scrap
    request_report
    extract_data_from_report
  end

  def request_report
    @client.visit 'https://meridian.sovrn.com/#account/my_downloads'
    sleep 5
    if @client.find_all(:xpath, '//input[@value="domestic_and_international"]').count == 0
      login
      @client.visit 'https://meridian.sovrn.com/#account/my_downloads'
      sleep 5
    end

    @client.fill_in 'adstats-date-range-start-month', :with => @date.strftime('%m')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)
    @client.fill_in 'adstats-date-range-start-day', :with => @date.strftime('%d')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)
    @client.fill_in 'adstats-date-range-start-year', :with => @date.strftime('%Y')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)

    @client.fill_in 'adstats-date-range-end-month', :with => @date.strftime('%m')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)
    @client.fill_in 'adstats-date-range-end-day', :with => @date.strftime('%d')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)
    @client.fill_in 'adstats-date-range-end-year', :with => @date.strftime('%Y')
    @client.find(:xpath, '//input[@value="domestic_and_international"]').set(true)

    @client.find_all(:xpath, '//button[text()=" Download "]').first.click

    sleep 2
  end

  def extract_data_from_report
    rows = CSV.parse File.read("#{@download_dir}/adstats_all_traffic.csv")
    @data = rows[6..-1]
  end

  def clean_up_download_dir
    FileUtils.rm_rf(Dir.glob("#{@download_dir}/*"))
  end
end
