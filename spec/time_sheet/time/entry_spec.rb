require "spec_helper"

RSpec.describe TimeSheet::Time::Entry do
  def entry(data)
    described_class.new(data)
  end

  def link(entries)
    entries.each_cons(2){|a, b| b.prev = a}
    entries
  end

  let(:base) do
    {
      'date' => Date.new(2017, 8, 1),
      'project' => 'project1',
      'activity' => 'dev',
      'description' => 'work on forms'
    }
  end

  it 'parses a comma-separated tag list' do
    e = entry(base.merge('tags' => 'ai, urgent'))
    expect(e.tags).to eq(%w[ai urgent])
  end

  it 'carries tags over when project, activity and description match' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base)
    link([first, second])
    expect(second.tags).to eq(['ai'])
  end

  it 'does not carry tags over when the description changes' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base.merge('description' => 'something else'))
    link([first, second])
    expect(second.tags).to eq([])
  end

  it 'does not carry tags over when the activity changes' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base.merge('activity' => 'ops'))
    link([first, second])
    expect(second.tags).to eq([])
  end

  it 'does not carry tags over when the project changes' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base.merge('project' => 'project2'))
    link([first, second])
    expect(second.tags).to eq([])
  end

  it 'keeps its own tags even when they differ from the previous entry' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base.merge('tags' => 'ops'))
    link([first, second])
    expect(second.tags).to eq(['ops'])
  end

  it 'carries tags over a run of matching entries' do
    first = entry(base.merge('tags' => 'ai'))
    second = entry(base)
    third = entry(base)
    link([first, second, third])
    expect(third.tags).to eq(['ai'])
  end

  describe 'tag boosts' do
    after { TimeSheet.options = nil }

    it 'multiplies the duration by the factor of a tag' do
      TimeSheet.options = {tag_boosts: {'ai' => 1.4}}
      e = entry(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'tags' => 'ai'))
      expect(e.factor).to eq(1.4)
      expect(e.duration).to be_within(0.001).of(84.0)
    end

    it 'multiplies the factors of several tags' do
      TimeSheet.options = {tag_boosts: {'ai' => 1.4, 'physical' => 0.75}}
      e = entry(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'tags' => 'ai,physical'))
      expect(e.duration).to be_within(0.001).of(63.0)
    end

    it 'leaves untagged and unboosted entries unchanged' do
      TimeSheet.options = {tag_boosts: {'ai' => 1.4}}
      untagged = entry(base.merge('start' => 9 * 3600, 'end' => 10 * 3600))
      other = entry(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'tags' => 'other'))
      expect(untagged.duration).to eq(60.0)
      expect(other.duration).to eq(60.0)
    end

    it 'leaves the duration unchanged when no boosts are configured' do
      TimeSheet.options = nil
      e = entry(base.merge('start' => 9 * 3600, 'end' => 10 * 3600, 'tags' => 'ai'))
      expect(e.duration).to eq(60.0)
    end
  end
end
