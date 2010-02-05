
# Copied from Innate. Thanks manveru ^_^

require 'digest/md5'

module Utopia

	class Etanni
		SEPARATOR = Digest::MD5.hexdigest(Time.new.to_s)
		START = "\n_out_ << <<#{SEPARATOR}.chomp!\n"
		STOP = "\n#{SEPARATOR}\n"
		REPLACEMENT = "#{STOP}\\1#{START}"

		def initialize(template)
			@template = template
			compile!
		end

		def compile!
			temp = @template.dup
			temp.strip!
			temp.gsub!(/<\?r\s+(.*?)\s+\?>/m, REPLACEMENT)
			@compiled = "_out_ = [<<#{SEPARATOR}.chomp!]\n#{temp}#{STOP}_out_"
		end

		def result(binding, filename = '<Etanni>')
			eval(@compiled, binding, filename).join
		end
	end
end