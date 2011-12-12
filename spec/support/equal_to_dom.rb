require "nokogiri"

def equal_to_dom(text)
  EqualToDom.new(text)
end


def include_dom(text)
  IncludeDom.new(text)
end

class IncludeDom
  def initialize(expectation)
    @expectation = Nokogiri::HTML::DocumentFragment.parse(expectation.strip).to_s
  end

  def matches?(text)
    @matcher = Nokogiri::HTML::DocumentFragment.parse(text.strip).to_s
    @matcher == @expectation
  end

  def failure_message
    "Expected dom \n#{@matcher.inspect}\n to include \n#{@expectation.inspect}\n, but it wasn't"
  end
end


class EqualToDom

  def initialize(expectation)
    @expectation = Nokogiri::HTML::DocumentFragment.parse(expectation.strip).to_s
  end

  def matches?(text)
    @matcher = Nokogiri::HTML::DocumentFragment.parse(text.strip).to_s
    @matcher == @expectation
  end

  def failure_message
    "Expected dom #{@matcher} to match #{@expectation}, but it wasn't"
  end
end
