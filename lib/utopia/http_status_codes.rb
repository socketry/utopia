#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Utopia
	
	HTTP_STATUS_CODES = {
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
	
	HTTP_STATUS_DESCRIPTIONS = {
		400 => "Bad Request",
		401 => "Permission Denied",
		403 => "Access Forbidden",
		404 => "Resource Not Found",
		405 => "Unsupported Method",
		500 => "Internal Server Error",
		501 => "Not Implemented",
		503 => "Service Unavailable"
	}
end
