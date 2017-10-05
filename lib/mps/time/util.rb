module Mps::Time::Util

  def self.month_start
    Time.mktime(now.year, now.month, 1)
  end

  def self.month_end
    tmp = month_start + 60 * 60 * 24 * 32
    Time.mktime(tmp.year, tmp.month, 1) - 1
  end

  def self.week_start
    day_start - (now.wday - 1) % 7 * 60 * 60 * 24
  end

  def self.week_end
    week_start + 60 * 60 * 24 * 7 - 1
  end

  def self.day_start
    now.to_date.to_time
  end

  def self.day_end
    day_start + 60 * 60 * 24 - 1
  end

  def self.now
    @now ||= Time.now
  end

  def self.human_duration(duration, rate)
    hours = duration.to_i / 60.0
    amount = (rate * hours)
    "#{duration.to_i}m (#{hours.round(2)}h, € #{amount.round(2)})"
  end

end