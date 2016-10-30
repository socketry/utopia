
prepend Actions

on '**' do |request, path|
	@page_path = path.components[0..-2]
	
	if @page_path.empty?
		goto! "welcome/index"
	end
	
	@page_file = File.join(BASE_PATH, @page_path, "content.md")
	@page_title = Trenni::Strings::to_title @page_path.last
end

def read_contents
	if File.exist? @page_file
		File.read(@page_file)
	else
		"This page is empty."
	end
end

on '**/edit' do |request, path|
	puts "Editing..."
	
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
	
	path.components = ["index"]
end
