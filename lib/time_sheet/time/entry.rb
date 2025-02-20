class TimeSheet::Time::Entry
  def self.now
    @now ||= Time.now
  end

  def initialize(data)
    @data = data
  end

  attr_accessor :prev, :next, :exception, :data

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
      hour_for(@data['start']),
      minute_for(@data['start'])
    )
  end

  def end
    ends_at = @data['end'] || (self.next ? self.next.start : self.class.now)

    @end ||= Time.mktime(
      date.year, date.month, date.day,
      hour_for(ends_at),
      minute_for(ends_at)
    )
  end

  def hour_for(timish)
    case timish
    when Time then timish.hour
    when DateTime then timish.hour
    when Integer then timish / 60 / 60
    else
      binding.pry
    end
  end

  def minute_for(timish)
    case timish
    when Time then timish.min
    when DateTime then timish.min
    when Integer then timish / 60 % 60
    else
      binding.pry
    end
  end

  def employee
    @employee ||= @data['employee'] || (self.prev ? self.prev.employee : 'Me')
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
    self.class.parse_tags(@data['tags'])
  end

  def working_day?
    !date.saturday? && !date.sunday? && !tags.include?('holiday')
  end

  def matches?(filters)
    from = (filters[:from] ? filters[:from] : nil)
    from = from.to_time if from.is_a?(Date)
    to = (filters[:to] ? filters[:to] : nil)
    to = (to + 1).to_time if to.is_a?(Date)
    tags = self.class.parse_tags(filters[:tags])

    has_tags?(tags) &&
    self.class.attrib_matches_any?(employee, filters[:employee]) &&
    self.class.attrib_matches_any?(description, filters[:description]) &&
    self.class.attrib_matches_any?(project, filters[:project]) &&
    self.class.attrib_matches_any?(activity, filters[:activity]) &&
    (!from || from <= self.start) &&
    (!to || to >= self.end)
  end

  def has_tags?(tags)
    return true if tags.empty?

    tags.all? do |tag|
      if tag.match?(/^\!/)
        t = tag.gsub(/\!/, '')
        !self.tags.include?(t)
      else
        self.tags.include?(tag)
      end
    end
  end

  def valid?
    valid!
    true
  rescue TimeSheet::Time::Exception => e
    self.exception = e
    false
  rescue StandardError => e
    binding.pry if TimeSheet.options[:debug]
    false
  end

  def valid!
    if !@data['start']
      raise TimeSheet::Time::Exception.new('time entry has no start')
    end

    if duration <= 0
      raise TimeSheet::Time::Exception.new('time entry duration is 0 or less')
    end

    if (self.start >= self.end) && self.next
      raise TimeSheet::Time::Exception.new('time entry has no end')
    end

    if !employee
      raise TimeSheet::Time::Exception.new('no employee set')
    end
  end

  def to_row
    [
      employee, date, start, self.end, duration.to_i, project, activity,
      description
    ]
  end

  def to_s
    values = [
      employee,
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
      'employee' => employee,
      'date' => date,
      'start' => start,
      'end' => self.end,
      'duration' => duration,
      'project' => project,
      'activity' => activity,
      'description' => description,
      'tags' => tags
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

  def self.parse_tags(string)
    (string || '').to_s.downcase.split(/\s*,\s*/).map{|t| t.strip}
  end

end