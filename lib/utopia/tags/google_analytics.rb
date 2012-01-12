#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

Utopia::Tags.create("google_analytics") do |transaction, state|
	html = <<EOF
<script type="text/javascript">
	var _gaq = _gaq || []; _gaq.push(['_setAccount', #{state[:id].to_quoted_string}]); _gaq.push(['_trackPageview']);
	(function() {
		var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
		ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
		var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
	})();
</script>
EOF


	transaction.cdata(html)
end
