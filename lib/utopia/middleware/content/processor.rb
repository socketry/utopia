#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tag'
require 'trenni/parser'
require 'trenni/strings'

module Utopia
	module Middleware
		class Content
			class Processor
				def self.parse_xml(xml_data, delegate)
					processor = self.new(delegate)
					
					processor.parse(xml_data)
				end

				class UnbalancedTagError < StandardError
					def initialize(scanner, start_position, current_tag, closing_tag)
						@scanner = scanner
						@start_position = start_position
						@current_tag = current_tag
						@closing_tag = closing_tag
				
						@starting_line = @scanner.calculate_line_number(@start_pos)
						@ending_line = @scanner.calculate_line_number
					end

					def to_s
						"Unbalanced Tag #{@current_tag}. " \
						"Line #{@starting_line[0]}: #{@starting_line[4]} has been closed by #{@closing_tag} on line #{@ending_line[0]}: #{@ending_line[4]}"
					end
				end

				def initialize(delegate)
					@delegate = delegate
					@stack = []

					@parser = Trenni::Parser.new(self)
				end

				def parse(input)
					@parser.parse(input)
				end

				def begin_parse(scanner)
					@scanner = scanner
				end

				def text(text)
					@delegate.cdata(text)
				end

				def cdata(text)
					@delegate.cdata(Trenni::Strings::to_html(text))
				end

				def comment(text)
					@delegate.cdata("<!#{text}>")
				end

				def begin_tag(tag_name, begin_tag_type)
					if begin_tag_type == :opened
						@stack << [Tag.new(tag_name, {}), @scanner.pos]
					else
						current_tag, current_position = @stack.pop
				
						if (tag_name != current_tag.name)
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
end
