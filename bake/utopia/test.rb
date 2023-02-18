# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

def coverage
	ENV['COVERAGE'] = 'PartialSummary'
end

def test
	system("sus") or abort
end
