// brush: "html" aliases: []

//	This file is part of the "jQuery.Syntax" project, and is distributed under the MIT License.
//	Copyright (c) 2011 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
//	See <jquery.syntax.js> for licensing details.

Syntax.brushes.dependency('trenni', 'xml');
Syntax.brushes.dependency('trenni', 'ruby');

Syntax.register('trenni', function(brush) {
	brush.push({
		pattern: /((<\?r)([\s\S]*?)(\?>))/gm,
		matches: Syntax.extractMatches(
			{klass: 'ruby-tag', allow: ['keyword', 'ruby']},
			{klass: 'keyword'},
			{brush: 'ruby'},
			{klass: 'keyword'}
		)
	});
	
	brush.push({
		pattern: /((#{)([\s\S]*?)(}))/gm,
		matches: Syntax.extractMatches(
			{klass: 'ruby-tag', allow: ['keyword', 'ruby']},
			{klass: 'keyword'},
			{brush: 'ruby'},
			{klass: 'keyword'}
		)
	});
	
	// The position of this statement is important - it determines at what point the rules of the parent are processed.
	// In this case, the rules for xml are processed after the rules for html.
	brush.derives('xml');
});

