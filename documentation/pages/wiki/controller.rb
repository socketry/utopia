
prepend Actions

on '**' do |request, path|
	@page_path = path.components[0..-2]
	
	@page_file = File.join(BASE_PATH, @page_path, "content.md")
	
	if last_path_component = @page_path.last
		@page_title = Trenni::Strings::to_title(last_path_component)
	else
		@page_title = "Wiki"
	end
end

def read_contents
	if File.exist? @page_file
		File.read(@page_file)
	else
		"\# #{@page_title}\n\n" +
		"This page is empty."
	end
end

on '**/edit' do |request, path|
	if request.post?
		FileUtils.mkdir_p File.dirname(@page_file)
		File.write(@page_file, request.params['content'])
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
