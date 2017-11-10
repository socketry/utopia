// brush: "swift" aliases: []

//	This file is part of the "jQuery.Syntax" project, and is distributed under the MIT License.
//	Copyright (c) 2016 Samuel G. D. Williams. <http://www.oriontransfer.co.nz>
//	See <jquery.syntax.js> for licensing details.

Syntax.register('swift', function(brush) {
	var keywords = [
		"associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "operator", "private", "protocol", "static", "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "catch", "is", "rethrows", "throw", "throws", "try", "_", "#available", "#colorLiteral", "#column", "#else", "#elseif", "#endif", "#file", "#fileLiteral", "#function", "#if", "#imageLiteral", "#line", "#selector", "#sourceLocation", "associativity", "convenience", "dynamic", "didSet", "final", "get", "infix", "indirect", "lazy", "left", "mutating", "none", "nonmutating", "optional", "override", "postfix", "precedence", "prefix", "Protocol", "required", "right", "set", "Type", "unowned", "weak", "willSet"];
		
	var operators = ["+", "*", "/", "-", "&", "|", "~", "!", "%", "<", "=", ">",
		"(", ")", "{", "}", "[", "]", ".", ",", ":", ";", "=", "@", "#", "->", "`", "?", "!"];
		
	var values = ["self", "super", "true", "false", "nil"];
	
	var access = ["fileprivate", "open", "private", "public"];
	
	brush.push(access, {klass: 'access'});
	brush.push(values, {klass: 'constant'});
	
	brush.push({
		pattern: /`[^`]+`/g,
		klass: 'identifier'
	});
	
	brush.push({
		pattern: /\\\(([^)]*)\)/g,
		matches: Syntax.extractMatches({
			brush: 'swift',
			only: ['string']
		})
	});
	
	brush.push(Syntax.lib.camelCaseType);
	brush.push(keywords, {klass: 'keyword'});
	brush.push(operators, {klass: 'operator'});
	
	// Comments
	brush.push(Syntax.lib.cStyleComment);
	brush.push(Syntax.lib.cppStyleComment);
	brush.push(Syntax.lib.webLink);
	
	// Strings
	brush.push(Syntax.lib.singleQuotedString);
	brush.push(Syntax.lib.doubleQuotedString);
	brush.push(Syntax.lib.stringEscape);
	
	// Numbers
	brush.push(Syntax.lib.decimalNumber);
	brush.push(Syntax.lib.hexNumber);
	
	// Functions
	brush.push(Syntax.lib.cStyleFunction);
});

