# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

def process!(_request, path)
	path.components = ["rewritten path"]
	return nil
end
