require 'slop'
require 'time'

class Mps::Time::Cmd
  def run
    if d = options[:from]
      if d.match(/^\d\d?-\d\d?$/)
        d = "#{Mps::Time::Util.now.year}-#{d}"
      end

      if d.match(/^\d{4}$/)
        d = "#{d}-01-01"
      end

      options[:from] = Time.parse(d)
    end

    if d = options[:to]
      if d.match(/^\d\d?-\d\d?$/)
        d = "#{Mps::Time::Util.now.year}-#{d}"
      end

      if d.match(/^\d{4}$/)
        d = "#{d}-12-31"
      end

      options[:to] = Time.parse(d)
    end

    if options[:help]
      puts options
    elsif options[:version]
      puts Mps::VERSION
    else
      case command
        when 'invoice'
          invoice
        when 'report', 'default'
          report
        when 'today', 't'
          options[:from] = Mps::Time::Util.today
          options[:summary] = true
          report
        when 'yesterday', 'y'
          options[:from] = Mps::Time::Util.yesterday
          options[:to] = Mps::Time::Util.yesterday
          options[:summary] = true
          report
        when 'week', 'w'
          options[:from] = Mps::Time::Util.week_start
          options[:summary] = true
          report
        when 'last-week', 'lw'
          options[:from] = Mps::Time::Util.week_start(-1)
          options[:to] = Mps::Time::Util.week_end(-1)
          options[:summary] = true
          report
        when 'month', 'm'
          options[:from] = Mps::Time::Util.month_start
          options[:summary] = true
          report
        when 'last-month', 'lm'
          options[:from] = Mps::Time::Util.month_start(-1)
          options[:to] = Mps::Time::Util.month_end(-1)
          options[:summary] = true
          report
        when 'overview'
          overview
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
        "  report (default): list entries conforming to given criteria",
        "  invoice: compress similar entries and filter petty ones. Optionally package for e.g. monthly invoicing",
        "\n  general options:"
      ].join("\n")

      o.boolean '-h', '--help', 'show help'
      o.boolean '--version', 'show the version'
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
      o.boolean '--trim', 'compact the output for processing as CSV', default: false
      o.boolean '-v', '--verbose', 'be more verbose'
      o.separator "\n  invoice options:"
      o.integer '--package', 'for invoice output: build packages of this duration in hours', default: 0
      o.integer '--petty', 'fold records of a certain threshold into a "misc" activity', default: 0
    end
  end

  def command
    options.arguments.shift || 'default'
  end

  def convert_to_time
    if options[:from]
      options[:from] = options[:from].to_time
    end
    if options[:to].is_a?(Date)
      options[:to] = options[:to].to_time + 24 * 60 * 60
    end
  end

  def invoice
    convert_to_time

    data = Mps::Time.invoice(options)

    data.each do |package|
      tp = Mps::TablePrinter.new package, options
      puts tp.generate
      puts "\n"
    end

    if options[:package]
      package = data.last.map{|entry| entry[1]}.sum
      total = options[:package] * 60
      percent = (package / total.to_f * 100)

      puts "last package duration: #{package}/#{total} (#{percent.round 2}%)"
    end
  end

  def report
    convert_to_time

    data = Mps::Time.report(options)
    tp = Mps::TablePrinter.new data['entries'], options
    puts tp.generate


    if options[:summary]
      puts "\nSummary:"

      tdata = [['project', 'activity', 'time [m]', 'time [h]', 'price [€]']]
      tdata << [
        'all',
        '',
        Mps::Time::Util.minutes(data['total']),
        Mps::Time::Util.hours(data['total']),
        Mps::Time::Util.price(data['total'], options[:rate])
      ]

      data['projects'].sort_by{|k, v| v['total']}.reverse.to_h.each do |pname, pdata|
        previous = nil

        tdata << '-'
        tdata << [
          pname,
          'all',
          Mps::Time::Util.minutes(pdata['total']),
          Mps::Time::Util.hours(pdata['total']),
          Mps::Time::Util.price(pdata['total'], options[:rate])
        ]
        
        pdata['activities'].sort_by{|k, v| v}.reverse.to_h.each do |aname, atotal|
          tdata << [
            '',
            aname,
            Mps::Time::Util.minutes(atotal),
            Mps::Time::Util.hours(atotal),
            Mps::Time::Util.price(atotal, options[:rate])
          ]
          previous = pname
        end
      end

      tdata << '-'

      tp = Mps::TablePrinter.new tdata, options
      puts tp.generate

      puts [
        "days: #{data['averages']['days']}",
        "worked: h/day: #{data['averages']['hours_per_day'].round(2)}",
        "h/workday: #{data['averages']['hours_per_workday'].round(2)}",
        "h/week: #{data['averages']['hours_per_week'].round(2)}",
        "h/month(30 days): #{data['averages']['hours_per_month'].round(2)}"
      ].join(', ')
    end
  end

end