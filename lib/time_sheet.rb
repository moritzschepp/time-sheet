require 'time_sheet/version'

if defined?(Bundler)
  require 'pry'
end

module TimeSheet
  autoload :Time, 'time_sheet/time'
  autoload :TablePrinter, 'time_sheet/table_printer'

  def self.root
    @root ||= File.expand_path(File.dirname(__FILE__) + '/..')
  end
end
