require 'spec_helper'
require 'time'

RSpec.describe Mps::Time::Util do

  before :each do
    @now = Time.parse(self.class.description)
    allow(Time).to receive(:now) {@now}
  end

  context '2017-11-30 8:55' do
    it 'should calculate today' do
      expect(subject.today).to eq(Date.parse '2017-11-30')
    end

    it 'should calculate yesterday' do
      expect(subject.yesterday).to eq(Date.parse '2017-11-29')
    end
  end

  context '2017-12-01 16:33' do
    it 'should calculate today' do
      expect(subject.today).to eq(Date.parse '2017-12-01')
    end

    it 'should calculate yesterday' do
      expect(subject.yesterday).to eq(Date.parse '2017-11-30')
    end
  end

  context '2018-01-03 0:55' do
    it 'should calculate this week' do
      expect(subject.week_start).to eq(Date.parse '2018-01-01')
      expect(subject.week_end).to eq(Date.parse '2018-01-07')
    end

    it 'should calculate last week' do
      expect(subject.week_start(-1)).to eq(Date.parse '2017-12-25')
      expect(subject.week_end(-1)).to eq(Date.parse '2017-12-31')
    end

    # make it work with timecop
    # it 'should calculate this month' do
    #   expect(subject.month_start).to eq(Date.parse('2018-01-01'))
    #   expect(subject.month_end).to eq(Date.parse('2018-01-31'))
    # end

    # make it work with timecop
    # it 'should calculate last month' do
    #   expect(subject.month_start(-1)).to eq(Date.parse('2017-12-01'))
    #   expect(subject.month_end(-1)).to eq(Date.parse('2017-12-31'))
    # end

    it 'should calculate this year' do
      expect(subject.year_start).to eq(Date.parse('2018-01-01'))
      expect(subject.year_end).to eq(Date.parse('2018-12-31'))
    end

    it 'should calculate last year' do
      expect(subject.year_start(-1)).to eq(Date.parse('2017-01-01'))
      expect(subject.year_end(-1)).to eq(Date.parse('2017-12-31'))
    end
  end

end