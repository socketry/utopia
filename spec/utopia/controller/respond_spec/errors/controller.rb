
prepend Respond, Actions

# If the request doesn't match application/json specifically, it would be passed through:
respond.with_passthrough
respond.with_json

# The reason why this test is important is that it tests the behaviour of error handling. Normally, if a request comes into the middleware and fails due to an unhandled exception, this is passed along by Utopia::ExceptionHandler. If the client is expecting JSON, they should get a JSON error response.
on 'file-not-found' do
	fail! 404, {message: 'File not found'}
end

# Accept: text/html, application/json, */*
