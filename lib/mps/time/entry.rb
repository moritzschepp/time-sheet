class Mps::Time::Entry
  def self.now
    @now ||= Time.now
  end

  def initialize(data)
    @data = data
  end

  attr_accessor :prev, :next

  def project
    @data['project'] ||= self.prev.project
  end

  def activity
    @data['activity'] ||= self.prev.activity
  end

  def description
    @data['description'] ||= self.prev.description
  end

  def date
    @date ||= @data['date'] || self.prev.date
  end

  def start
    @start ||= Time.mktime(
      date.year, date.month, date.day,
      @data['start'].hour, @data['start'].min
    )
  end


  def end
    ends_at = @data['end'] || (self.next ? self.next.start : self.class.now)

    @end ||= Time.mktime(
      date.year, date.month, date.day,
      ends_at.hour, ends_at.min
    )
  end

  # Experiment to add timezone support. However, this would complicate every day
  # handing because of daylight saving time changes.
  # def start_zone
  #   @start_zone ||= if v = @data['start_zone']
  #     # allow a name prefixing the value
  #     v.split(/\s/).last
  #   elsif v = self.prev.start_zone
  #     v
  #   else
  #     self.class.now.getlocal.utc_offset
  #     # use this process' timezone
  #     nil
  #   end
  # end

  # def end_zone
  #   @end_zone ||= if v = @data['end_zone']
  #     # allow a name prefixing the value
  #     v.split(/\s/).last
  #   elsif self.prev && v = self.prev.end_zone
  #     v
  #   else
  #     # self.class.now.getlocal.utc_offset
  #     # use this process' timezone
  #     nil
  #   end
  # end

  def duration
    (self.end - self.start) / 60
  end

  def tags
    (@data['tags'] || '').split(/\s*,\s*/)
  end

  def working_day?
    !date.saturday? && !date.sunday? && !tags.include?('holiday')
  end

  def matches?(filters)
    from = (filters[:from] ? filters[:from] : nil)
    from = from.to_time if from.is_a?(Date)
    to = (filters[:to] ? filters[:to] : nil)
    to = (to + 1).to_time if to.is_a?(Date)

    self.class.attrib_matches_any?(description, filters[:description]) &&
    self.class.attrib_matches_any?(project, filters[:project]) &&
    self.class.attrib_matches_any?(activity, filters[:activity]) &&
    (!from || from <= self.start) &&
    (!to || to >= self.end)
  end

  def valid?
    (duration > 0) &&
    ((self.start < self.end) || !self.next)
  end

  def to_row
    [date, start, self.end, duration.to_i, project, activity, description]
  end

  def to_s
    values = [
      date.strftime('%Y-%m-%d'),
      start.strftime('%H:%M'),
      self.end.strftime('%H:%M'),
      duration.to_i.to_s.rjust(4),
      project,
      activity,
      description
    ].join(' | ')
  end

  def to_hash
    return {
      'date' => date,
      'start' => start,
      'end' => self.end,
      'duration' => duration,
      'project' => project,
      'activity' => activity,
      'description' => description
    }
  end

  def <=>(other)
    (self.date <=> other.date) || self.start <=> other.start
  end

  def self.attrib_matches_any?(value, patterns)
    return true if !patterns

    patterns.split(/\s*,\s*/).any? do |pattern|
      value.match(pattern)
    end
  end

end