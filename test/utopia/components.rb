# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"
require "json"
require "tmpdir"

require "utopia/components"

describe Utopia::Components do
	def write(path, content)
		FileUtils.mkdir_p(File.dirname(path))
		File.write(path, content)
	end
	
	it "copies selected files from a package distribution" do
		Dir.mktmpdir do |root|
			package = File.join(root, "node_modules/mermaid/dist")
			write(File.join(package, "mermaid.esm.min.mjs"), "entry")
			write(File.join(package, "chunks/mermaid.esm.min/diagram.mjs"), "chunk")
			write(File.join(package, "chunks/mermaid.esm.min/diagram.mjs.map"), "map")
			write(File.join(package, "mermaid.js"), "unused")
			
			write(File.join(root, "public/_components/mermaid/stale.mjs"), "stale")
			write(File.join(root, "package.json"), JSON.generate(
				"utopia" => {
					"components" => {
						"mermaid" => {
							"include" => [
								"mermaid.esm.min.mjs",
								"chunks/mermaid.esm.min/**/*.mjs",
							],
						},
					},
				},
			))
			
			subject.new(root).update(["mermaid"])
			install = File.join(root, "public/_components/mermaid")
			
			expect(File.read(File.join(install, "mermaid.esm.min.mjs"))).to be == "entry"
			expect(File.read(File.join(install, "chunks/mermaid.esm.min/diagram.mjs"))).to be == "chunk"
			expect(File).not.to be(:exist?, File.join(install, "chunks/mermaid.esm.min/diagram.mjs.map"))
			expect(File).not.to be(:exist?, File.join(install, "mermaid.js"))
			expect(File).not.to be(:exist?, File.join(install, "stale.mjs"))
		end
	end
	
	it "copies unconfigured scoped packages using the existing behavior" do
		Dir.mktmpdir do |root|
			write(File.join(root, "package.json"), "{}")
			write(File.join(root, "node_modules/@socketry/syntax/Syntax.js"), "syntax")
			
			subject.new(root).update(["@socketry/syntax"])
			
			installed = File.join(root, "public/_components/@socketry/syntax/Syntax.js")
			expect(File.read(installed)).to be == "syntax"
		end
	end
	
	it "validates patterns before removing existing components" do
		Dir.mktmpdir do |root|
			write(File.join(root, "node_modules/mermaid/dist/mermaid.esm.min.mjs"), "entry")
			write(File.join(root, "public/_components/mermaid/existing.mjs"), "existing")
			write(File.join(root, "package.json"), JSON.generate(
				"utopia" => {
					"components" => {
						"mermaid" => {"include" => ["missing/**/*.mjs"]},
					},
				},
			))
			
			expect do
				subject.new(root).update(["mermaid"])
			end.to raise_exception(ArgumentError, message: be =~ /matched no files/)
			
			existing = File.join(root, "public/_components/mermaid/existing.mjs")
			expect(File.read(existing)).to be == "existing"
		end
	end
end
