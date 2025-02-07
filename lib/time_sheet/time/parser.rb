require 'roo'
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
        results += Dir["#{dir}/**/*.xlsx"]
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
          parse_xlsx(f)
        end
      end
    end
  end

  def parse_xlsx(filename)
    results = []

    xlsx = Roo::Spreadsheet.open(filename)
    xlsx.each_with_pagename do |name, sheet|
      headers = sheet.row(1).to_h{|e| [e, e]}
      rows = sheet.parse(headers)

      rows.each do |row|
        next unless row['start']
        next if row.values.all?{|v| [nil, ''].include?(v)}

        results << row
      end
    end

    results
  end

  def parse_google_doc(url)
    # Chart Tools datasource protocol, see 
    # https://developers.google.com/chart/interactive/docs/querylanguage
    response = HTTPClient.get(url)

    if response.status == 200
      data = CSV.parse(response.body, liberal_parsing: true)
      headers = data.shift
      data.map do |row|
        record = nullify_empties(headers.zip(row).to_h)
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
    binding.pry if TimeSheet.options[:debug]
    puts "current record: #{record.inspect}"
    return {}
    # raise e
  end

  def nullify_empties(record)
    record.transform_values do |v|
      v == '' ? nil : v
    end
  end

end