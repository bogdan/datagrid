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

    it "should work for every filter type" do
      Datagrid::Filters::FILTER_TYPES.each do |type, klass|
        Datagrid::FormBuilder.instance_methods.map(&:to_sym).should include(klass.form_builder_helper_name)
      end
    end

    subject { view.datagrid_filter(_filter, _filter_options)}
    let(:_filter_options) { {} }
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

    context "with date filter type" do
      let(:_filter) { :created_at }
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:created_at, :date)
        end
      }
      it { should equal_to_dom(
        '<input class="created_at date_filter" id="report_created_at" name="report[created_at]" size="30" type="text"/>'
      )}
    end

    context "with integer filter type and range option" do
      let(:_filter) { :group_id }
      let(:_grid) {
        test_report(:group_id => _range) do
          scope {Entry}
          filter(:group_id, :integer, :range => true)
        end
      }
      context "when datagrid_filter options has id" do
        let(:_filter_options) { {:id => "hello"} }
        let(:_range) { [1,2]}
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" id="from_hello" multiple name="report[group_id][]" size="30" type="text" value="1"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" id="to_hello" multiple name="report[group_id][]" size="30" type="text" value="2"/>'
        )}
      end
      context "with only left bound" do
        
        let(:_range) { [10, nil]}
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple name="report[group_id][]" size="30" type="text" value="10"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple name="report[group_id][]" size="30" type="text"/>'
        )}
        it { should be_html_safe }
      end
      context "with only right bound" do
        let(:_range) { [nil, 10]}
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple name="report[group_id][]" size="30" type="text"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple name="report[group_id][]" size="30" type="text" value="10"/>'
        )}
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { 2..1 }
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple name="report[group_id][]" size="30" type="text" value="2"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple name="report[group_id][]" size="30" type="text" value="1"/>'
        )}
      end
    end


    context "with date filter type and range option" do
      let(:_filter) { :created_at }
      let(:_grid) {
        test_report(:created_at => _range) do
          scope {Entry}
          filter(:created_at, :date, :range => true)
        end
      }
      context "with only left bound" do
        
        let(:_range) { ["2012-01-03", nil]}
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple name="report[created_at][]" size="30" type="text" value="2012-01-03"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple name="report[created_at][]" size="30" type="text"/>'
        )}
        it { should be_html_safe }
      end
      context "when special date format specified" do
        around(:each) do |example|
          with_date_format do
            example.run
          end
        end
        let(:_range) { ["2013/01/01", '2013/02/02']}
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple name="report[created_at][]" size="30" type="text" value="01/01/2013"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple name="report[created_at][]" size="30" type="text" value="02/02/2013"/>'
        )}
      end
      context "with only right bound" do
        
        let(:_range) { [nil, "2012-01-03"]}
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple name="report[created_at][]" size="30" type="text"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple name="report[created_at][]" size="30" type="text" value="2012-01-03"/>'
        )}
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { Date.parse('2012-01-02')..Date.parse('2012-01-01') }
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple name="report[created_at][]" size="30" type="text" value="2012-01-02"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple name="report[created_at][]" size="30" type="text" value="2012-01-01"/>'
        )}
      end
      context "with blank range value" do
        around(:each) do |example|
          with_date_format do
            example.run
          end
        end
        let(:_range) { [nil, nil] }
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple name="report[created_at][]" size="30" type="text"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple name="report[created_at][]" size="30" type="text"/>'
        )}
      end
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
       <option value="YES">Yes</option>
       <option value="NO">No</option></select>'
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
    context "with float filter type" do
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:group_id, :float)
        end
      }
      let(:_filter) { :group_id }
      it { should equal_to_dom(
        '<input class="group_id float_filter" id="report_group_id" name="report[group_id]" size="30" type="text"/>'
      )}

    end

    context "with enum multiple filter" do
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(:group_id, :enum, :select => ['hello'], :multiple => true)
        end
      end
      let(:_filter) { :group_id }
      let(:expected_html) do
        if ActionPack::VERSION::MAJOR == 3 && ActionPack::VERSION::MINOR < 2
          <<-HTML
<select class="group_id enum_filter" id="report_group_id" multiple name="report[group_id][]">
<option value="hello">hello</option></select>
          HTML
        else
          <<-HTML
<input name="report[group_id][]" type="hidden" value=""><select class="group_id enum_filter" id="report_group_id" multiple name="report[group_id][]">
<option value="hello">hello</option></select>
          HTML
        end
      end

      it { should equal_to_dom(expected_html) }
    end

    context "with column names filter" do
      let(:_grid) do
        test_report(:column_names => [:id, :name]) do
          scope {Entry}

          column_names_filter

          column(:id)
          column(:name)
          column(:category)
        end       
      end
      let(:_filter) { :column_names }
      let(:expected_html) do
        if ActionPack::VERSION::MAJOR == 3 && ActionPack::VERSION::MINOR < 2
          <<-HTML
<select class="column_names enum_filter" id="report_column_names" multiple name="report[column_names][]"><option value="id" selected>Id</option>
<option value="name" selected>Name</option>
<option value="category">Category</option></select>
          HTML
        else
          <<-HTML
<input name="report[column_names][]" type="hidden" value=""><select class="column_names enum_filter" id="report_column_names" multiple name="report[column_names][]"><option value="id" selected>Id</option>
<option value="name" selected>Name</option>
<option value="category">Category</option></select>
          HTML
        end
      end

      it { should equal_to_dom(expected_html) }
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
        '<label class="foo" for="report_name">Name</label>'
      )
    end
  end
end
