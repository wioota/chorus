#!/usr/bin/env ruby

LOOK_FOR_OTHERS = true

ERROR_TYPES = [
	/Missing semicolon/,
	/Use '===' to compare/,
	/Missing radix parameter/,
	/Expected an assignment or function call and instead saw an expression/,
	/Expected a conditional expression and instead saw an assignment/,
	/is better written in dot notation/,
	/is already defined/,
	/Duplicate member/,
	/Missing .* invoking a constructor/,
	/Expected an identifier and instead saw/,
	/Expected an operator and instead saw/,
	/Possible strict violation/,
	/Don't make functions within a loop/,
	/Confusing use of '!'/,
	/Don't use extra leading zeros/,
	/Unescaped /,
	/Wrap the \/regexp\/ literal in parens to disambiguate the slash operator/,
	/Expected '===' and instead saw '=='/,
	/Too many errors/,
	/Too many var statements/,
	/Extra comma/,
	/Unexpected use of '..'/,
	/Expected '!==' and instead saw '!='/,
	/Unnecessary semicolon/,
	/Unreachable 'break' after 'return'/,
	/Bad line breaking before '&&'/,
	/Bad escapement of EOL/,
	/Bad line breaking before/,
	/Value of 'err' may be overwritten in IE/,
	/Use '!==' to compare with/,
	/A leading decimal point can be confused with a dot/,
	/used out of scope/,
	/Bad assignment/,
	/Did you mean to return a conditional instead of an assignment/,
	/Unexpected dangling/,
	/Use the function form of "use strict"/,
	/Expected a number and instead saw/,
	/Input is an empty string/,
  /Missing space after '(.+)'/,
  /Unexpected space before/,
  /Trailing whitespace/,
  /Line too long/,
  /to have an indentation at/,
  /Bad escapement/,
  /eval is evil/,
  /Unexpected space after/,
  /and instead saw/,
  /Bad for in variable/,
  /Missing name in function declaration/,
  /Do not use 'new' for side effects/,
  /Empty block/,
  /A constructor name should start with an uppercase letter/,
  /The body of a for in should be wrapped in an if statement to filter unwanted properties from the prototype/,
  /Redefinition of/,
  /Line breaking error/,
  /Label '\w+' on \S+ statement/,
  /'(.+)' is not defined/
]

class Error
  attr_reader :error_type
  attr_reader :specifics

  def initialize(error_type)
    @error_type = error_type
    @specifics = Hash.new { 0 }
  end

  def add_specific(specific)
    @specifics[specific || '__general__'] += 1
  end

  def count
    specifics.values.inject(:+)
  end

  def print_out
    puts "#{error_type}: #{count}"
    specifics.reject {|key| key == "__general__"}.each do |name, count|
      puts "  #{name}: #{count}"
    end
  end
end

def get_results(input)
	results = Hash.new { |hash, new_key| hash[new_key] = Error.new(new_key) }
	input.each do |line|
		known_error = false
    print '.'
		ERROR_TYPES.each do |error|
			if line.match(error)
				results[error.source].add_specific $1
				known_error = true
			end
		end

		unless known_error || !LOOK_FOR_OTHERS
			puts line
			results["Other"] += 1
		end
	end

	results
end

puts "Gathering error information..."
code_output = `rake jshint 2> /dev/null | grep Lint`.split("\n")
CODE_RESULTS = get_results(code_output)

spec_output = `rake jshint:specs 2> /dev/null | grep Lint`.split("\n")
SPEC_RESULTS = get_results(spec_output)

def output_result(title, results)
	puts title
	puts "=" * title.length
	puts

	results.values.each(&:print_out)

	puts
	error_count = results.values.map(&:count).inject(:+)
	puts "#{title} Error Count: #{error_count}"
	puts
end

puts ""
output_result("Application Code", CODE_RESULTS)
output_result("Spec Code", SPEC_RESULTS)
