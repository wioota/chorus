# encoding: UTF-8

module Capybara
  module Helpers
    class << self
      ##
      #
      # Normalizes whitespace space by stripping leading and trailing
      # whitespace and replacing sequences of whitespace characters
      # with a single space.
      #
      # @param [String] text     Text to normalize
      # @return [String]         Normalized text
      #
      def normalize_whitespace(text)
        # http://en.wikipedia.org/wiki/Whitespace_character#Unicode
        # We should have a better reference.
        # See also http://stackoverflow.com/a/11758133/525872
        text.to_s.gsub(/[\s\u0085\u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+/, ' ').strip
      end
    end
  end
end

module CapybaraHelpers
  def current_route
    URI.parse(current_url).fragment
  end

  def wait_until(timeout = 30)
    Timeout.timeout(timeout) do
      loop do
        begin
          yield
          break
        rescue Timeout::Error
          message = last_error.message if last_error
          raise "CapybaraHelper timeout: Last Error was '#{message}'"
        rescue => e
          raise e unless e.class.name =~ /Capybara/
          last_error = e
          sleep 0.1
        end
      end
    end
  end

  def attach_file(locator, path)
    element = find(:file_field, locator)
    id = element['id']
    jquery_locator = id.present? ? "#" + id : "input[name=\"#{locator}\"]"
    # workaround to allow selenium to click the element
    page.execute_script("$('#{jquery_locator}').removeClass('file-input');")
    element.set(path)
  end

  def click_link(locator)
    page.click_link(locator)
  rescue Capybara::Ambiguous
    first(:xpath, ".//a[descendant-or-self::node()='#{locator}']").click
  rescue Capybara::Ambiguous
    find(locator).click
  end

  def wait_for_ajax(timeout = 30)
    wait_until(timeout) do
      sleep 0.2
      page.evaluate_script 'jQuery.active == 0'
    end
  end
end