require 'time_sheet/version'

if defined?(Bundler)
  begin
    require 'pry'
  rescue LoadError => e
    # do nothing, we are probably in production
  end
end

module TimeSheet
  autoload :Time, 'time_sheet/time'
  autoload :TablePrinter, 'time_sheet/table_printer'

  def self.root
    @root ||= File.expand_path(File.dirname(__FILE__) + '/..')
  end
end
