# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'trenni/parser'
require 'trenni/strings'

require_relative 'tag'

module Utopia
	class Content
		class Processor
			def self.parse_markup(markup, delegate)
				processor = self.new(delegate)
				
				processor.parse(markup)
			end

			class UnbalancedTagError < StandardError
				def initialize(scanner, start_position, current_tag, closing_tag)
					@scanner = scanner
					@start_position = start_position
					@current_tag = current_tag
					@closing_tag = closing_tag
					
					@starting_line = Trenni::Parser::Location.new(@scanner.string, @start_position)
					@ending_line = Trenni::Parser::Location.new(@scanner.string, @scanner.pos)
				end

				attr :scanner
				attr :start_position
				attr :current_tag
				attr :closing_tag

				def to_s
					"Unbalanced Tag Error. Line #{@starting_line}: #{@current_tag} has been closed by #{@closing_tag} on line #{@ending_line}!"
				end
			end

			def initialize(delegate)
				@delegate = delegate
				@stack = []

				@parser = Trenni::Parser.new(self)
			end

			def parse(input)
				@parser.parse(input)
				
				unless @stack.empty?
					current_tag, current_position = @stack.pop
					
					raise UnbalancedTagError.new(@scanner, current_position, current_tag.name, 'EOF')
				end
			end

			def begin_parse(scanner)
				@scanner = scanner
			end

			def text(text)
				@delegate.cdata(text)
			end

			def cdata(text)
				@delegate.cdata("<![CDATA[#{text}]]>")
			end

			def comment(text)
				@delegate.cdata("<!#{text}>")
			end

			def begin_tag(tag_name, begin_tag_type)
				if begin_tag_type == :opened
					@stack << [Tag.new(tag_name, {}), @scanner.pos]
				else
					current_tag, current_position = @stack.pop
			
					if tag_name != current_tag.name
						raise UnbalancedTagError.new(@scanner, current_position, current_tag.name, tag_name)
					end
			
					@delegate.tag_end(current_tag)
				end
			end

			def finish_tag(begin_tag_type, end_tag_type)
				if begin_tag_type == :opened # <...
					if end_tag_type == :closed # <.../>
						cur, pos = @stack.pop
						cur.closed = true

						@delegate.tag_complete(cur)
					elsif end_tag_type == :opened # <...>
						cur, pos = @stack.last

						@delegate.tag_begin(cur)
					end
				end
			end

			def attribute(name, value)
				@stack.last[0].attributes[name] = value
			end

			def instruction(content)
				cdata("<?#{content}?>")
			end
		end
	end
end
