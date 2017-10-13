require 'date'
require_relative 'base_client'
require 'net/imap'
require 'mail'
require 'csv'

class AdopsReportScrapper::EmailClient < AdopsReportScrapper::BaseClient
  def date_supported?(date = nil)
    _date = date || @date
    return true if _date >= Date.today - 30
    false
  end
  private

  def init_client
    fail 'please specify email imap_server' unless @options['imap_server']
    fail 'please specify email imap_port' unless @options['imap_port']
    fail 'please specify email imap_ssl' unless @options['imap_ssl']
    fail 'please specify email title' unless @options['title']
    @imap_server = @options['imap_server']
    @imap_port = @options['imap_port']
    @imap_ssl = @options['imap_ssl']
    @title = @options['title'] # supports data macro e.g. `XXX Report %Y-%m-%d` will match XXX Report `2017-04-26`
    @date_column = @options['date_column'] # optional. supports data macro e.g. `0||%Y-%m-%d` will match rows that has `2017-04-26` for their first column
    @header_first_cell = @options['header_first_cell'] # optional. It will try to match the first cell text, and treat the matched row as header, ignoring all the rows above. By default, it will take the first row as header.
    @imap_ssl_verify = @options['imap_ssl_verify'].nil? ? true : @options['imap_ssl_verify']
    @ignore_receive_date = @options['ignore_receive_date'].nil? ? false : @options['ignore_receive_date']
  end

  def before_quit_with_error
  end

  def scrap
    @data = []
    email_received_date = Net::IMAP.format_date(@date+1)
    title = @date.strftime(@title)

    imap = Net::IMAP.new(@imap_server, @imap_port, @imap_ssl, nil, @imap_ssl_verify)
    imap.login(@login, @secret)
    imap.select('INBOX')
    search_condition = []
    search_condition += ['ON', email_received_date] unless @ignore_receive_date
    search_condition += ['SUBJECT', title]
    report_email_ids = imap.search search_condition
    if report_email_ids.count == 0
      imap.logout
      imap.disconnect
      fail 'no email found with the given date and title'
    elsif report_email_ids.count > 1
      puts 'more than one email found with the given date and title, try to use the first one'
    end
    report_email_id = report_email_ids.first

    body = imap.fetch(report_email_id, 'RFC822')[0].attr['RFC822']
    mail = Mail.new(body)
    if mail.attachments.blank?
      imap.logout
      imap.disconnect
      fail 'no attachment found for the given report'
    end

    raw_data = mail.attachments.first.body.decoded

    imap.logout
    imap.disconnect

    @data = CSV.parse(raw_data)

    if @date_column
      column_index, date_format_str = @date_column.split('||')
      column_index = column_index.to_i
      date_str = @date.strftime(date_format_str)
      header = nil
      if @header_first_cell
        while !@data.empty?
          row = @data.shift
          if @header_first_cell == row[0]
            header = row
            break
          end
          fail 'empty report' if @data.length == 0
        end
      else
        header = @data.shift
      end
      @data = @data.select { |row| row[column_index] == date_str }
      @data.unshift header
    end
  end
end