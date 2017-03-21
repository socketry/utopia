
# Configure "min" to be the minimum number of threads to use to answer
# requests and "max" the maximum.
threads 0,4

# Preload the application before starting the workers; this conflicts with
# phased restart feature. (off by default)
preload_app!

# This writes run/url.txt which allows us to watch and load the URL once puma has started.
get(:binds).tap do |binds|
	urls = binds.grep(/tcp:\/\/0.0.0.0:(\d+)/).collect do
		"http://localhost:#{$1}"
	end
	
	run_path = File.expand_path('../run', __dir__)
	
	FileUtils.mkdir_p run_path
	File.write(File.join(run_path, 'url.txt'), urls.first)
end
