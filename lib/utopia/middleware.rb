# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2022, by Samuel Williams.

require_relative 'http'
require_relative 'path'

module Utopia
	# The default pages path for {Utopia::Content} middleware.
	PAGES_PATH = 'pages'.freeze
	
	# This is used for shared controller variables which get consumed by the content middleware.
	VARIABLES_KEY = 'utopia.variables'.freeze
	
	# The default root directory for middleware to operate within, e.g. the web-site directory. Convention over configuration.
	# @param subdirectory [String] Appended to the default root to make a more specific path.
	# @param pwd [String] The working directory for the current site.
	def self.default_root(subdirectory = PAGES_PATH, pwd = Dir.pwd)
		File.expand_path(subdirectory, pwd)
	end
	
	# The same as {default_root} but returns an instance of {Path}.
	# @return [Path] The path as requested.
	def self.default_path(*arguments)
		Path[default_root(*arguments)]
	end
end
