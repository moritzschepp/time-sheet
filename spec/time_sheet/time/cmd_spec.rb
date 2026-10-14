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
end
