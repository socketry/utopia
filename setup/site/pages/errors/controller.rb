
prepend Respond

respond.with_json
respond.otherwise_passthrough

on 'file-not-found' do
	fail! 404, {message: 'File not found'}
end
