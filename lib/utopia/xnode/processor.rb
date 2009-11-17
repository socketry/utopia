
module Utopia
	module XNode
		OPENED_TAG = 0
		CLOSED_TAG = 1

		class Processor
			Tag = Struct.new(:name, :attributes)

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
				@delegate.text(text)
			end
		
			def comment(text)
				cdata("<!#{text}>")
			end

			def begin_tag(tag_name, begin_tag_type)
				# $stderr.puts "begin_tag: #{tag_name}, #{begin_tag_type}"
				if begin_tag_type == OPENED_TAG
					@stack << Tag.new(tag_name, {})
				else
					cur = @stack.pop
				
					if (tag_name != cur.name)
						raise XNode::ScanError.new("Unbalanced tag #{tag_name}")
					end
				
					@delegate.tag_end(cur.name)
				end
			end

			def finish_tag(begin_tag_type, end_tag_type)
				# $stderr.puts "finish_tag: #{begin_tag_type} #{end_tag_type}"
				if begin_tag_type == OPENED_TAG # <...
					if end_tag_type == CLOSED_TAG # <.../>
						cur = @stack.pop
				
						@delegate.tag(cur.name, cur.attributes)
					elsif end_tag_type == OPENED_TAG # <...>
						cur = @stack.last

						@delegate.tag_start(cur.name, cur.attributes)
					end
				end
			end

			def attribute(name, value)
				# $stderr.puts "\tattribute: #{name} = #{value}"
				@stack.last.attributes[name] = value
			end
		end
	end
end
