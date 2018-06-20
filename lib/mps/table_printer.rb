class Mps::TablePrinter

  def initialize(data = [], options = {})
    @options = options
    @data = data
  end

  attr_reader :options

  def <<(row)
    @data << row
  end

  def flush
    @widths = nil
  end

  def generate
    flush

    result = []
    @data.each do |row|
      output = if row == '-'
        widths.map{|w| '-' * w}
      else
        row.each_with_index.map do |r, i|
          format(r, widths[i], i == row.size - 1)
        end
      end
      result << output.join(options[:trim] ? '|' : ' | ')
    end
    result.join("\n")
  end

  def widths
    @widths ||= @data.first.each_with_index.map do |c, i|
      @data.map{|row| row == '-' ? 0 : size(row[i])}.max
    end
  end

  def format(value, width, last_column = false)
    str = case value
      when Integer then value.to_s.rjust(width)
      when Date then value.strftime('%Y-%m-%d').rjust(width)
      when Time then value.strftime('%H:%M').rjust(width)
      when Float then ("%.2f" % value).rjust(width)
      when nil then ' ' * width
      else
        last_column ? value : value.ljust(width)
    end
  end

  def size(value)
    case value
      when nil then 0
      when Integer then value.to_s.size
      when Float then ("%.2f" % value).size
      when Date then 10
      when Time then 5
      else
        value.size
    end
  end

end