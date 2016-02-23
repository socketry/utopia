
prepend Respond

respond.passthrough
respond.with_json

on 'file-not-found' do
	fail! 404, {message: 'File not found'}
end
