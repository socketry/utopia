# frozen_string_literal: true

use Utopia::Static, root: File.expand_path('static_spec', __dir__)

run lambda {|env| [404, {}, []]}
