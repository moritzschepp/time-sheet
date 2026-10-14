require "spec_helper"
require "stringio"

RSpec.describe TimeSheet::Time::Cmd do
  subject(:cmd) { described_class.new }

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  let(:base_options) do
    {
      location: ["spec/data/time_log.xlsx"],
      from: Time.mktime(2017, 8, 1),
      to: Time.mktime(2017, 8, 5),
      carry_over_activity: 'previous',
      trim: false
    }
  end

  def options_with(hash)
    base_options.merge(hash)
  end

  it 'does not print the package progress line without a package size' do
    cmd.instance_variable_set(:@options, options_with(package: 0.0))

    output = capture_stdout { cmd.invoice }

    expect(output).not_to include('current package')
    expect(output).to include('Tags:')
  end

  it 'prints the package progress line when a package size is given' do
    cmd.instance_variable_set(:@options, options_with(package: 4))

    output = capture_stdout { cmd.invoice }

    expect(output).to include('current package')
    expect(output).to include('Tags:')
  end

  it 'keeps the tag summary on unboosted time' do
    cmd.instance_variable_set(:@options, options_with(package: 0.0, tag_boosts: {'ai' => 2.0}))

    output = capture_stdout { cmd.invoice }

    expect(output).to include('ai: 4.62 h (26.3%)')
  end

  it 'drops the matching part of descriptions in report output' do
    cmd.instance_variable_set(:@options, options_with(filter_descriptions: 'finish '))

    output = capture_stdout { cmd.report }

    expect(output).to include('OAI-PMH export script for John')
    expect(output).not_to include('finish OAI-PMH')
  end

  it 'drops the matching part of descriptions in invoice output' do
    cmd.instance_variable_set(:@options, options_with(package: 0.0, filter_descriptions: 'finish '))

    output = capture_stdout { cmd.invoice }

    expect(output).to include('OAI-PMH export script for John')
    expect(output).not_to include('finish OAI-PMH')
  end

  describe '#parse_tag_boosts' do
    it 'parses comma-separated tag:factor pairs' do
      expect(cmd.parse_tag_boosts('ai:1.4, physical:0.75')).to eq('ai' => 1.4, 'physical' => 0.75)
    end

    it 'lowercases the tag names' do
      expect(cmd.parse_tag_boosts('AI:2')).to eq('ai' => 2.0)
    end

    it 'returns an empty hash for blank input' do
      expect(cmd.parse_tag_boosts(nil)).to eq({})
      expect(cmd.parse_tag_boosts('')).to eq({})
    end
  end
end
