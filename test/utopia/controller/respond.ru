# frozen_string_literal: true

use Utopia::Redirection::Errors,
	404 => '/fail'

use Utopia::Controller,
	root: File.expand_path('.respond', __dir__)

use Utopia::Content,
	root: File.expand_path('.respond', __dir__)

run lambda {|env| [404, {}, []]}
