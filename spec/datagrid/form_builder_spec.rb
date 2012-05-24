require 'spec_helper'


class MyFormBuilder
  include Datagrid::FormBuilder
end

class MyTemplate
  include ActionView::Helpers::FormHelper
end


describe Datagrid::FormBuilder do

  let(:template) { ActionView::Base.new}
  let(:view) { ActionView::Helpers::FormBuilder.new(:report, _grid, template, {}, Proc.new {|f| })}
  subject { view }


  describe ".datagrid_filter" do

    subject { view.datagrid_filter(_filter)}
    context "with default filter type" do
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:name)
        end
      }
      let(:_filter) { :name }
      it { should equal_to_dom(
        '<input class="name default_filter" id="report_name" name="report[name]" size="30" type="text"/>'
      )}
    end
    context "with integer filter type" do
      let(:_filter) { :group_id }
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:group_id, :integer)
        end
      }
      it { should equal_to_dom(
        '<input class="group_id integer_filter" id="report_group_id" name="report[group_id]" size="30" type="text"/>'
      )}
    end
    context "with enum filter type" do
      let(:_filter) { :category }
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:category, :enum, :select => ["first", "second"])
          filter(:category_without_include_blank, :enum, :select => ["first", "second"], :include_blank => false)
          filter(:category_with_prompt, :enum, :select => ["first", "second"], :prompt => "My Prompt")
        end
      }
      it { should equal_to_dom(
        '<select class="category enum_filter" id="report_category" name="report[category]"><option value=""></option>
       <option value="first">first</option>
       <option value="second">second</option></select>'
      )}
      context "when first option is selected" do
        before(:each) do
          _grid.category = "first"
        end
        it { should equal_to_dom(
          '<select class="category enum_filter" id="report_category" name="report[category]"><option value=""></option>
       <option value="first" selected="true">first</option>
       <option value="second">second</option></select>'
        )}
      end
      context "with include_blank option set to false" do
        let(:_filter) { :category_without_include_blank }
        it { should equal_to_dom(
          '<select class="category_without_include_blank enum_filter" id="report_category_without_include_blank" name="report[category_without_include_blank]">
         <option value="first">first</option>
         <option value="second">second</option></select>'
        )}
      end
      context "with prompt option" do
        let(:_filter) { :category_with_prompt }
        it { should equal_to_dom(
          '<select class="category_with_prompt enum_filter" id="report_category_with_prompt" name="report[category_with_prompt]"><option value="">My Prompt</option>
         <option value="first">first</option>
         <option value="second">second</option></select>'
        )}
      end
    end

    context "with eboolean filter type" do
      let(:_filter) { :disabled }
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(:disabled, :eboolean)
        end
      end
      it { should equal_to_dom(
        '<select class="disabled boolean_enum_filter" id="report_disabled" name="report[disabled]"><option value=""></option>
       <option value="YES">YES</option>
       <option value="NO">NO</option></select>'
      )}
    end
    context "with string filter" do
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(:name, :string)
        end
      end

      let(:_filter) { :name }

      it {should equal_to_dom('<input class="name string_filter" id="report_name" name="report[name]" size="30" type="text">')}
    end

    context "with non multiple filter" do
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(
            :name, :enum,
            :include_blank => false,
            :multiple => false,
            :select => []
          )
        end
      end
      let(:_filter) { :name }
      it {should equal_to_dom('<select class="name enum_filter" id="report_name" name="report[name]"></select>')}
    end
  end

  describe ".datagrid_label" do
    let(:_grid) do
      test_report do
        scope {Entry}
        filter(:name, :string)
      end
    end
    it "should generate label for filter" do
      view.datagrid_label(:name).should equal_to_dom(
        '<label for="report_name">Name</label>'
      )
    end
    it "should pass options through to the helper" do
      view.datagrid_label(:name, :class => 'foo').should equal_to_dom(
        '<label for="report_name" class="foo">Name</label>'
      )
    end
  end
end




