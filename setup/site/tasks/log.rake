
task :log do
	require 'utopia/logger'
	LOGGER = Utopia.logger
end

namespace :log do
	desc "Increase verbosity of logger to info."
	task :info => :log do
		LOGGER.info!
	end

	desc "Increase verbosity of global debug."
	task :debug => :log do
		LOGGER.debug!
	end
end
