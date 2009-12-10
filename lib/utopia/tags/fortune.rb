
require 'utopia/tags'

Utopia::Tags.create("fortune") do |transaction, state|
	"<pre>#{`fortune`.to_html}</pre>"
end
