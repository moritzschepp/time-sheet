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

      options[:from] = Date.parse(d)
    end

    if d = options[:to]
      if d.match(/^\d\d?-\d\d?$/)
        d = "#{Mps::Time::Util.now.year}-#{d}"
      end

      if d.match(/^\d{4}$/)
        d = "#{d}-12-31"
      end

      options[:to] = Date.parse(d)
    end

    if options[:help]
      puts options
    elsif options[:version]
      puts Mps::VERSION
    else
      case command
        when 'invoice'
          invoice
        when 'overview'
          show_html
        when 'report', 'default'
          report
        when 'today', 't'
          options[:from] = Mps::Time::Util.today
          options[:to] = Mps::Time::Util.today
          options[:summary] = true
          report
        when 'yesterday', 'y'
          options[:from] = Mps::Time::Util.yesterday
          options[:to] = Mps::Time::Util.yesterday
          options[:summary] = true
          report
        when 'week', 'w'
          options[:from] = Mps::Time::Util.week_start
          options[:to] = Mps::Time::Util.week_end
          options[:summary] = true
          report
        when 'last-week', 'lw'
          options[:from] = Mps::Time::Util.week_start(-1)
          options[:to] = Mps::Time::Util.week_end(-1)
          options[:summary] = true
          report
        when 'month', 'm'
          options[:from] = Mps::Time::Util.month_start
          options[:to] = Mps::Time::Util.month_end
          options[:summary] = true
          report
        when 'last-month', 'lm'
          options[:from] = Mps::Time::Util.month_start(-1)
          options[:to] = Mps::Time::Util.month_end(-1)
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
        "* invoice: compress similar entries and filter petty ones. Optionally package for e.g. monthly invoicing",
        "\noptions:"
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
      o.boolean '-v', '--verbose', 'be more verbose'
      o.integer '--package', 'for invoice output: build packages of this duration in hours', default: 0
      o.integer '--petty', 'fold records of a certain threshold into a "misc" activity', default: 0
    end
  end

  def command
    options.arguments.shift || 'default'
  end

  def invoice
    data = Mps::Time.invoice(options)

    data.each do |package|
      tp = Mps::TablePrinter.new package
      puts tp.generate
      puts "\n"
    end

    print "last package duration: "
    puts data.last.map{|entry| entry[1]}.sum
  end

  def report
    data = Mps::Time.report(options)
    tp = Mps::TablePrinter.new data['entries']
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

      tp = Mps::TablePrinter.new tdata
      puts tp.generate

      # averages
      days = (
        (options[:to] || data['entries'].last[1]).to_date -
        (options[:from] || data['entries'].first[0]).to_date
      )
      weeks = days / 7.0
      months = days / 30.0
      workdays = weeks * 5.0
      hours_worked = Mps::Time::Util.hours(data['total'])
      puts [
        "worked: h/day: #{(hours_worked / days).round(2)}",
        "h/workday: #{(hours_worked / workdays).round(2)}",
        "h/week: #{(hours_worked / weeks).round(2)}",
        "h/month: #{(hours_worked / months).round(2)}"
      ].join(', ')
    end
  end
end