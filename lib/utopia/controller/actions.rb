# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Utopia
	class Controller
		module Actions
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			class Action < Hash
				def initialize(options = {}, &block)
					@options = options
					@callback = block
					
					super()
				end
				
				attr_accessor :callback, :options
				
				def callback?
					@callback != nil
				end
				
				def eql? other
					super and @callback.eql? other.callback and @options.eql? other.options
				end
				
				def hash
					[super, @callback, @options].hash
				end
				
				def == other
					super and @callback == other.callback and @options == other.options
				end
				
				WILDCARD_GREEDY = '**'.freeze
				WILDCARD = '*'.freeze
				
				# Given a path, iterate over all actions that match. Actions match from most specific to most general.
				# @return nil if nothing matched, or true if something matched.
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
				
				def matching(path, &block)
					to_enum(:apply, path).to_a
				end
				
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
				
				def inspect
					if callback?
						"<action " + super + ":#{callback.source_location}(#{options})>"
					else
						"<action " + super + ">"
					end
				end
			end
			
			module ClassMethods
				def self.extended(klass)
					klass.instance_eval do
						@actions = nil
						@otherwise = nil
					end
				end
				
				def actions
					@actions ||= Action.new
				end
				
				def on(first, *path, **options, &block)
					if first.is_a? Symbol
						first = ['**', first.to_s]
					end
					
					actions.define(Path.split(first) + path, options, &block)
				end
				
				def otherwise(&block)
					@otherwise = block
				end
				
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
