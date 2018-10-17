require 'erb'

module Mps::Time
  autoload :Cmd, 'mps/time/cmd'
  autoload :Entry, 'mps/time/entry'
  autoload :Exception, 'mps/time/exception'
  autoload :Parser, 'mps/time/parser'
  autoload :Util, 'mps/time/util'

  def self.report(options)
    results = {
      'entries' => [],
      'total' => 0.0,
      'projects' => {}
    }

    x = nil
    Parser.new(options[:location]).entries.each do |e|
      unless x
        x = true
      end
      if e.matches?(options)
        results['total'] += e.duration
        results['projects'][e.project] ||= {'total' => 0.0, 'activities' => {}}
        results['projects'][e.project]['total'] += e.duration
        results['projects'][e.project]['activities'][e.activity] ||= 0.0
        results['projects'][e.project]['activities'][e.activity] += e.duration

        results['entries'] << e.to_row
      end
    end

    averages(results, options)

    results
  end

  def self.averages(results, options)
    days = 1

    unless results['entries'].empty?
      time = (
        (options[:to] || Util.day_end) - 
        (options[:from] || results['entries'].first[0].to_time)
      ).to_i
      days = (time.to_f / 60 / 60 / 24).round
    end

    weeks = days / 7.0
    months = days / 30.0
    workdays = weeks * 5.0
    worked = Mps::Time::Util.hours(results['total'])

    results['averages'] = {
      'days' => days,
      'weeks' => weeks,
      'months' => months,
      'workdays' => workdays,
      'worked' => worked,
      'hours_per_day' => worked / days,
      'hours_per_workday' => worked / workdays,
      'hours_per_week' => worked / weeks,
      'hours_per_month' => worked / months,
    }
  end

  def self.invoice(options)
    grouped = {}
    Parser.new(options[:location]).entries.each do |e|
      if e.matches?(options)
        grouped[[e.date, e.description]] ||= 0
        grouped[[e.date, e.description]] += e.duration.to_i
      end
    end
    rows = []
    grouped.each{|k, d| rows << [k.first, d, k.last]}
    packages = [[]]
    ptotal = 0
    rows.each do |row|
      if options[:package] > 0
        if ptotal + row[1] > options[:package] * 60
          filler = row.dup
          filler[1] = options[:package] * 60 - ptotal
          row[1] -= filler[1]
          packages.last << filler
          packages << []
          ptotal = 0
        end

        if ptotal + row[1] == options[:package] * 60
          packages << []
          ptotal = 0
        end
      end

      packages.last << row
      ptotal += row[1]
    end

    if options[:petty]
      packages.map do |package|
        petty = 0
        package.select! do |row|
          if row[1] < options[:petty]
            petty += row[1]
            next false
          end
          true
        end
        if petty > 0
          package << [nil, petty, 'misc']
        end
        package
      end
    end
  end

end