
use Utopia::ExceptionHandler, '/controller/exception'

use Utopia::Controller, root: File.expand_path('../pages', __FILE__)

run lambda {|env| [404, {}, []]}
