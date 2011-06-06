shared_examples_for "Datagrid" do
  describe "as Datagrid" do

    it "should have at least one entry if assets" do
      subject.assets.should_not be_empty
    end

    its(:data) {should_not be_empty}

    described_class.columns.each do |column|
      describe "column ##{column.name}" do

        it "should has value in #data_hash" do
          subject.data_hash.first.should have_key(column.name)
        end

        it "should support order" do
          subject.order = column.order
          subject.assets.first.should_not be_nil
        end
      end

    end

    described_class.filters.each do |filter|
      describe "filter ##{filter.attribute}" do

        let(:filter_value) do
          
          case Datagrid::Filters::FILTER_TYPES.invert[filter.class]
          when :default, :string
            "text"
          when :date
            1.day.ago
          when :eboolean
            Datagrid::Filters::BooleanEnumFilter::YES
          when :boolean
            true
          when :integer
            1
          when :enum
            select = filter.select
            select = select.call(subject)  if select.respond_to?(:call)
            select.first.try(:last)
          else
            raise "unknown filter type: #{filter.class}"
          end.to_s
        end

        before(:each) do
          subject.attributes = {filter.attribute => filter_value}
          subject.send(filter.attribute).should_not be_nil
        end

        it "should be supported" do
          subject.assets.should respond_to(:all)
        end
      end
    end

  end
end
