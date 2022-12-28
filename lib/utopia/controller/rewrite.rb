# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

require_relative '../http'
require_relative '../path/matcher'

module Utopia
	class Controller
		# This controller layer rewrites the path before executing controller actions. When the rule matches, the supplied block is executed.
		# @example
		# 	prepend Rewrite
		# 	rewrite.extract_prefix id: Integer do
		# 		@user = User.find(@id)
		# 	end
		module Rewrite
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			# A abstract rule which can match against a request path.
			class Rule
				def apply_match_to_context(match_data, context)
					match_data.names.each do |name|
						context.instance_variable_set("@#{name}", match_data[name])
					end
				end
			end
			
			# A rule which extracts a prefix pattern from the request path.
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
			
			# Rewrite a request path based on a set of defined rules.
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
			
			# Exposed to the controller class.
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
