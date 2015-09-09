
use Utopia::ExceptionHandler, '/exception'

use Utopia::Controller, root: File.expand_path('exception_handler_spec', __dir__)

run lambda {|env| [404, {}, []]}
