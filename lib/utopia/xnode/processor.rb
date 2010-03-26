# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'utopia/tag'

module Utopia
	module XNode
		OPENED_TAG = 0
		CLOSED_TAG = 1

		class UnbalancedTagError < StandardError
			def initialize(scanner, start_pos, current_tag, closing_tag)
				@scanner = scanner
				@start_pos = start_pos
				@current_tag = current_tag
				@closing_tag = closing_tag
				
				@starting_line = @scanner.calculate_line_number(@start_pos)
				@ending_line = @scanner.calculate_line_number
			end
			
			def to_s
				"UnbalancedTagError: Tag #{@current_tag} (line #{@starting_line[0]}: #{@starting_line[4]}) has been closed by #{@closing_tag} (line #{@ending_line[0]}: #{@ending_line[4]})."
			end
		end

		class Processor
			def initialize(content, delegate, options = {})
				@delegate = delegate
				@stack = []

				@scanner = (options[:scanner] || Scanner).new(self, content)
			end

			def parse
				@scanner.parse
			end
		
			def cdata(text)
				# $stderr.puts "\tcdata: #{text}"
				@delegate.cdata(text)
			end
		
			def comment(text)
				cdata("<!#{text}>")
			end

			def begin_tag(tag_name, begin_tag_type)
				# $stderr.puts "begin_tag: #{tag_name}, #{begin_tag_type}"
				if begin_tag_type == OPENED_TAG
					@stack << [Tag.new(tag_name, {}), @scanner.pos]
				else
					cur, pos = @stack.pop
				
					if (tag_name != cur.name)
						raise UnbalancedTagError.new(@scanner, pos, cur.name, tag_name)
					end
				
					@delegate.tag_end(cur)
				end
			end

			def finish_tag(begin_tag_type, end_tag_type)
				# $stderr.puts "finish_tag: #{begin_tag_type} #{end_tag_type}"
				if begin_tag_type == OPENED_TAG # <...
					if end_tag_type == CLOSED_TAG # <.../>
						cur, pos = @stack.pop
						cur.closed = true
				
						@delegate.tag_complete(cur)
					elsif end_tag_type == OPENED_TAG # <...>
						cur, pos = @stack.last

						@delegate.tag_begin(cur)
					end
				end
			end

			def attribute(name, value)
				# $stderr.puts "\tattribute: #{name} = #{value}"
				@stack.last[0].attributes[name] = value
			end

			def instruction(content)
				cdata("<?#{content}?>")
			end
		end
	end
end
