# frozen_string_literal: true

use Utopia::Controller,
	root: File.expand_path(".middleware", __dir__)

run lambda {|env| [404, {}, []]}
