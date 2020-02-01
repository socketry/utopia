# frozen_string_literal: true

prepend Actions

on '**' do |request, path|
	@full_path = URI_PATH + path
	@page_path = path.components[0..-2]
	
	@page_file = File.join(BASE_PATH, @page_path, "content.md")
	
	if last_path_component = @page_path.last
		@title = Trenni::Strings::to_title(last_path_component)
	else
		@title = "Wiki"
	end
end

def read_contents
	if File.exist? @page_file
		File.read(@page_file)
	else
		"\# #{@title}\n\n" +
		"This page is empty."
	end
end

on '**/edit' do |request, path|
	if request.post?
		FileUtils.mkdir_p File.dirname(@page_file)
		
		# Get the content and normalize newlines:
		content = request.params['content'].gsub /\r\n?/, "\n"
		File.write(@page_file, content)
		
		# Redirect relative to controller.
		goto! @page_path
	else
		@content = read_contents
	end
	
	path.components = ["edit"]
end

on '**/index' do |request, path|
	@content = read_contents
	
	path.components = ["show"]
end
