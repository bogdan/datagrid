# encoding: UTF-8
require 'spec_helper'

class MyFormBuilder
  include Datagrid::FormBuilder
end

class MyTemplate
  include ActionView::Helpers::FormHelper
end


describe Datagrid::FormBuilder do

  let(:template) do
    ActionView::Base.new.tap do |v|
      v.view_paths << File.expand_path("../../../app/views", __FILE__)
      v.view_paths << File.expand_path("../../support/test_partials", __FILE__)
    end
  end
  let(:view) { ActionView::Helpers::FormBuilder.new(:report, _grid, template, view_options)}
  let(:view_options) { {} }


  describe ".datagrid_filter" do

    it "should work for every filter type" do
      Datagrid::Filters::FILTER_TYPES.each do |type, klass|
        expect(Datagrid::FormBuilder.instance_methods.map(&:to_sym)).to include(klass.form_builder_helper_name)
      end
    end

    subject do
      view.datagrid_filter(_filter, _filter_options, &_filter_block)
    end

    let(:_filter_options) { {} }
    let(:_filter_block) { nil }
    context "with default filter type" do
      let(:_grid) {
        test_report do
          scope {Entry}
          filter(:name)
        end
      }
      let(:_filter) { :name }
      it { should equal_to_dom(
        '<input class="name default_filter" type="text" name="report[name]" id="report_name"/>'
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
        '<input class="group_id integer_filter" type="text" name="report[group_id]" id="report_group_id"/>'
      )}

      context "when partials option is passed for filter that don't support range" do
        let(:view_options) { {partials: 'anything' } }
        it { should equal_to_dom(
          '<input class="group_id integer_filter" type="text" name="report[group_id]" id="report_group_id"/>'
        )}
      end
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
        '<input class="created_at date_filter" type="text" name="report[created_at]" id="report_created_at"/>'
      )}
      context "when special date format specified" do
        around(:each) do |example|
          _grid.created_at = Date.parse('2012-01-02')
          with_date_format do
            example.run
          end
        end
        it { should equal_to_dom(
          '<input value="01/02/2012" class="created_at date_filter" type="text" name="report[created_at]" id="report_created_at"/>'
        )}
      end
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
          '<input id="from_hello" class="group_id integer_filter from" multiple value="1" type="text" name="report[group_id][]"/>' +
          '<span class="separator integer"> - </span>' +
          '<input id="to_hello" class="group_id integer_filter to" multiple value="2" type="text" name="report[group_id][]"/>'
        )}
      end
      context "with only left bound" do

        let(:_range) { [10, nil]}
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple value="10" type="text" name="report[group_id][]"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple type="text" name="report[group_id][]"/>'
        )}
        it { should be_html_safe }
      end
      context "with only right bound" do
        let(:_range) { [nil, 10]}
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple type="text" name="report[group_id][]"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple value="10" type="text" name="report[group_id][]"/>'
        )}
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { 2..1 }
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple value="1" type="text" name="report[group_id][]"/>' +
          '<span class="separator integer"> - </span>' +
          '<input class="group_id integer_filter to" multiple value="2" type="text" name="report[group_id][]"/>'
        )}
      end

      context "with custom partials option and template exists" do
        let(:view_options) { { :partials => 'custom_range' } }
        let(:_range) { nil }
        it { should equal_to_dom(
          "custom_range_partial"
        ) }
      end

      context "when custom partial doesn't exist" do
        let(:view_options) { { :partials => 'not_existed' } }
        let(:_range) { nil }
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple type="text" name="report[group_id][]"><span class="separator integer"> - </span><input class="group_id integer_filter to" multiple type="text" name="report[group_id][]">'
        ) }

      end

      context "when deprecated format translation specified" do
        let(:_range) { nil }
        around(:each) do |example|
          store_translations(:en, datagrid: {filters: {integer: {range_format: "from %{from_input} to %{to_input}"}}}) do
            silence_warnings do
              example.run
            end
          end
        end
        it { should equal_to_dom(
          'from <input class="group_id integer_filter from" multiple type="text" name="report[group_id][]"> to <input class="group_id integer_filter to" multiple type="text" name="report[group_id][]">'
        )}
      end
      context "when deprecated separator is specified" do
        let(:_range) { nil }
        around(:each) do |example|
          store_translations(:en, datagrid: {filters: {integer: {range_separator: " | "}}}) do
            silence_warnings do
              example.run
            end
          end
        end
        it { should equal_to_dom(
          '<input class="group_id integer_filter from" multiple type="text" name="report[group_id][]"> | <input class="group_id integer_filter to" multiple type="text" name="report[group_id][]">'
        )}
      end
    end
    context "with float filter type and range option" do
      let(:_filter) { :rating }
      let(:_grid) {
        test_report(:rating => _range) do
          scope {Group}
          filter(:rating, :float, :range => true)
        end
      }
      let(:_range) { [1.5,2.5]}
      it { should equal_to_dom(
        '<input class="rating float_filter from" multiple value="1.5" type="text" name="report[rating][]"/>' +
        '<span class="separator float"> - </span>' +
        '<input class="rating float_filter to" multiple value="2.5" type="text" name="report[rating][]"/>'
      )}
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
          '<input class="created_at date_filter from" multiple value="2012-01-03" type="text" name="report[created_at][]"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple type="text" name="report[created_at][]"/>'
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
          '<input class="created_at date_filter from" multiple value="01/01/2013" type="text" name="report[created_at][]"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple value="02/02/2013" type="text" name="report[created_at][]"/>'
        )}
      end
      context "with only right bound" do

        let(:_range) { [nil, "2012-01-03"]}
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple type="text" name="report[created_at][]"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple value="2012-01-03" type="text"  name="report[created_at][]"/>'
        )}
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { Date.parse('2012-01-02')..Date.parse('2012-01-01') }
        it { should equal_to_dom(
          '<input class="created_at date_filter from" multiple value="2012-01-01" type="text" name="report[created_at][]"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple value="2012-01-02" type="text" name="report[created_at][]"/>'
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
          '<input class="created_at date_filter from" multiple type="text" name="report[created_at][]"/>' +
          '<span class="separator date"> - </span>' +
          '<input class="created_at date_filter to" multiple type="text" name="report[created_at][]"/>'
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
        '<select class="category enum_filter" name="report[category]" id="report_category"><option value=""></option>
       <option value="first">first</option>
       <option value="second">second</option></select>'
      )}

      context "when block is given" do
        before(:each) do
          skip("not supported by rails < 4.1") if Rails.version < '4.1'
        end
        let(:_filter_block ) do
          proc do
            template.content_tag(:option, 'block option', :value => 'block_value')
          end
        end
        it { should equal_to_dom(
          '<select class="category enum_filter" name="report[category]" id="report_category"><option value=""></option>
          <option value="block_value">block option</option></select>'
        )}
      end
      context "when first option is selected" do
        before(:each) do
          _grid.category = "first"
        end
        it { should equal_to_dom(
          '<select class="category enum_filter" name="report[category]" id="report_category"><option value=""></option>
       <option selected value="first">first</option>
       <option value="second">second</option></select>'
        )}
      end
      context "with include_blank option set to false" do
        let(:_filter) { :category_without_include_blank }
        it { should equal_to_dom(
          '<select class="category_without_include_blank enum_filter" name="report[category_without_include_blank]" id="report_category_without_include_blank">
         <option value="first">first</option>
         <option value="second">second</option></select>'
        )}
      end
      context "with dynamic include_blank option" do
        let(:_grid) do
          test_report do
            scope {Entry}
              filter(:category, :enum, :select => ["first", "second"], :include_blank => proc { "Choose plz" })
          end
        end
        let(:_filter) { :category }
        it { should equal_to_dom(
          '<select class="category enum_filter" name="report[category]" id="report_category">
         <option value="">Choose plz</option>
         <option value="first">first</option>
         <option value="second">second</option></select>'
        )}
      end

      context "with prompt option" do
        let(:_filter) { :category_with_prompt }
        it { should equal_to_dom(
          '<select class="category_with_prompt enum_filter" name="report[category_with_prompt]" id="report_category_with_prompt"><option value="">My Prompt</option>
         <option value="first">first</option>
         <option value="second">second</option></select>'
        )}
      end
      context "with checkboxes option" do
        let(:_grid) do
          test_report do
            scope {Entry}
            filter(:category, :enum, :select => ["first", "second"], :checkboxes => true)
          end
        end
        let(:_filter) { :category }
        if Rails.version >= "4.1"
          it { should equal_to_dom(
            '
<label class="category enum_filter checkboxes" for="report_category_first"><input id="report_category_first" type="checkbox" value="first" name="report[category][]" />first</label>
<label class="category enum_filter checkboxes" for="report_category_second"><input id="report_category_second" type="checkbox" value="second" name="report[category][]" />second</label>
            '
          )}
        else
          it { should equal_to_dom(
            '
<label class="category enum_filter checkboxes" for="report_category_first"><input id="report_category_first" name="report[category][]" type="checkbox" value="first" />first</label>
<label class="category enum_filter checkboxes" for="report_category_second"><input id="report_category_second" name="report[category][]" type="checkbox" value="second" />second</label>
            '
          )}


        end

        context "when partials option passed and partial exists" do
          let(:view_options) { {partials: 'custom_checkboxes'} }
          it { should equal_to_dom('custom_enum_checkboxes') }
        end
      end
    end

    context "with boolean filter type" do
      let(:_filter) { :disabled }
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(:disabled, :boolean, default: true)
        end
      end
      it { should equal_to_dom(
        # hidden is important when default is set to true
        '<input name="report[disabled]" type="hidden" value="0"><input class="disabled boolean_filter" type="checkbox" value="1" checked name="report[disabled]" id="report_disabled">'
      )}
    end
    context "with xboolean filter type" do
      let(:_filter) { :disabled }
      let(:_grid) do
        test_report do
          scope {Entry}
          filter(:disabled, :xboolean)
        end
      end
      it { should equal_to_dom(
        '<select class="disabled extended_boolean_filter" name="report[disabled]" id="report_disabled"><option value=""></option>
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

      it {should equal_to_dom('<input class="name string_filter" type="text" name="report[name]" id="report_name">')}

      context "when multiple option is set" do
      let(:_grid) do
        test_report(:name => "one,two") do
          scope {Entry}
          filter(:name, :string, :multiple => true)
        end
      end

      let(:_filter) { :name }

      it {should equal_to_dom('<input value="one,two" class="name string_filter" type="text" name="report[name]" id="report_name">')}
      end
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
      it {should equal_to_dom('<select class="name enum_filter" name="report[name]" id="report_name"></select>')}
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
        '<input class="group_id float_filter" type="text" name="report[group_id]" id="report_group_id"/>'
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
        <<-HTML
<select class="group_id enum_filter" multiple name="report[group_id][]" id="report_group_id">
<option value="hello">hello</option></select>
        HTML
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
        <<-HTML
<select class="column_names enum_filter" multiple name="report[column_names][]" id="report_column_names"><option selected value="id">Id</option>
<option selected value="name">Name</option>
<option value="category">Category</option></select>
        HTML
      end

      it { should equal_to_dom(expected_html) }
    end
    context "with column_names_filter default given as symbols" do
      let(:_grid) do
        test_report() do
          scope {Entry}

          column_names_filter(:default => [:id, :name], :checkboxes => true)

          column(:id)
          column(:name)
          column(:category)
        end
      end
      let(:_filter) { :column_names }
      let(:expected_html) do
        <<DOM
<label class="column_names enum_filter checkboxes" for="report_column_names_id"><input id="report_column_names_id" type="checkbox" value="id" checked name="report[column_names][]">Id</label>
<label class="column_names enum_filter checkboxes" for="report_column_names_name"><input id="report_column_names_name" type="checkbox" value="name" checked name="report[column_names][]">Name</label>
<label class="column_names enum_filter checkboxes" for="report_column_names_category"><input id="report_column_names_category" type="checkbox" value="category" name="report[column_names][]">Category</label>
DOM
      end

      it do
        should equal_to_dom(expected_html)
      end
    end

    context "with dynamic filter" do
      let(:filter_options) do
        {}
      end

      let(:_grid) do
        options = filter_options
        test_report do
          scope {Entry}
          filter(:condition, :dynamic, options)
        end
      end
      let(:_filter) { :condition }
      context "with no options" do
        let(:expected_html) do
          <<-HTML
         <select class="condition dynamic_filter field" name="report[condition][]" id="report_condition"><option value="id">Id</option>
         <option value="group_id">Group</option>
         <option value="name">Name</option>
         <option value="category">Category</option>
         <option value="access_level">Access level</option>
         <option value="pet">Pet</option>
         <option value="disabled">Disabled</option>
         <option value="confirmed">Confirmed</option>
         <option value="shipping_date">Shipping date</option>
         <option value="created_at">Created at</option>
         <option value="updated_at">Updated at</option></select><select class="condition dynamic_filter operation" name="report[condition][]" id="report_condition"><option value="=">=</option>
         <option value="=~">&asymp;</option>
         <option value="&gt;=">&ge;</option>
         <option value="&lt;=">&le;</option></select><input class="condition dynamic_filter value"  name="report[condition][]" type="text" id="report_condition">
          HTML
        end
        it {should equal_to_dom(expected_html)}

      end
      context "when default option passed" do
        let(:filter_options) do
          {:select => [:id, :name], :default => [:id, '>=', 1]}
        end
        let(:expected_html) do
          <<-HTML
            <select class="condition dynamic_filter field" name="report[condition][]" id="report_condition"><option selected value="id">id</option>
       <option value="name">name</option></select><select class="condition dynamic_filter operation" name="report[condition][]" id="report_condition"><option value="=">=</option>
       <option value="=~">&asymp;</option>
       <option selected value="&gt;=">&ge;</option>
       <option value="&lt;=">&le;</option></select><input class="condition dynamic_filter value" name="report[condition][]" value="1" type="text"  id="report_condition">
          HTML
        end
        it {should equal_to_dom(expected_html)}

      end

      context "when operations and options are defined" do
        let(:filter_options) do
          {:operations => %w(>= <=), :select => [:id, :name]}
        end
        let(:expected_html) do
          <<-HTML
          <select class="condition dynamic_filter field" name="report[condition][]" id="report_condition"><option value="id">id</option><option value="name">name</option></select><select class="condition dynamic_filter operation" name="report[condition][]" id="report_condition"><option value="&gt;=">≥</option>
       <option value="&lt;=">≤</option></select><input class="condition dynamic_filter value" name="report[condition][]" type="text" id="report_condition">
          HTML
        end
        it {should equal_to_dom(expected_html)}
      end

      context "when the field is predefined" do
        let(:filter_options) do
          {:operations => %w(>= <=), :select => [:id]}
        end
        let(:expected_html) do
          <<-HTML
          <input class="condition dynamic_filter field" name="report[condition][]" value="id" type="hidden" id="report_condition"><select class="condition dynamic_filter operation" name="report[condition][]" id="report_condition"><option value="&gt;=">≥</option>
       <option value="&lt;=">≤</option></select><input class="condition dynamic_filter value" name="report[condition][]" type="text" id="report_condition">
          HTML
        end
        it {should equal_to_dom(expected_html)}
      end
      context "when operation is predefined" do
        let(:filter_options) do
          {:operations => %w(=), :select => [:id, :name]}
        end
        let(:expected_html) do
          <<-HTML
          <select class="condition dynamic_filter field" name="report[condition][]" id="report_condition"><option value="id">id</option><option value="name">name</option></select><input class="condition dynamic_filter operation" name="report[condition][]" value="=" type="hidden" id="report_condition"><input class="condition dynamic_filter value" name="report[condition][]" type="text" id="report_condition">
          HTML
        end
        it {should equal_to_dom(expected_html)}
      end

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
      expect(view.datagrid_label(:name)).to equal_to_dom(
        '<label for="report_name">Name</label>'
      )
    end
    it "should pass options through to the helper" do
      expect(view.datagrid_label(:name, :class => 'foo')).to equal_to_dom(
        '<label class="foo" for="report_name">Name</label>'
      )
    end
    it "should support block" do
      expect(view.datagrid_label(:name, :class => 'foo') { 'The Name' }).to equal_to_dom(
        '<label class="foo" for="report_name">The Name</label>'
      )
    end
    it "should support explicit label" do
      expect(view.datagrid_label(:name, "The Name")).to equal_to_dom(
        '<label for="report_name">The Name</label>'
      )
    end
  end
end
