require 'spreadsheet'
require 'httpclient'
require 'csv'

class TimeSheet::Time::Parser

  def initialize(dirs)
    @dirs = dirs
  end

  def files
    results = []
    @dirs.each do |dir|
      if File.directory?(dir)
        results += Dir["#{dir}/**/*.xls"]
      else
        results << dir
      end
    end
    results.sort
  end

  def entries
    @entries ||= begin
      results = []
      hashes_per_file.each do |hashes|
        file_results = []
        hashes.each do |e|
          te = TimeSheet::Time::Entry.new(e)
          if file_results.last 
            file_results.last.next = te
            te.prev = file_results.last
          end
          file_results << te
        end
        results += file_results
      end
      results.sort!
      results.each do |r|
        unless r.valid?
          # byebug
          raise r.exception, [
            r.exception.message, ': ',
            r.data.inspect,
            ', preceeding entry: ',
            r.prev
          ].join
        end
      end
      results
    end
  end

  def hashes_per_file
    @hashes_per_file ||= begin
      files.map do |f|
        if f.match(/https:\/\/docs\.google\.com/)
          parse_google_doc(f)
        else
          parse_xls(f)
        end
      end
    end
  end

  def parse_xls(filename)
    results = []

    Spreadsheet.open(filename).worksheets.each do |sheet|
      headers = sheet.rows.first.to_a
      sheet.rows[1..-1].each do |row|
        # TODO find a way to guard against xls sheets with 65535 (empty)
        # lines, perhaps:
        # break if row[1].nil?

        record = {}
        row.each_with_index do |value, i|
          record[headers[i]] = value
        end
        results << record
      end
    end

    results
  end

  def parse_google_doc(share_url)
    id = share_url.match(/\/d\/([^\/]+)\//)[1]
    url = "https://docs.google.com/spreadsheets/d/#{id}/export?exportFormat=tsv"
    response = HTTPClient.get(url)

    if response.status == 200
      data = CSV.parse(response.body, col_sep: "\t")
      headers = data.shift
      data.map do |row|
        record = headers.zip(row).to_h
        parse_date_and_time(record)
      end
    else
      raise "request to google docs failed (#{response.status}):\n#{response.body}"
    end
  end

  def parse_date_and_time(record)
    record.merge(
      'date' => (record['date'] ? Date.parse(record['date']) : nil),
      'start' => (record['start'] ? DateTime.parse(record['start']) : nil),
      'end' => (record['end'] ? DateTime.parse(record['end']) : nil)
    )
  rescue ArgumentError => e
    puts "current record: #{record.inspect}"
    return {}
    # raise e
  end

end