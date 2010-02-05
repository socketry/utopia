
require 'utopia/middleware'

module Utopia
	module Middleware

		class Benchmark
			def initialize(app, options = {})
				@app = app
				@tag = options[:tag] || "{{benchmark}}"
			end

			def call(env)
				start = Time.now
				response = @app.call(env)
				finish = Time.now

				time = "%0.4f" % (finish - start)
				# LOG.debug "benchmark: Request #{env["PATH_INFO"]} took #{time}s"
				buf = StringIO.new

				response[2].each do |text|
					buf.write(text.gsub(@tag, time))
				end

				buf.rewind

				[response[0], response[1], buf]
			end
		end

	end
end
