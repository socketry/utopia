#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

Utopia::Tags.create("env") do |transaction, state|
	only = state[:only].split(",").collect(&:to_sym) rescue []

	if defined?(UTOPIA_ENV) && only.include?(UTOPIA_ENV)
		transaction.parse_xml(state.content)
	end
end
