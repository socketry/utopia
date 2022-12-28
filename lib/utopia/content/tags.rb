# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2022, by Samuel Williams.

require_relative 'namespace'

require 'variant'

module Utopia
	class Content
		# Tags which provide intrinsic behaviour within the content middleware.
		module Tags
			extend Namespace
			
			# Invokes a node and renders a single node to the output stream.
			# @param path [String] The path of the node to invoke.
			tag('node') do |document, state|
				path = Path[state[:path]]
				
				node = document.lookup_node(path)
				
				document.render_node(node)
			end
			
			# Invokes a deferred tag from the current state. Works together with {Document::State#defer}.
			# @param id [String] The id of the deferred to invoke.
			tag('deferred') do |document, state|
				id = state[:id].to_i
				
				deferred = document.parent.deferred[id]
				
				deferred.call(document, state)
			end
			
			# Renders the content of the parent node into the output of the document.
			tag('content') do |document, state|
				# We are invoking this node within a parent who has content, and we want to generate output equal to that.
				document.write(document.parent.content)
			end
			
			# Render the contents only if in the correct environment.
			# @param only [String] A comma separated list of environments to check.
			tag('environment') do |document, state|
				variant = document.attributes.fetch(:variant) do
					Variant.for(:utopia)
				end.to_s
				
				if state[:only].split(',').include?(variant)
					document.parse_markup(state.content)
				end
			end
		end
	end
end
