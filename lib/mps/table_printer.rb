class Mps::TablePrinter

  def initialize(data = [])
    @data = data
  end

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
      output = row.each_with_index.map do |c, i|
        format(c, widths[i])
      end
      result << output.join(' | ')
    end
    result.join("\n")
  end

  def widths
    @widths ||= @data.first.each_with_index.map do |c, i|
      @data.map{|row| size(row[i])}.max
    end
  end

  def format(value, width)
    str = case value
      when Numeric then value.to_s.rjust(width)
      when Date then value.strftime('%Y-%m-%d').rjust(width)
      when Time then value.strftime('%H:%M')
      when nil then ' ' * width
      else
        value.ljust(width)
    end
  end

  def size(value)
    case value
      when nil then 0
      when Numeric then value.to_s.size
      when Date then 10
      when Time then 5
      else
        value.size
    end
  end

end