require "nokogiri"

def equal_to_dom(text)
  EqualToDom.new(text)
end


def include_dom(text)
  IncludeDom.new(text)
end

def match_css_pattern(pattern)
  CssPattern.new(pattern)
end


class IncludeDom
  def initialize(expectation)
    @expectation = Nokogiri::HTML::DocumentFragment.parse(expectation).to_s
  end

  def matches?(text)
    @matcher = Nokogiri::HTML::DocumentFragment.parse(text).to_s
    @matcher == @expectation
  end

  def failure_message
    "Expected dom \n#{@matcher.inspect}\n to include \n#{@expectation.inspect}\n, but it wasn't"
  end
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


class CssPattern
  def initialize(pattern)
    @css_pattern = pattern
  end

  def error!(message)
    @error_message = message
    false
  end

  def failure_message
    @error_message || ""
  end

  def matches?(text)
    @matcher = Nokogiri::HTML::DocumentFragment.parse(text)
    @css_pattern.each do |css, amount_or_pattern_or_string_or_proc|
      path = @matcher.css(css)
      if amount_or_pattern_or_string_or_proc.is_a?(String) or amount_or_pattern_or_string_or_proc.is_a?(Regexp)
        pattern_or_string = amount_or_pattern_or_string_or_proc 
        html = path.inner_html
        if !html.match(pattern_or_string)
          return error!("#{css.inspect} did not match #{pattern_or_string.inspect}. It was \n:#{html.inspect}")
        end
      elsif amount_or_pattern_or_string_or_proc.is_a? Fixnum
        expected_amount = amount_or_pattern_or_string_or_proc
        amount = path.size
        if amount != expected_amount
          return error!("did not find #{css.inspect} #{expected_amount.inspect} times. It was #{amount.inspect}")
        end
      elsif amount_or_pattern_or_string_or_proc.is_a? Proc
        if !amount_or_pattern_or_string_or_proc.call(path)
          return error!("#{css.inspect} did not validate (proc must not return a falsy value)")
        end
      else
        raise "Instance of String, Rexexp, Proc or Fixnum required"
      end
      true
    end 
  end

end
