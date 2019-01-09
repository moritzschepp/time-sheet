require "spec_helper"

RSpec.describe TimeSheet do
  it "has a version number" do
    expect(TimeSheet::VERSION).not_to be nil
  end
end
