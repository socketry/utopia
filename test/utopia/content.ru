# frozen_string_literal: true

use Utopia::Content,
	root: File.expand_path('.content', __dir__)

run lambda {|env| [404, {}, []]}
