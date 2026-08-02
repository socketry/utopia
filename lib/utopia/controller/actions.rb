# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.

require_relative "../http"

module Utopia
	module Controller
		# A controller layer which invokes functinality based on the request path.
		# @example
		# 	on '*' do |request, path|
		# 		succeed! content: 'Hello World'
		# 	end
		module Actions
			# Extend a controller class with the action-definition DSL.
			# @parameter base [Class] The controller class.
			# @returns [Class] The extended controller class.
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			# A nested action lookup hash table.
			class Action < Hash
				# Initialize an action lookup node.
				# @parameter options [Hash] Metadata associated with this action.
				# @yields The action body when this node matches.
				def initialize(options = {}, &block)
					@options = options
					@callback = block
					
					super()
				end
				
				attr_accessor :callback, :options
				
				# Check whether this action has a callback.
				# @returns [Boolean] Whether this action has a callback.
				def callback?
					@callback != nil
				end
				
				# Check whether this object is equivalent to another object.
				# @parameter other [Object] The object to compare.
				# @returns [Boolean] Whether the action mappings, callback, and options are equal.
				def eql? other
					super and @callback.eql? other.callback and @options.eql? other.options
				end
				
				# Compute the hash value for this object.
				# @returns [Integer] The resulting integer.
				def hash
					[super, @callback, @options].hash
				end
				
				# Compare this object with another object.
				# @parameter other [Object] The object to compare.
				# @returns [Boolean] Whether the action mappings, callback, and options are equal.
				def == other
					super and @callback == other.callback and @options == other.options
				end
				
				# Matches 0 or more path components.
				WILDCARD_GREEDY = "**".freeze
				
				# Matches any 1 path component.
				WILDCARD = "*".freeze
				
				# Yield all actions matching a path, from most specific to most general.
				# @parameter path [Array(String)] The path components.
				# @parameter index [Integer] The component index currently being matched.
				# @yields {|action| ...} Each matching action.
				# @returns [Boolean | Nil] `true` if any action matched, otherwise `nil`.
				def apply(path, index = -1, &block)
					# ** is greedy, it always matches if possible and matches all remaining input.
					if match_all = self[WILDCARD_GREEDY] and match_all.callback?
						# It's possible in this callback that path is modified.
						matched = true; yield(match_all)
					end
					
					if name = path[index]
						# puts "Matching #{name} in #{self.keys.inspect}"
						
						if match_name = self[name]
							# puts "Matched against exact name #{name}: #{match_name}"
							matched = match_name.apply(path, index-1, &block) || matched
						end
						
						if match_one = self[WILDCARD]
							# puts "Match against #{WILDCARD}: #{match_one}"
							matched = match_one.apply(path, index-1, &block) || matched
						end
					elsif self.callback?
						# Got to end, matched completely:
						matched = true; yield(self)
					end
					
					return matched
				end
				
				# Collect the actions matching the given path.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Array(Action)] The matching actions.
				def matching(path, &block)
					to_enum(:apply, path).to_a
				end
				
				# Define an action at the given path.
				# @parameter path [Array(String)] The path components in reverse matching order.
				# @parameter options [Hash] Metadata associated with the action.
				# @yields The action body.
				# @returns [Action] The defined action.
				def define(path, **options, &callback)
					# puts "Defining path: #{path.inspect}"
					current = self
					
					path.reverse_each do |name|
						current = (current[name] ||= Action.new)
					end
					
					current.options = options
					current.callback = callback
					
					return current
				end
				
				# Generate a debug representation of this object.
				# @returns [String] The resulting string.
				def inspect
					if callback?
						"<action " + super + ":#{callback.source_location}(#{options})>"
					else
						"<action " + super + ">"
					end
				end
			end
			
			# Exposed to the controller class.
			module ClassMethods
				# Initialize class-level state when this module is extended.
				# @parameter klass [Class] The class to configure.
				# @returns [Class] The configured controller class.
				def self.extended(klass)
					klass.instance_eval do
						@actions = nil
						@otherwise = nil
					end
				end
				
				# Return the root of the action lookup tree.
				# @returns [Action] The root action.
				def actions
					@actions ||= Action.new
				end
				
				# Define an action for the given request path.
				# @parameter first [Path | String | Symbol | Array] The first path pattern or named suffix.
				# @parameter path [Array(String)] Additional path components.
				# @parameter options [Hash] Metadata associated with the action.
				# @yields The action body.
				# @returns [Action] The defined action.
				def on(first, *path, **options, &block)
					if first.is_a? Symbol
						first = ["**", first.to_s]
					end
					
					actions.define(Path.split(first) + path, **options, &block)
				end
				
				# Define the fallback action.
				# @yields The fallback action body.
				# @returns [Proc] The fallback action body.
				def otherwise(&block)
					@otherwise = block
				end
				
				# Dispatch the request to the first matching action.
				# @parameter controller [Utopia::Controller::Base] The controller instance.
				# @parameter request [Utopia::Request] The request.
				# @parameter path [Utopia::Path | String] The path.
				# @returns [Object | Nil] The result of the final matching action or fallback action.
				def dispatch(controller, request, path)
					if @actions
						matched = @actions.apply(path.components) do |action|
							controller.instance_exec(request, path, &action.callback)
						end
					end
					
					if @otherwise and !matched
						controller.instance_exec(request, path, &@otherwise)
					end
				end
			end
			
			# Invoke all matching actions. If no actions match, will call otherwise. If no action gives a response, the request is passed to super.
			def process!(request, path)
				catch_response do
					self.class.dispatch(self, request, path)
				end || super
			end
		end
	end
end
