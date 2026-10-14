require "spec_helper"

RSpec.describe TimeSheet::Time do
  it 'should deal well with time entries overflowing a package' do
    opts = {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1, 14),
      to: Time.mktime(2017, 8, 1, 17),
      package: 1
    }
    data = described_class.invoice(opts)

    expect(data.size).to eq(3)
    expect(data[0].length).to eq(1)
    expect(data[0].first[1]).to eq(60)
    expect(data[1].length).to eq(1)
    expect(data[1].first[1]).to eq(60)
    expect(data[2].length).to eq(1)
    expect(data[2].first[1]).to eq(30)
  end

  it 'should deal well with time entries exactly completing a package' do
    opts = {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1, 14),
      to: Time.mktime(2017, 8, 1, 19),
      package: 1
    }
    data = described_class.invoice(opts)

    expect(data.size).to eq(5)
    expect(data[4].last[1]).to eq(60)
  end

  it 'should total the durations of tagged entries' do
    opts = {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1),
      to: Time.mktime(2017, 8, 5),
      carry_over_activity: 'previous'
    }
    data = described_class.report(opts)

    # 87 + 60 + 36 + 62, plus 32 carried over to the matching 13:02 row
    expect(data['tags']).to eq('ai' => 277.0)
  end

  it 'should count an entry with several tags fully under each tag' do
    base = {
      'date' => Date.new(2017, 8, 1),
      'project' => 'project1',
      'activity' => 'dev',
      'description' => 'work'
    }
    entries = [
      TimeSheet::Time::Entry.new(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'tags' => 'x,y')),
      TimeSheet::Time::Entry.new(base.merge('start' => 10 * 3600, 'end' => 10 * 3600 + 1800))
    ]
    entries.each_cons(2){|a, b| b.prev = a}

    expect(described_class.tag_totals(entries)).to eq('x' => 90.0, 'y' => 90.0)
  end

  it 'should total tags for the entries selected by the invoice command' do
    opts = {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1),
      to: Time.mktime(2017, 8, 5),
      carry_over_activity: 'previous'
    }
    entries = described_class.matching_entries(opts)

    expect(described_class.tag_totals(entries)).to eq('ai' => 277.0)
  end

  it 'should boost the durations of tagged entries but not the tag summary' do
    opts = {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1),
      to: Time.mktime(2017, 8, 5),
      carry_over_activity: 'previous',
      tag_boosts: {'ai' => 1.4}
    }
    data = described_class.report(opts)

    # the totals are boosted, the tag summary stays unboosted
    expect(data['total']).to be_within(0.001).of(1163.8)
    expect(data['raw_total']).to eq(1053.0)
    expect(data['tags']['ai']).to eq(277.0)
  end

  it 'should filter descriptions when rendering invoice rows without merging them' do
    base = {'date' => Date.new(2017, 8, 1), 'project' => 'p', 'activity' => 'a'}
    entries = [
      TimeSheet::Time::Entry.new(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'description' => 'mail to Tom')),
      TimeSheet::Time::Entry.new(base.merge('start' => 10 * 3600, 'end' => 11 * 3600, 'description' => 'mail to Lana'))
    ]
    options = {package: 0, petty: nil, filter_descriptions: 'Tom|Lana'}

    packages = described_class.invoice_entries(entries, options)

    expect(packages.first.size).to eq(2)
    expect(packages.first.map{|row| row[2]}).to eq(['mail to ', 'mail to '])
  end
end
