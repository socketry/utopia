# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Redirection
		# An error handler fails to redirect to a valid page.
		class RequestFailure < StandardError
			# Describe a failed attempt to render an error document.
			# @parameter resource_path [Object] The resource path.
			# @parameter resource_status [Object] The resource status.
			# @parameter error_path [Object] The error path.
			# @parameter error_status [Object] The error status.
			def initialize(resource_path, resource_status, error_path, error_status)
				@resource_path = resource_path
				@resource_status = resource_status
				
				@error_path = error_path
				@error_status = error_status
				
				super "Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
			end
		end
	end
end
