#!/usr/bin/env ruby

LOOK_FOR_OTHERS = false

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
	/Input is an empty string/
]

sub_dirs = ["collections", "views", "models", "presenters", "mixins", "dialogs", "alerts", "views", "pages", "utilities"]
directories = sub_dirs.map { |sub| "app/assets/javascripts/#{sub}" }

code_output = `jshint #{directories.join(" ")}`.split("\n")
spec_output = `jshint spec/javascripts`.split("\n")

def get_results(input)
	results = Hash.new { 0 }
	input.each do |line|
		flag = false
		ERROR_TYPES.each do |error|
			if line.match(error)
				results[error.source] += 1
				flag = true
			end
		end

		unless flag || !LOOK_FOR_OTHERS
			puts line
			results["Other"] += 1
		end
	end

	results
end

CODE_RESULTS = get_results(code_output)
SPEC_RESULTS = get_results(spec_output)

def output_result(title, results)
	puts title
	puts "=" * title.length
	puts

	results.each do |error_type, error_count|
		puts "#{error_type}: #{error_count}"
	end

	puts
	error_count = results.values.inject(:+)
	puts "#{title} Warning Count: #{error_count}"
	puts
end

output_result("Application Code", CODE_RESULTS)
output_result("Spec Code", SPEC_RESULTS)
