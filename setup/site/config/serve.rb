# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "utopia/application"

run Utopia::Application.load(File.expand_path("application.rb", __dir__))
