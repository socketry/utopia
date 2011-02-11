#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'strscan'

module Utopia
	class Trenni
		class Buffer
			def initialize
				@parts = []
			end

			attr :parts

			def text(text)
				text = text.gsub('\\', '\\\\\\').gsub('@', '\\@')

				@parts << "_out << %q@#{text}@ ; "
			end

			def expression(text)
				@parts << "#{text} ; "
			end

			def output(text)
				@parts << "_out << #{text} ; "
			end

			def code
				parts = ['_out = [] ; '] + @parts + ['_out.join']

				code = parts.join
			end
		end

		class Scanner < StringScanner
			def initialize(callback, string)
				@callback = callback
				super(string)
			end

			def parse
				until eos?
					pos = self.pos

					scan_text
					scan_expression

					if pos == self.pos
						raise StandardError.new "Could not scan current input #{self.pos} #{eos?}!"
					end
				end
			end

			def scan_text
				if scan_until(/(.*?)(?=\#\{|<\?r)/m) || scan(/(.*)\Z/m)
					@callback.text(self[1]) if self[1].size > 0
				end
			end

			def scan_expression
				if scan(/\#\{/)
					done = false
					code = ""

					until eos? || done
						if scan(/[^"'\{\}]+/m)
							code << matched
						end

						if scan(/"(\\"|[^"])*"/m)
							code << matched
						end

						if scan(/'(\\'|[^'])*'/m)
							code << matched
						end

						if scan(/\{[^\}]*\}/m)
							code << matched
						end

						if scan(/\}/)
							done = true
						end
					end

					if done
						@callback.output(code)
					else
						raise StandardError.new "Could not find end of expression #{self}!"
					end
				elsif scan(/<\?r/)
					if scan_until(/(.*?)\?>/m)
						@callback.expression(self[1])
					else
						raise StandardError.new "Could not find end of expression #{self}!"
					end
				end
			end
		end

		def self.load(path)
			return self.new(File.read(path), path)
		end

		def initialize(template, filename = '<Trenni>')
			@template = template
			@filename = filename
			compile!
		end

		def compile!(filename = @filename)
			buffer = Buffer.new
			scanner = Scanner.new(buffer, @template)

			scanner.parse
			
			@code = buffer.code
		end

		def result(binding)
			eval(@code, binding, @filename)
		end
	end
end