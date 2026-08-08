# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "protocol/content/parameters"

prepend Actions

PARAMETERS = Protocol::Content::Parameters.build do
	nested "user", required: true do
		field "name", String, required: true
		field "age", Integer
		field "role", enumeration("member", "administrator")
		upload "avatar", accept: ["text/plain"], size_limit: 8
	end
end

def respond_json!(status, value)
	respond! Utopia::Response[status, {"content-type" => "application/json"}, [JSON.generate(value)]]
end

on "parse" do |request|
	result = parse_body(request, parser: PARAMETERS) do |_name, upload|
		{
			"filename" => upload.filename,
			"content" => upload.each.to_a.join
		}
	end
	
	if result.valid?
		respond_json!(200, "value" => result.value)
	else
		errors = result.errors.map do |error|
			{"path" => error.path, "code" => error.code}
		end
		
		respond_json!(422, "errors" => errors)
	end
rescue Protocol::Content::UnsupportedMediaTypeError
	respond_json!(415, "error" => "unsupported_media_type")
end
