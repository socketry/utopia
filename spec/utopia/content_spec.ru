
require 'utopia/tags/deferred'

use Utopia::Content,
	root: File.expand_path('pages', __dir__),
	tags: {
		'deferred' => Utopia::Tags::Deferred
	}

run lambda {|env| [404, {}, []]}
