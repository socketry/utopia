
use Utopia::Controller, root: File.expand_path('middleware_spec', __dir__), cache_controllers: true

run lambda {|env| [404, {}, []]}
