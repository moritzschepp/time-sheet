require "spec_helper"

RSpec.describe Mps::Time do
  it 'should deal well with time entries overflowing a package' do
    opts = {
      location: ["spec/data/time_log.xls"],
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
      location: ["spec/data/time_log.xls"],
      from: Time.mktime(2017, 8, 1, 14),
      to: Time.mktime(2017, 8, 1, 19),
      package: 1
    }
    data = described_class.invoice(opts)

    expect(data.size).to eq(5)
    expect(data[4].last[1]).to eq(60)
  end
end