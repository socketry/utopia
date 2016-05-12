
# Setup default encoding:
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Load environment variables:
environment_path = File.expand_path('environment.yaml', __dir__)
if File.exist? environment_path
	require 'yaml'
	ENV.update(YAML.load_file(environment_path))
end

# Setup the server environment:
RACK_ENV = ENV.fetch('RACK_ENV', :development).to_sym unless defined?(RACK_ENV)

# Allow loading library code from lib directory:
$LOAD_PATH << File.expand_path('../lib', __dir__)

# Load utopia framework:
require 'utopia'
