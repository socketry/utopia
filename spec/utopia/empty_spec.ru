# frozen_string_literal: true

use Utopia::Content,
	root: File.expand_path('empty_spec', __dir__)

run lambda {|env| [404, {}, []]}
