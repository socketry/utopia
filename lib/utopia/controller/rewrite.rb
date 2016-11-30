# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../http'
require_relative '../path/matcher'

module Utopia
	class Controller
		# This controller layer rewrites the path before executing controller actions. When the rule matches, the supplied block is executed.
		# @example
		# prepend Rewrite
		# rewrite.extract_prefix id: Integer do
		#   @user = User.find(@id)
		# end
		module Rewrite
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			class Rule
				def apply_match_to_context(match_data, context)
					match_data.names.each do |name|
						context.instance_variable_set("@#{name}", match_data[name])
					end
				end
			end
			
			class ExtractPrefixRule < Rule
				def initialize(patterns, block)
					@matcher = Path::Matcher.new(patterns)
					@block = block
				end
				
				def freeze
					@matcher.freeze
					@block.freeze
					
					super
				end
				
				def apply(context, request, path)
					if match_data = @matcher.match(path)
						apply_match_to_context(match_data, context)
						
						if @block
							context.instance_exec(request, path, match_data, &@block)
						end
						
						return match_data.post_match
					else
						return path
					end
				end
			end
			
			class Rewriter
				def initialize
					@rules = []
				end
				
				attr :rules
				
				def extract_prefix(**patterns, &block)
					@rules << ExtractPrefixRule.new(patterns, block)
				end
				
				def apply(context, request, path)
					@rules.each do |rule|
						path = rule.apply(context, request, path)
					end
					
					return path
				end
				
				def call(context, request, path)
					path.components = apply(context, request, path).components
				end
			end
			
			module ClassMethods
				def rewrite
					@rewriter ||= Rewriter.new
				end
				
				def rewrite_request(controller, request, path)
					if @rewriter
						@rewriter.call(controller, request, path)
					end
				end
			end
			
			# Rewrite the path before processing the request if possible.
			def process!(request, path)
				catch_response do
					self.class.rewrite_request(self, request, path)
				end || super
			end
		end
	end
end
