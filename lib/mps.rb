require "mps/version"

module Mps
  autoload :Time, 'mps/time'
  autoload :TablePrinter, 'mps/table_printer'

  def self.root
    @root ||= File.expand_path(File.dirname(__FILE__) + '/..')
  end
end
