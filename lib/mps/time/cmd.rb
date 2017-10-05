require 'slop'

class Mps::Time::Cmd
  def run
    command = options.arguments.shift || 'default'

    if options[:help]
      puts options
    else
      case command
        when 'invoice'
          invoice
        when 'overview'
          show_html
        when 'report', 'default'
          report
        when 'today', 't'
          options[:from] = Utils.now.strftime('%Y-%m-%d')
          options[:summary] = true
          report
        when 'yesterday', 'y'
          options[:from] = (Utils.now - 60 * 60 * 24).strftime('%Y-%m-%d')
          options[:to] = Utils.now.strftime('%Y-%m-%d')
          options[:summary] = true
          report
        when 'week', 'w'
          options[:from] = Utils.week_start.strftime('%Y-%m-%d')
          options[:to] = Utils.week_end.strftime('%Y-%m-%d')
          options[:summary] = true
          report
        when 'last-week', 'lw'
          options[:from] = (Utils.week_start - 60 * 60 * 24 * 6.5).strftime('%Y-%m-%d')
          options[:to] = (Utils.week_end - 60 * 60 * 24 * 7.5).strftime('%Y-%m-%d')
          options[:summary] = true
          report
        when 'month', 'm'
          options[:from] = Utils.month_start.strftime('%Y-%m-%d')
          options[:to] = (Utils.month_end + 1).strftime('%Y-%m-%d')
          options[:summary] = true
          report
        else
          raise "unknown command: #{command}"
      end

      if options[:verbose]
        puts "\noptions:"
        p options.to_h
      end
    end
  end

  def options
    @options ||= Slop.parse do |o|
      o.banner = [
        "usage: time.rb [command] [options]\n",
        'available commands:',
        '* overview (default): generate an html overview and open it with the browser',
        "* report: list entries conforming to given criteria",
        "* invoice: compress similar entries and filter petty ones",
        "\noptions:"
      ].join("\n")

      o.array('-l', '--location', 'a location to gather data from (file or directory)',
        default: ["#{ENV['HOME']}/Desktop/cloud/time"]
      )
      o.string '-f', '--from', 'ignore entries older than the date given'
      o.string '-t', '--to', 'ignore entries more recent than the date given'
      o.string '-p', '--project', 'take only entries of this project into account'
      o.string '-a', '--activity', 'take only entries of this activity into account'
      o.string '-d', '--description', 'consider only entries matching this description'
      o.float '-r', '--rate', 'use an alternative hourly rate (default: 86.70)', default: 86.70
      o.boolean '-s', '--summary', 'when reporting, add summary section'
      o.boolean '-h', '--help', 'show help'
      o.boolean '-v', '--verbose', 'be more verbose'
      o.integer '--package', 'for invoice output: build packages of this duration in hours', default: 0
    end
  end

  def invoice
    data = Mps::Time.invoice(@options)

    data.each do |package|
      tp = Mps::TablePrinter.new package
      puts tp.generate
      puts '-'
    end
  end

  def report
    data = Mps::Time.report(@options)
    tp = Mps::TablePrinter.new data['entries']
    puts tp.generate

    if @options[:summary]
      puts "\nsums: #{Mps::Time::Util.human_duration data['total'], @options[:rate]}"
      data['projects'].each do |pname, pdata|
        puts "#{pname}: #{Mps::Time::Util.human_duration pdata['total'], @options[:rate]} "
        pdata['activities'].each do |aname, atotal|
          puts "  #{aname}: #{Mps::Time::Util.human_duration atotal, @options[:rate]}"
        end
      end
    end
  end
end