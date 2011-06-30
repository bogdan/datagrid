require 'spec_helper'


class MyFormBuilder
  include Datagrid::FormBuilder
end

class MyTemplate
  include ActionView::Helpers::FormHelper
end


describe Datagrid::FormBuilder do

  let(:template) { ActionView::Base.new}
  let(:grid) { SimpleReport.new }
  let(:view) { ActionView::Helpers::FormBuilder.new(:report, grid, template, {}, Proc.new {|f| })}
  subject { view }


  describe ".datagrid_filter" do

    subject { view.datagrid_filter(_filter)}
    context "with default filter type" do
      let(:_filter) { :name }
      it { should equal_to_dom(
        '<input class="name default_filter" id="report_name" name="report[name]" size="30" type="text"/>'
      )}
    end
    context "with integer filter type" do
      let(:_filter) { :group_id }
      it { should equal_to_dom(
        '<input class="group_id integer_filter" id="report_group_id" name="report[group_id]" size="30" type="text" value=""/>'
      )}
    end
    context "with enum filter type" do
      let(:_filter) { :category }
      it { should equal_to_dom(
        '<select class="category enum_filter" id="report_category" name="report[category][]"><option value=""></option>
       <option value="first">first</option>
       <option value="second">second</option></select>'
      )}
      context "when first option is selected" do
        before(:each) do
          grid.category = "first"
        end
        it { should equal_to_dom(
          '<select class="category enum_filter" id="report_category" name="report[category][]"><option value=""></option>
       <option value="first" selected="true">first</option>
       <option value="second">second</option></select>'
        )}
      end
    end

    context "with eboolean filter type" do
      let(:_filter) { :disabled }
      it { should equal_to_dom(
        '<select class="disabled boolean_enum_filter" id="report_disabled" name="report[disabled][]"><option value=""></option>
       <option value="YES">YES</option>
       <option value="NO">NO</option></select>'
      )} #TODO: review unwanted [] in name here
    end
    context "with string filter" do
      let(:grid) do
        test_report do
          scope {Entry}
          filter(:name, :string)
        end
      end

      let(:_filter) { :name }

    it {should equal_to_dom('<input class="name string_filter" id="report_name" name="report[name]" size="30" type="text">')}
    end
  end

  describe ".datagrid_label" do
    it "should generate label for filter" do
      view.datagrid_label(:name).should equal_to_dom(
        '<label for="report_name">Name</label>'
      )
    end
  end

end




