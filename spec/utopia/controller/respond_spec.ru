
use Utopia::Controller, root: File.expand_path('respond_spec', __dir__)

use Utopia::Content, root: File.expand_path('respond_spec', __dir__)

run lambda {|env| [404, {}, []]}
