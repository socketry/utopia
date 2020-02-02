# frozen_string_literal: true

task :log do
	require 'utopia/logger'
	
	# This is deprecated, prefer to use `Utopia.logger` or `Async.logger`:
	LOGGER = Utopia.logger
end

namespace :log do
	desc "Increase verbosity of logger to info."
	task :info => :log do
		Utopia.logger.info!
	end

	desc "Increase verbosity of global debug."
	task :debug => :log do
		Utopia.logger.debug!
	end
end
