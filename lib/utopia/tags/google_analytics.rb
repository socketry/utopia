
require 'utopia/tags'

Utopia::Tags.create("google_analytics") do |transaction, state|
result = <<EOF
<script type="text/javascript">
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
    var pageTracker = _gat._getTracker(#{state[:id].dump});
    pageTracker._initData();
    pageTracker._trackPageview();
</script>
EOF
end
