# frozen_string_literal: true

use Utopia::Controller,
	root: File.expand_path('middleware_spec', __dir__)

run lambda {|env| [404, {}, []]}
