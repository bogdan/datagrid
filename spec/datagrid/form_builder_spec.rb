# frozen_string_literal: true

require "spec_helper"
require "action_controller"

class MyFormBuilder
  include Datagrid::FormBuilder
end

class MyTemplate
  include ActionView::Helpers::FormHelper
end

describe Datagrid::FormBuilder do
  let(:template) do
    action_view_template
  end

  let(:view) do
    ActionView::Helpers::FormBuilder.new(
      :report, _grid, template,
      skip_default_ids: false,
      **view_options,
    )
  end

  let(:view_options) { {} }

  describe ".datagrid_filter" do
    subject do
      view.datagrid_filter(_filter, **_filter_options, &_filter_block)
    end

    let(:_filter_options) { {} }
    let(:_filter_block) { nil }

    context "with default filter type" do
      let(:_grid) do
        test_grid_filter(:name)
      end

      let(:_filter) { :name }
      it {
        should equal_to_dom(<<~HTML)
          <input type="text" name="report[name]" id="report_name"/>
        HTML
      }
    end

    context "with integer filter type" do
      let(:_filter) { :group_id }
      let(:_grid) do
        test_grid_filter(:group_id, :integer)
      end

      it {
        should equal_to_dom(<<~HTML)
          <input type="number" step="1" name="report[group_id]" id="report_group_id"/>
        HTML
      }

      context "when partials option is passed for filter that don't support range" do
        let(:view_options) { { partials: "anything" } }

        it {
          should equal_to_dom(<<~HTML)
            <input type="number" step="1" name="report[group_id]" id="report_group_id"/>
          HTML
        }
      end
    end

    context "with date filter type" do
      let(:_filter) { :created_at }
      let(:_grid) do
        test_grid_filter(:created_at, :date)
      end

      it {
        should equal_to_dom(<<~HTML)
          <input type="date" name="report[created_at]" id="report_created_at"/>
        HTML
      }

      context "when special date format specified" do
        around(:each) do |example|
          _grid.created_at = Date.parse("2012-01-02")
          with_date_format do
            example.run
          end
        end

        it {
          should equal_to_dom(<<~HTML)
            <input value="2012-01-02" type="date" name="report[created_at]" id="report_created_at"/>
          HTML
        }
      end
    end

    context "with input_options" do
      context "date filter type is text" do
        let(:_filter) { :created_at }
        let(:_grid) do
          test_grid_filter(:created_at, :date, input_options: { type: 'text' })
        end

        it {
          should equal_to_dom(<<~HTML)
            <input type="text" name="report[created_at]" id="report_created_at"/>
          HTML
        }
      end

      context "string filter type is textarea" do
        let(:_filter) { :name }
        let(:_grid) do
          test_grid_filter(:name, :string, input_options: { type: :textarea })
        end

        it {
          should equal_to_dom(
            '<textarea name="report[name]" id="report_name"/>',
          )
        }
      end

      context "datetime filter type is text" do
        let(:_filter) { :created_at }
        let(:_grid) do
          created_at = ActiveSupport::TimeZone["UTC"].local(
            2024, 1, 1, 9, 25, 15,
          )
          test_grid(created_at: created_at) do
            scope { Entry }
            filter(:created_at, :datetime, input_options: { type: "text" })
          end
        end

        it {
          should equal_to_dom(<<~HTML)
            <input type="text" value="2024-01-01 09:25:15 UTC" name="report[created_at]" id="report_created_at"/>
          HTML
        }

        context "nil value option" do
          let(:_filter_options) do
            { value: nil }
          end

          it {
            should equal_to_dom(<<~HTML)
              <input type="text" name="report[created_at]" id="report_created_at"/>
            HTML
          }
        end
      end

      context "datetime filter type is date" do
        let(:_filter) { :created_at }
        let(:_grid) do
          test_grid(created_at: Date.new(2024, 1, 1)) do
            scope { Entry }
            filter(:created_at, :datetime, input_options: { type: :date })
          end
        end

        it {
          should equal_to_dom(
            <<~HTML,
              <input type="date" value="2024-01-01" name="report[created_at]" id="report_created_at"/>
            HTML
          )
        }
      end
    end

    context "with integer filter type and range option" do
      let(:_filter) { :group_id }
      let(:_grid) do
        grid = test_grid_filter(:group_id, :integer, range: true)
        grid.group_id = _range
        grid
      end

      context "when datagrid_filter options has id" do
        let(:_filter_options) { { id: "hello" } }
        let(:_range) { [1, 2] }

        it {
          should equal_to_dom(
            '<input value="1" id="hello" class="datagrid-range-from"
                type="number" step="1" name="report[group_id][from]"/>' \
            '<span class="datagrid-range-separator"> - </span>' \
            '<input value="2" class="datagrid-range-to"
                type="number" step="1" name="report[group_id][to]"/>',
          )
        }
      end

      context "with only left bound" do
        let(:_range) { [10, nil] }

        it {
          should equal_to_dom(<<~HTML)
            <input value="10" class="datagrid-range-from" id="report_group_id" type="number" step="1" name="report[group_id][from]"/> \
            <span class="datagrid-range-separator"> - </span>
            <input class="datagrid-range-to" type="number" step="1" name="report[group_id][to]"/>
          HTML
        }
        it { should be_html_safe }
      end

      context "with only right bound" do
        let(:_range) { [nil, 10] }

        it {
          should equal_to_dom(<<~HTML)
            <input class="datagrid-range-from" type="number" step="1" name="report[group_id][from]" id="report_group_id"/>
            <span class="datagrid-range-separator"> - </span>
            <input value="10" class="datagrid-range-to" type="number" step="1" name="report[group_id][to]"/>
          HTML
        }
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { 2..1 }

        it {
          should equal_to_dom(<<~HTML)
            <input value="1" class="datagrid-range-from" type="number" step="1" name="report[group_id][from]" id="report_group_id"/>
            <span class="datagrid-range-separator"> - </span>
            <input value="2" class="datagrid-range-to" type="number" step="1" name="report[group_id][to]"/>
          HTML
        }
      end

      context "with custom partials option and template exists" do
        let(:view_options) { { partials: "custom_range" } }
        let(:_range) { nil }
        it {
          should equal_to_dom(
            "custom_range_partial",
          )
        }
      end

      context "when custom partial doesn't exist" do
        let(:view_options) { { partials: "not_existed" } }
        let(:_range) { nil }
        it {
          should equal_to_dom(<<~HTML)
            <input class="datagrid-range-from" type="number" step="1" name="report[group_id][from]" id="report_group_id">
            <span class="datagrid-range-separator"> - </span>
            <input class="datagrid-range-to" type="number" step="1" name="report[group_id][to]">
          HTML
        }
      end
    end

    context "with float filter type and range option" do
      let(:_filter) { :rating }
      let(:_grid) do
        test_grid(rating: _range) do
          scope { Group }
          filter(:rating, :float, range: true)
        end
      end
      let(:_range) { [1.5, 2.5] }

      it {
        should equal_to_dom(<<~HTML)
          <input value="1.5" class="datagrid-range-from" id="report_rating" type="number" step="any" name="report[rating][from]"/>
          <span class="datagrid-range-separator"> - </span>
          <input value="2.5" class="datagrid-range-to" type="number" step="any" name="report[rating][to]"/>
        HTML
      }
    end

    context "with date filter type and range option" do
      let(:_filter) { :created_at }
      let(:_grid) do
        test_grid(created_at: _range) do
          scope { Entry }
          filter(:created_at, :date, range: true)
        end
      end

      context "with only left bound" do
        let(:_range) { ["2012-01-03", nil] }

        it {
          should equal_to_dom(<<~HTML)
            <input value="2012-01-03" class="datagrid-range-from" type="date" name="report[created_at][from]" id="report_created_at"/>
            <span class="datagrid-range-separator"> - </span>
            <input class="datagrid-range-to" type="date" name="report[created_at][to]" value=""/>
          HTML
        }
        it { should be_html_safe }
      end

      context "when special date format specified" do
        around(:each) do |example|
          with_date_format do
            example.run
          end
        end
        let(:_range) { ["2013/01/01", "2013/02/02"] }

        it {
          should equal_to_dom(<<~HTML)
            <input value="2013-01-01" class="datagrid-range-from" id="report_created_at" type="date" name="report[created_at][from]"/>
            <span class="datagrid-range-separator"> - </span>
            <input value="2013-02-02" class="datagrid-range-to" type="date" name="report[created_at][to]"/>
          HTML
        }
      end

      context "with only right bound" do
        let(:_range) { [nil, "2012-01-03"] }

        it {
          should equal_to_dom(<<~HTML)
            <input class="datagrid-range-from" id="report_created_at" type="date" value="" name="report[created_at][from]"/>
            <span class="datagrid-range-separator"> - </span>
            <input value="2012-01-03" class="datagrid-range-to" type="date" name="report[created_at][to]"/>
          HTML
        }
        it { should be_html_safe }
      end

      context "with invalid range value" do
        let(:_range) { Date.parse("2012-01-02")..Date.parse("2012-01-01") }
        it {
          should equal_to_dom(<<~HTML)
            <input value="2012-01-01" class="datagrid-range-from" id="report_created_at" type="date" name="report[created_at][from]"/>
            <span class="datagrid-range-separator"> - </span>
            <input value="2012-01-02" class="datagrid-range-to" type="date" name="report[created_at][to]"/>
          HTML
        }
      end

      context "with blank range value" do
        around(:each) do |example|
          with_date_format do
            example.run
          end
        end
        let(:_range) { [nil, nil] }
        it {
          should equal_to_dom(<<~HTML)
            <input class="datagrid-range-from" type="date" value="" name="report[created_at][from]" id="report_created_at"/>
            <span class="datagrid-range-separator"> - </span>
            <input class="datagrid-range-to" type="date" value="" name="report[created_at][to]"/>
          HTML
        }
      end
    end
    context "with enum filter type" do
      let(:_filter) { :category }
      let(:_category_filter_options) { {} }
      let(:_grid) do
        filter_options = _category_filter_options
        test_grid_filter(:category, :enum, select: %w[first second], **filter_options)
      end

      it {
        should equal_to_dom(<<~HTML)
          <select name="report[category]" id="report_category">
            <option value="" label=" "></option>
            <option value="first">first</option>
            <option value="second">second</option>
          </select>
        HTML
      }

      context "when block is given" do
        let(:_filter_block) do
          proc do
            template.tag.option("block option", value: "block_value")
          end
        end

        it {
          should equal_to_dom(<<~HTML)
            <select name="report[category]" id="report_category">
              <option value="" label=" "></option>
              <option value="block_value">block option</option>
            </select>
          HTML
        }
      end

      context "when first option is selected" do
        before(:each) do
          _grid.category = "first"
        end

        it {
          should equal_to_dom(<<~HTML)
            <select name="report[category]" id="report_category">
              <option value="" label=" "></option>
              <option selected value="first">first</option>
              <option value="second">second</option>
            </select>
          HTML
        }
      end

      context "with include_blank option set to false" do
        let(:_category_filter_options) { { include_blank: false } }

        it {
          should equal_to_dom(<<~HTML)
            <select name="report[category]" id="report_category">
              <option value="first">first</option>
              <option value="second">second</option>
            </select>
          HTML
        }
      end

      context "with dynamic include_blank option" do
        let(:_category_filter_options) { { include_blank: proc { "Choose plz" } } }

        it {
          should equal_to_dom(<<~HTML)
            <select name="report[category]" id="report_category">
              <option value="">Choose plz</option>
              <option value="first">first</option>
              <option value="second">second</option>
            </select>
          HTML
        }
      end

      context "with prompt option" do
        let(:_category_filter_options) { { prompt: "My Prompt" } }

        it {
          should equal_to_dom(<<~HTML)
            <select name="report[category]" id="report_category">
              <option value="">My Prompt</option>
              <option value="first">first</option>
              <option value="second">second</option>
            </select>
          HTML
        }
      end

      context "with input_options class" do
        let(:_category_filter_options) { { input_options: { class: "custom-class" } } }

        it {
          should equal_to_dom(<<~HTML)
            <select class="custom-class" name="report[category]" id="report_category">
              <option value="" label=" "></option>
              <option value="first">first</option>
              <option value="second">second</option>
            </select>
          HTML
        }
      end

      context "with checkboxes option" do
        let(:_category_filter_options) { { checkboxes: true } }

        it {
          should equal_to_dom(
            <<~HTML,
              <div class="datagrid-enum-checkboxes">
              <label for="report_category_first">
              <input type="checkbox" id="report_category_first"
                  value="first" name="report[category][]" />
              first
              </label>
              <label for="report_category_second">
              <input type="checkbox" id="report_category_second"
                  value="second" name="report[category][]" />
              second
              </label>
              </div>
            HTML
          )
        }

        it "disables label[for] attribute" do
          expect(view.datagrid_label(_filter)).to eq("<label>Category</label>")
        end

        context "when partials option passed and partial exists" do
          let(:view_options) { { partials: "custom_checkboxes" } }
          it { should equal_to_dom("custom_enum_checkboxes") }
        end

        context "when using deprecated elements variable in partial" do
          around do |ex|
            Datagrid::Utils.deprecator.silence do
              ex.run
            end
          end
          let(:view_options) { { partials: "deprecated_enum_checkboxes" } }
          it {
            should equal_to_dom(
              [["first", "first", false], ["second", "second", false]].to_json,
            )
          }
        end

        context "when inline class attribute specified" do
          let(:_filter_options) { { for: nil, class: "custom-class" } }

          it { should equal_to_dom(<<~HTML) }
            <div class="datagrid-enum-checkboxes">
              <label class="custom-class">
                <input id="report_category_first" value="first" type="checkbox" name="report[category][]">first
              </label>
              <label class="custom-class">
                <input id="report_category_second" value="second" type="checkbox" name="report[category][]">second
              </label>
            </div>
          HTML
        end
      end
    end

    context "with boolean filter type" do
      let(:_filter) { :disabled }
      let(:_grid) do
        test_grid_filter(:disabled, :boolean, default: true)
      end

      it {
        # hidden is important when default is set to true
        should equal_to_dom(<<~HTML)
          <input name="report[disabled]" type="hidden" value="0" autocomplete="off">
          <input type="checkbox" value="1" checked name="report[disabled]" id="report_disabled">
        HTML
      }
    end
    context "with xboolean filter type" do
      let(:_filter) { :disabled }
      let(:_grid) do
        test_grid_filter(:disabled, :xboolean)
      end
      it {
        should equal_to_dom(
          %(<select name="report[disabled]" id="report_disabled">
          <option value="" label=" "></option>
          <option value="YES">Yes</option>
          <option value="NO">No</option></select>),
        )
      }
    end
    context "with string filter" do
      let(:_grid) do
        test_grid_filter(:name, :string)
      end

      let(:_filter) { :name }

      it { should equal_to_dom('<input type="text" name="report[name]" id="report_name">') }

      context "when multiple option is set" do
        let(:_grid) do
          test_grid(name: "one,two") do
            scope { Entry }
            filter(:name, :string, multiple: true)
          end
        end

        let(:_filter) { :name }

        it {
          should equal_to_dom(
            '<input value="one,two" type="text" name="report[name]" id="report_name">',
          )
        }
      end
    end

    context "with non multiple filter" do
      let(:_grid) do
        test_grid_filter(
          :name, :enum,
          include_blank: false,
          multiple: false,
          select: [],
        )
      end
      let(:_filter) { :name }
      it { should equal_to_dom('<select name="report[name]" id="report_name"></select>') }
    end
    context "with float filter type" do
      let(:_grid) do
        test_grid_filter(:group_id, :float)
      end
      let(:_filter) { :group_id }
      it {
        should equal_to_dom(
          '<input type="number" step="any" name="report[group_id]" id="report_group_id"/>',
        )
      }
    end

    context "with enum multiple filter" do
      let(:_grid) do
        test_grid_filter(:group_id, :enum, select: ["hello"], multiple: true)
      end
      let(:_filter) { :group_id }
      let(:expected_html) do
        <<~HTML
          <select multiple name="report[group_id][]" id="report_group_id">
          <option value="hello">hello</option></select>
        HTML
      end

      it { should equal_to_dom(expected_html) }
    end

    context "with column names filter" do
      let(:_grid) do
        test_grid(column_names: %i[id name]) do
          scope { Entry }

          column_names_filter

          column(:id)
          column(:name)
          column(:category)
        end
      end
      let(:_filter) { :column_names }
      let(:expected_html) do
        <<~HTML
          <select multiple name="report[column_names][]" id="report_column_names"><option selected value="id">Id</option>
          <option selected value="name">Name</option>
          <option value="category">Category</option></select>
        HTML
      end

      it { should equal_to_dom(expected_html) }
    end
    context "with column_names_filter default given as symbols" do
      let(:_grid) do
        test_grid do
          scope { Entry }

          column_names_filter(default: %i[id name], checkboxes: true)

          column(:id)
          column(:name)
          column(:category)
        end
      end
      let(:_filter) { :column_names }
      let(:expected_html) do
        <<~DOM
          <div class="datagrid-enum-checkboxes">
            <label for="report_column_names_id">
              <input id="report_column_names_id" type="checkbox" value="id" checked name="report[column_names][]">
              Id
            </label>
            <label for="report_column_names_name">
              <input id="report_column_names_name" type="checkbox" value="name" checked name="report[column_names][]"/>
              Name
            </label>
            <label for="report_column_names_category">
              <input id="report_column_names_category" type="checkbox" value="category" name="report[column_names][]">
              Category
            </label>
          </div>
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
        test_grid_filter(:condition, :dynamic, **options)
      end
      let(:_filter) { :condition }
      context "with no options" do
        let(:expected_html) do
          <<-HTML
         <select class="datagrid-dynamic-field" name="report[condition][field]" id="report_condition"><option value="id">Id</option>
         <option value="group_id">Group</option>
         <option value="name">Name</option>
         <option value="category">Category</option>
         <option value="access_level">Access level</option>
         <option value="pet">Pet</option>
         <option value="disabled">Disabled</option>
         <option value="confirmed">Confirmed</option>
         <option value="shipping_date">Shipping date</option>
         <option value="created_at">Created at</option>
         <option value="updated_at">Updated at</option></select><select class="datagrid-dynamic-operation" name="report[condition][operation]" id="report_condition"><option value="=">=</option>
         <option value="=~">&asymp;</option>
         <option value="&gt;=">&ge;</option>
         <option value="&lt;=">&le;</option></select><input class="datagrid-dynamic-value"  name="report[condition][value]" type="text" id="report_condition">
          HTML
        end
        it { should equal_to_dom(expected_html) }
      end
      context "when default option passed" do
        let(:filter_options) do
          { select: %i[id name], default: [:id, ">=", 1] }
        end
        let(:expected_html) do
          <<-HTML
         <select class="datagrid-dynamic-field" name="report[condition][field]" id="report_condition">
           <option selected value="id">id</option>
           <option value="name">name</option>
         </select>
         <select class="datagrid-dynamic-operation" name="report[condition][operation]" id="report_condition">
           <option value="=">=</option>
           <option value="=~">≈</option>
           <option selected value="&gt;=">≥</option>
           <option value="&lt;=">≤</option></select>
         <input value="1" name="report[condition][value]" class="datagrid-dynamic-value" type="text" id="report_condition"/>
          HTML
        end

        it { should equal_to_dom(expected_html) }
      end

      context "when operations and options are defined" do
        let(:filter_options) do
          { operations: %w[>= <=], select: %i[id name] }
        end
        let(:expected_html) do
          <<-HTML
          <select class="datagrid-dynamic-field" name="report[condition][field]" id="report_condition"><option value="id">id</option><option value="name">name</option></select><select class="datagrid-dynamic-operation" name="report[condition][operation]" id="report_condition"><option value="&gt;=">≥</option>
       <option value="&lt;=">≤</option></select><input class="datagrid-dynamic-value" name="report[condition][value]" type="text" id="report_condition">
          HTML
        end
        it { should equal_to_dom(expected_html) }
      end

      context "when the field is predefined" do
        let(:filter_options) do
          { operations: %w[>= <=], select: [:id] }
        end
        let(:expected_html) do
          <<-HTML
          <input class="datagrid-dynamic-field" name="report[condition][field]" value="id" autocomplete="off" type="hidden" id="report_condition"><select class="datagrid-dynamic-operation" name="report[condition][operation]" id="report_condition"><option value="&gt;=">≥</option>
       <option value="&lt;=">≤</option></select><input class="datagrid-dynamic-value" name="report[condition][value]" type="text" id="report_condition">
          HTML
        end
        it { should equal_to_dom(expected_html) }
      end
      context "when operation is predefined" do
        let(:filter_options) do
          { operations: %w[=], select: %i[id name] }
        end
        let(:expected_html) do
          <<-HTML
          <select class="datagrid-dynamic-field" name="report[condition][field]" id="report_condition"><option value="id">id</option><option value="name">name</option></select><input class="datagrid-dynamic-operation" name="report[condition][operation]" value="=" autocomplete="off" type="hidden" id="report_condition"><input class="datagrid-dynamic-value" name="report[condition][value]" type="text" id="report_condition">
          HTML
        end
        it { should equal_to_dom(expected_html) }
      end
    end
  end

  describe ".datagrid_label" do
    let(:_grid) do
      test_grid do
        scope { Entry }
        filter(:name, :string)
        filter(:created_at, :date, label_options: { class: "js-date-selector" })
      end
    end

    it "should generate label for filter" do
      expect(view.datagrid_label(:created_at)).to equal_to_dom(<<~HTML)
        <label class="js-date-selector" for="report_created_at">Created at</label>
      HTML
    end

    it "should generate label for filter" do
      expect(view.datagrid_label(:name)).to equal_to_dom(<<~HTML)
        <label for="report_name">Name</label>
      HTML
    end
    it "should pass options through to the helper" do
      expect(view.datagrid_label(:name, class: "foo")).to equal_to_dom(
        '<label class="foo" for="report_name">Name</label>',
      )
    end
    it "should support block" do
      expect(view.datagrid_label(:name, class: "foo") { "The Name" }).to equal_to_dom(
        '<label class="foo" for="report_name">The Name</label>',
      )
    end
    it "should support explicit label" do
      expect(view.datagrid_label(:name, "The Name")).to equal_to_dom(
        '<label for="report_name">The Name</label>',
      )
    end
  end
end
