#include "ruby.h"

#define OPENED_TAG 0
#define CLOSED_TAG 1

static VALUE rb_XNode;
static VALUE rb_XNode_ScanError;
static VALUE rb_XNode_Scanner;

static ID rb_XNode_CDATA_Callback;
static ID rb_XNode_BeginTag_Callback;
static ID rb_XNode_FinishTag_Callback;
static ID rb_XNode_Attribute_Callback;
static ID rb_XNode_Comment_Callback;
static ID rb_XNode_Instruction_Callback;
static ID rb_XNode_Comment_Callback;

#define NewObject(type) (type*)malloc(sizeof(type))

typedef struct {
	VALUE delegate;
	VALUE content;
} XNode_Scanner;

typedef char Character;
typedef Character * Iterator;

static void XNode_Scanner_Mark(XNode_Scanner * scanner) {
	rb_gc_mark(scanner->delegate);
	rb_gc_mark(scanner->content);
}

static void XNode_Scanner_Free(XNode_Scanner * scanner) {
	free(scanner);
}

static VALUE XNode_Scanner_Allocate(VALUE klass) {
	XNode_Scanner * scanner = NewObject(XNode_Scanner);
	
	return Data_Wrap_Struct(klass, XNode_Scanner_Mark, XNode_Scanner_Free, scanner);
}

static VALUE XNode_Scanner_Initialize(VALUE self, VALUE delegate, VALUE content) {
	Check_Type(content, T_STRING);

	XNode_Scanner * scanner;

	Data_Get_Struct(self, XNode_Scanner, scanner);

	scanner->delegate = delegate;
	scanner->content = content;

	return Qnil;
}

static VALUE rb_str_from_iterators(Iterator start, Iterator end) {
	return rb_str_new(start, end - start);
}

static int is_whitespace(Iterator i) {
	return (*i == ' ' || *i == '\r' || *i == '\n' || *i == '\t');
}

static int is_tag_character(Iterator i) {
	return (*i == '<' || *i == '>' || *i == '/');
}

static int is_tag_name(Iterator i) {
	return !(is_whitespace(i) || is_tag_character(i));
}

static Iterator expect_character(XNode_Scanner * scanner, Iterator start, Iterator end, Character c) {
	if (start >= end || *start != c) {
		VALUE message = rb_str_new2("Expected Character ");
		rb_str_cat(message, &c, 1);
		VALUE exception = rb_exc_new3(rb_XNode_ScanError, message);
		rb_exc_raise(exception);
	}
	
	return start + 1;
}

static Iterator skip_whitespace(Iterator start, Iterator end) {
	while (start < end) {
		if (!is_whitespace(start))
			break;
			
		++start;
	}
	
	return start;
}

static Iterator XNode_Scanner_Parse_CDATA(XNode_Scanner * scanner, Iterator start, Iterator end) {
	Iterator cdata_start = start;
	
	while (start < end && *start != '<') {
		++start;
	}
	
	Iterator cdata_end = start;

	if (cdata_start != cdata_end) {
		VALUE cdata = rb_str_from_iterators(cdata_start, cdata_end);
		rb_funcall(scanner->delegate, rb_XNode_CDATA_Callback, 1, cdata);
	}
	
	return start;
}

static Iterator XNode_Scanner_Parse_Attributes(XNode_Scanner * scanner, Iterator start, Iterator end) {
	while (start < end && !is_tag_character(start)) {
		start = skip_whitespace(start, end);

		Iterator attribute_name_start = start;
	
		while (start < end && *start != '=') {
			++start;
		}

		Iterator attribute_name_end = start;

		start = expect_character(scanner, start, end, '=');
		start = expect_character(scanner, start, end, '"');

		Iterator attribute_value_start = start;

		while (start < end && *start != '"') {
			++start;
		}

		Iterator attribute_value_end = start;
		start = expect_character(scanner, start, end, '"');

		VALUE attribute_name = rb_str_from_iterators(attribute_name_start, attribute_name_end);
		VALUE attribute_value = rb_str_from_iterators(attribute_value_start, attribute_value_end);
		rb_funcall(scanner->delegate, rb_XNode_Attribute_Callback, 2, attribute_name, attribute_value);
		
		start = skip_whitespace(start, end);
	}
	
	return start;
}

static Iterator XNode_Scanner_Parse_Tag_Normal(XNode_Scanner * scanner, Iterator start, Iterator end, int begin_tag_type) {
	Iterator tag_name_start = start;
	int finish_tag_type;
	
	while (start < end && is_tag_name(start)) {
		++start;
	}
	
	Iterator tag_name_end = start;
	
	VALUE tag_name = rb_str_from_iterators(tag_name_start, tag_name_end);
	rb_funcall(scanner->delegate, rb_XNode_BeginTag_Callback, 2, tag_name, INT2FIX(begin_tag_type));
	
	start = skip_whitespace(start, end);
	
	if (!is_tag_character(start))
		start = XNode_Scanner_Parse_Attributes(scanner, start, end);
	
	if (*start == '/') {
		if (begin_tag_type == CLOSED_TAG) {
			VALUE exception = rb_exc_new2(rb_XNode_ScanError, "Tag cannot be closed at both ends!");
			rb_exc_raise(exception);
		}
		
		finish_tag_type = CLOSED_TAG;
		start += 2;
	} else if (*start == '>') {
		finish_tag_type = OPENED_TAG;
		++start;
	}
	
	rb_funcall(scanner->delegate, rb_XNode_FinishTag_Callback, 2, INT2FIX(begin_tag_type), INT2FIX(finish_tag_type));
	
	return start;
}

static Iterator XNode_Scanner_Parse_Tag_Comment(XNode_Scanner * scanner, Iterator start, Iterator end) {
	Iterator comment_start = start;
	
	while (start < end && *start != '>') {
		++start;
	}
	
	Iterator comment_end = start;
	
	start = expect_character(scanner, start, end, '>');
	
	VALUE comment = rb_str_from_iterators(comment_start, comment_end);
	rb_funcall(scanner->delegate, rb_XNode_Comment_Callback, 1, comment);
	
	return start;
}

static Iterator XNode_Scanner_Parse_Tag_Instruction(XNode_Scanner * scanner, Iterator start, Iterator end) {
	Iterator instruction_start = start;
	
	while ((start+1) < end && *start != '?' && *(start+1) != '>') {
		++start;
	}
	
	Iterator instruction_end = start;
	
	start = expect_character(scanner, start, end, '?');
	start = expect_character(scanner, start, end, '>');
	
	VALUE instruction = rb_str_from_iterators(instruction_start, instruction_end);
	rb_funcall(scanner->delegate, rb_XNode_Instruction_Callback, 1, instruction);
	
	return start;
}

static Iterator XNode_Scanner_Parse_Tag(XNode_Scanner * scanner, Iterator start, Iterator end) {
	if (*start == '<') {
		++start;
		
		if (*start == '/') {
			++start;
			start = XNode_Scanner_Parse_Tag_Normal(scanner, start, end, CLOSED_TAG);
		} else if (*start == '!') {
			++start;
			start = XNode_Scanner_Parse_Tag_Comment(scanner, start, end);
		} else if (*start == '?') {
			++start;
			start = XNode_Scanner_Parse_Tag_Instruction(scanner, start, end);
		} else {
			start = XNode_Scanner_Parse_Tag_Normal(scanner, start, end, OPENED_TAG);
		}
	}
	
	return start;
}

static Iterator XNode_Scanner_Parse_Document(XNode_Scanner * scanner) {
	Iterator current, start, end;

	start = RSTRING(scanner->content)->ptr;
	end = start + RSTRING(scanner->content)->len;

	while (start < end) {
		current = start;
		
		current = XNode_Scanner_Parse_CDATA(scanner, current, end);
		current = XNode_Scanner_Parse_Tag(scanner, current, end);
		
		if (current == start) {
			/* We did not parse anything! */
			VALUE message = rb_str_new2("Parser Stuck at ");
			
			int len = 10;
			if (current + len > end)
				len = end - current;
			
			rb_str_cat(message, current, len);
			VALUE exception = rb_exc_new3(rb_XNode_ScanError, message);
			rb_exc_raise(exception);
		}
		
		start = current;
	}
}

static VALUE XNode_Scanner_Parse(VALUE self) {
	XNode_Scanner * scanner;

	Data_Get_Struct(self, XNode_Scanner, scanner);
		
	XNode_Scanner_Parse_Document(scanner);
}

void Init_xnode() {
	rb_XNode = rb_define_module("XNode");
	rb_XNode_ScanError = rb_define_class_under(rb_XNode, "ScanError", rb_eStandardError);
	rb_XNode_Scanner = rb_define_class_under(rb_XNode, "Scanner", rb_cObject);
	
	rb_define_alloc_func(rb_XNode_Scanner, XNode_Scanner_Allocate);
	rb_define_method(rb_XNode_Scanner, "initialize", XNode_Scanner_Initialize, 2);
	rb_define_method(rb_XNode_Scanner, "parse", XNode_Scanner_Parse, 0);
	
	rb_XNode_CDATA_Callback = rb_intern("cdata");
	rb_XNode_BeginTag_Callback = rb_intern("begin_tag");
	rb_XNode_FinishTag_Callback = rb_intern("finish_tag");
	rb_XNode_Attribute_Callback = rb_intern("attribute");
	rb_XNode_Comment_Callback = rb_intern("comment");
	rb_XNode_Instruction_Callback = rb_intern("instruction");
}
