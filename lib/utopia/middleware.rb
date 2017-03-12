# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'logger'

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
end
