require 'spec_helper'


class MyFormBuilder
  include Datagrid::FormBuilder
end

class MyTemplate
  include ActionView::Helpers::FormHelper
end


describe Datagrid::FormBuilder do

  let(:template) { MyTemplate.new}
  subject { ActionView::Helpers::FormBuilder.new(:report, SimpleReport.new, template, {}, Proc.new {|f| }) }


  describe ".report_filter" do

    it "should render default filter" do
      subject.report_filter(:name).should have_dom(
        '<input class="name default_filter" id="report_name" name="report[name]" size="30" type="text"/>'
      )
    end
    
  end
  
end
