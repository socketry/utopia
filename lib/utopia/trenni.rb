#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'strscan'

module Utopia
	class Trenni
		# The output variable that will be used in templates:
		OUT = '_out'
		
		# Returns the output produced by calling the given block.
		def self.capture(*args, &block)
			out = eval(OUT, block.binding)
			top = out.size
			
			block.call *args
			
			return out.pop(out.size - top).join
		end
		
		# Returns the buffer used for capturing output.
		def self.buffer(binding)
			eval(OUT, binding)
		end
		
		class Buffer
			def initialize
				@parts = []
			end

			attr :parts

			def text(text)
				text = text.gsub('\\', '\\\\\\').gsub('@', '\\@')

				@parts << "#{OUT} << %q@#{text}@ ; "
			end

			def expression(text)
				@parts << "#{text} ; "
			end

			def output(text)
				@parts << "#{OUT} << (#{text}) ; "
			end

			def code
				parts = ["#{OUT} = [] ; "] + @parts + ["#{OUT}.join"]

				code = parts.join
			end
		end

		class Scanner < StringScanner
			TEXT = /([^<#]|<(?!\?r)|#(?!\{)){1,1024}/m
			
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
				if scan(TEXT)
					@callback.text(matched)
				end
			end

			def scan_expression
				if scan(/\#\{/)
					level = 1
					code = ""

					until eos? || level == 0
						if scan(/[^"'\{\}]+/m)
							code << matched
						end

						if scan(/"(\\"|[^"])*"/m)
							code << matched
						end

						if scan(/'(\\'|[^'])*'/m)
							code << matched
						end

						if scan(/\{/)
							code << matched
							level += 1
						end

						if scan(/\}/)
							code << matched if level > 1
							level -= 1
						end
					end

					if level == 0
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