require "nokogiri"

def equal_to_dom(text)
  EqualToDom.new(text)
end



class EqualToDom

  def initialize(expectation)
    @expectation = Nokogiri::HTML::DocumentFragment.parse(expectation).to_s
  end

  def matches?(text)
    @matcher = Nokogiri::HTML::DocumentFragment.parse(text).to_s
    @matcher == @expectation
  end

  def failure_message
    "Expected dom #{@matcher} to match #{@expectation}, but it wasn't"
  end
end
