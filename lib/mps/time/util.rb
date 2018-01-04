module Mps::Time::Util

  def self.year_start(factor = 0)
    Date.new(Date.today.year + factor, 1, 1)
  end

  def self.year_end(factor = 0)
    Date.new(Date.today.year + factor, 12, 31)
  end

  def self.month_start(factor = 0)
    tmp = Date.today.prev_month(factor * -1)
    Date.new tmp.year, tmp.month, 1
  end

  def self.month_end(factor = 0)
    tmp = (month_start(factor) + 45)
    Date.new(tmp.year, tmp.month) - 1
  end

  def self.week_start(factor = 0)
    today - (today.wday - 1) % 7 + (factor * 7)
  end

  def self.week_end(factor = 0)
    week_start(factor) + 6
  end

  def self.day_start
    now.to_date.to_time
  end

  def self.day_end
    day_start + 60 * 60 * 24 - 1
  end

  def self.now
    Time.now
  end

  def self.today
    now.to_date
  end

  def self.yesterday
    now.to_date - 1
  end

  def self.human_duration(duration, rate)
    hours = duration.to_i / 60.0
    amount = (rate * hours)
    "#{duration.to_i}m (#{hours.round(2)}h, € #{amount.round(2)})"
  end

end