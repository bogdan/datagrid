require "nokogiri"

def have_dom(text)
  HaveDom.new(text)
end



class HaveDom

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
