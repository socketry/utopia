
require 'utopia/middleware'
require 'utopia/path'

class Rack::Request
	def controller(&block)
		if block_given?
			env["utopia.controller"].instance_eval(&block)
		else
			env["utopia.controller"]
		end
	end
end

module Utopia
	module Middleware

		class Controller
			CONTROLLER_RB = "controller.rb"

			class Variables
				def [](key)
					instance_variable_get("@#{key}")
				end
			end

			class Base
				def initialize(controller)
					@controller = controller
				end

				def call(env)
					@controller.app.call(env)
				end

				def redirect(target, status=302)
					Rack::Response.new([], status, "Location" => target.to_s).finish
				end

				def process!(path, request)
				end
			end

			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				LOG.info "#{self.class.name}: Running in #{@root}"

				@controllers = {}
				@cache_controllers = true

				if options[:controller_file]
					@controller_file = options[:controller_file]
				else
					@controller_file = "controller.rb"
				end
			end

			attr :app

			def lookup(path)
				if @cache_controllers
					return @controllers.fetch(path.to_s) do |key|
						@controllers[key] = load_file(path)
					end
				else
					return load_file(path)
				end
			end

			def load_file(path)
				if path.directory?
					base_path = File.join(@root, path.components)
				else
					base_path = File.join(@root, path.dirname.components)
				end

				controller_path = File.join(base_path, CONTROLLER_RB)

				if File.exist?(controller_path)
					Dir.chdir(base_path) do
						klass = Class.new(Base)
						klass.class_eval(File.read(CONTROLLER_RB), CONTROLLER_RB)
						return klass.new(self)
					end
				else
					return nil
				end
			end

			def fetch_controllers(path)
				controllers = []
				path.ascend do |parent_path|
					controllers << lookup(parent_path)
				end

				return controllers.compact.reverse
			end

			def call(env)
				env["utopia.controller"] ||= Variables.new
				
				request = Rack::Request.new(env)

				path = Path.create(request.path_info)
				fetch_controllers(path).each do |controller|
					if result = controller.process!(path, request)
						return result
					end
				end

				return @app.call(env)
			end
		end

	end
end
