
use Utopia::Middleware::Static, root: File.expand_path('../pages', __FILE__)

run lambda {|env| [404, {}, []]}
