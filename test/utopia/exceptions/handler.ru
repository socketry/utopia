# frozen_string_literal: true

use Utopia::Exceptions::Handler, '/exception'

use Utopia::Controller,
	root: File.expand_path('.handler', __dir__)

run lambda {|env| [404, {}, []]}
