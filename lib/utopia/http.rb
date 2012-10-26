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

module Utopia
	module HTTP
		STATUS_CODES = {
			:success => 200,
			:created => 201,
			:accepted => 202,
			:moved => 301,
			:found => 302,
			:see_other => 303,
			:not_modified => 304,
			:redirect => 307,
			:bad_request => 400,
			:unauthorized => 401,
			:forbidden => 403,
			:not_found => 404,
			:unsupported_method => 405,
			:gone => 410,
			:teapot => 418,
			:error => 500,
			:unimplemented => 501,
			:unavailable => 503
		}
	
		STATUS_DESCRIPTIONS = {
			400 => "Bad Request",
			401 => "Permission Denied",
			403 => "Access Forbidden",
			404 => "Resource Not Found",
			405 => "Unsupported Method",
			416 => "Byte range unsatisfiable",
			500 => "Internal Server Error",
			501 => "Not Implemented",
			503 => "Service Unavailable"
		}
	end
end
