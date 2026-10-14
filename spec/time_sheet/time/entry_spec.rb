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
end
