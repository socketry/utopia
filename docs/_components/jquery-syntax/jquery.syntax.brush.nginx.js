// brush: "nginx" aliases: []

//	This file is part of the "jQuery.Syntax" project, and is distributed under the MIT License.
//	Copyright (c) 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
//	See <jquery.syntax.js> for licensing details.

Syntax.register('nginx', function(brush) {
	brush.push({
		pattern: /((\w+).*?);/g,
		matches: Syntax.extractMatches(
			{klass: 'directive', allow: '*'},
			{klass: 'function', process: Syntax.lib.webLinkProcess("http://nginx.org/r/")}
		)
	});
	
	brush.push({
		pattern: /(\w+).*?{/g,
		matches: Syntax.extractMatches(
			{klass: 'keyword'}
		)
	});
	
	brush.push({pattern: /(\$)[\w]+/g, klass: 'variable'});
	
	brush.push(Syntax.lib.perlStyleComment);
	brush.push(Syntax.lib.singleQuotedString);
	brush.push(Syntax.lib.doubleQuotedString);
	
	brush.push(Syntax.lib.webLink);
});

