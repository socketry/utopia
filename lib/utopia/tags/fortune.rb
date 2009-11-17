
require 'utopia/tags'

Utopia::Tags.create("fortune") do |t|
	"<pre>#{`fortune`.to_html}</pre>"
end
