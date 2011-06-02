require 'spec_helper'
require "will_paginate"

describe Datagrid::Helper do
  subject {ActionView::Base.new}

  before(:each) do
    subject.stub!(:params).and_return({})
    subject.stub!(:url_for).and_return("http://localhost")
  end

  let(:report) { SimpleReport.new }

  describe ".report_table" do
    it "should return data table html" do
      subject.report_table(report).should_not be_empty
    end
  end
  

end
