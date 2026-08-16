# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require_relative "../http"
require_relative "../path/matcher"

module Utopia
	module Controller
		# This controller layer rewrites the path before executing controller actions. When the rule matches, the supplied block is executed.
		# @example
		# 	prepend Rewrite
		# 	rewrite.extract_prefix id: Integer do
		# 		@user = User.find(@id)
		# 	end
		module Rewrite
			# Extend a controller class with path-rewrite rules.
			# @parameter base [Class] The controller class.
			# @returns [Class] The extended controller class.
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			# A abstract rule which can match against a request path.
			class Rule
				# Copy named regular-expression captures into context instance variables.
				# @parameter match_data [MatchData] The regular expression match.
				# @parameter context [Object] The context.
				# @returns [Array(String)] The capture names.
				def apply_match_to_context(match_data, context)
					match_data.names.each do |name|
						context.instance_variable_set("@#{name}", match_data[name])
					end
				end
			end
			
			# A rule which extracts a prefix pattern from the request path.
			class ExtractPrefixRule < Rule
				# Initialize a typed prefix-extraction rule.
				# @parameter patterns [Hash] The path rewrite patterns.
				# @parameter block [Proc] The block.
				def initialize(patterns, block)
					@matcher = Path::Matcher.new(patterns)
					@block = block
				end
				
				# Freeze this object and its internal state.
				# @returns [self] This object.
				def freeze
					return self if frozen?
					
					@matcher.freeze
					@block.freeze
					
					super
				end
				
				# Apply this prefix rule and execute its callback when it matches.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Path] The unmatched suffix, or the original path when the rule does not match.
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
				# Initialize an empty rewrite rule sequence.
				def initialize
					@rules = []
				end
				
				attr :rules
				
				# Add a rule that extracts a typed prefix from the request path.
				# @parameter patterns [Hash] The path rewrite patterns.
				# @yields {|request, path, match| ...} The request, original path, and match data when the rule matches.
				# @returns [ExtractPrefixRule] The added rule.
				def extract_prefix(**patterns, &block)
					@rules << ExtractPrefixRule.new(patterns, block)
				end
				
				# Apply every rewrite rule in order.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Path] The rewritten path.
				def apply(context, request, path)
					@rules.each do |rule|
						path = rule.apply(context, request, path)
					end
					
					return path
				end
				
				# Rewrite a path's components in place.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Array(String)] The rewritten components.
				def call(context, request, path)
					path.components = apply(context, request, path).components
				end
			end
			
			# Exposed to the controller class.
			module ClassMethods
				# Return this controller's path rewriter.
				# @returns [Rewriter] The path rewriter.
				def rewrite
					@rewriter ||= Rewriter.new
				end
				
				# Apply configured rewrite rules to the request path.
				# @parameter controller [Utopia::Controller::Base] The controller instance.
				# @parameter request [Utopia::Request] The request.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Array(String) | Nil] The rewritten components, or `nil` when no rewriter is configured.
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
