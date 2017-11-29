require 'date'
require_relative 'base_client'
require_relative '../helpers/ox3client'
require 'csv'

class AdopsReportScrapper::OpenxClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 2
    false
  end

  private

  def init_client
    fail 'please specify openx consumer_key' unless @options['consumer_key']
    fail 'please specify openx consumer_secret' unless @options['consumer_secret']
    fail 'please specify openx realm' unless @options['realm']
    fail 'please specify openx site_url' unless @options['site_url']
    @consumer_key = @options['consumer_key']
    @consumer_secret = @options['consumer_secret']
    @realm = @options['realm']
    @site_url = @options['site_url']
  end

  def before_quit_with_error
  end

  def scrap
    start_date_str = @date.strftime('%Y-%m-%d 00:00:00')
    end_date_str = @date.strftime('%Y-%m-%d 23:59:59')
    
    ox3 = OX3APIClient.new(@login, @secret, @site_url, @consumer_key, @consumer_secret, @realm)

    response = ox3.get("/report/run?report=inv_rev&start_date=#{URI.escape(start_date_str)}&end_date=#{URI.escape(end_date_str)}&report_format=csv&do_break=AdUnit,Country&saleschannel=SALESCHANNEL.OPENXMARKET")
    report_pickup_url = @site_url + JSON.parse(response)['url']
    report_csv_data = nil;
    open(report_pickup_url) { |f| report_csv_data = f.read }

    @data = CSV.parse(report_csv_data)

    while @data.count > 0
      row = @data.shift
      break if row.first == 'Report Data:'
    end

    while @data.count > 0
      break if @data.last.first == 'Real-time Buyer'
      @data.pop
    end
  end
end
