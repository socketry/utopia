
use Utopia::Exceptions::Handler, '/exception'

use Utopia::Controller, root: File.expand_path('handler_spec', __dir__)

run lambda {|env| [404, {}, []]}
