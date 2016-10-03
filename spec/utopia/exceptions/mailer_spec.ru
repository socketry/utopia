
use Utopia::Exceptions::Mailer, delivery_method: :test, from: 'test@localhost'

use Utopia::Controller, root: File.expand_path('handler_spec', __dir__)

run lambda {|env| [404, {}, []]}
