require 'spreadsheet'

class Mps::Time::Parser

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
          te = Mps::Time::Entry.new(e)
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
          raise Mps::Time::Exception.new("invalid time entry: #{r.to_row.inspect}")
        end
      end
      results
    end
  end

  def hashes_per_file
    @hashes_per_file ||= begin
      files.map do |f|
        results = []
        Spreadsheet.open(f).worksheets.each do |sheet|
          headers = sheet.rows.first.to_a
          sheet.rows[1..-1].each do |row|
            record = {}
            row.each_with_index do |value, i|
              record[headers[i]] = value
            end
            results << record
          end
        end
        results
      end
    end
  end

end