# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "utopia/import_map"

describe Utopia::ImportMap do
	with ".build" do
		it "creates an import map with a block yielding map" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react@18")
				map.import("@myapp/utils", "./js/utils.js")
			end
			
			expect(import_map).to be_a(subject)
			expect(import_map.imports).to have_keys("react", "@myapp/utils")
		end
		
		it "supports instance_eval style" do
			import_map = subject.build do
				import("app", "./app.js")
			end
			
			expect(import_map.imports).to have_keys("app")
		end
		
		it "returns a frozen instance" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react")
			end
			
			expect(import_map).to be(:frozen?)
		end
		
		it "supports with(base:) for scoped imports" do
			import_map = subject.build do |map|
				map.with(base: "https://cdn.jsdelivr.net/npm/") do |m|
					m.import "lit", "lit@2.7.5/index.js"
					m.import "lit/decorators.js", "lit@2.7.5/decorators.js"
				end
			end
			
			expect(import_map.imports["lit"]).to be == "https://cdn.jsdelivr.net/npm/lit@2.7.5/index.js"
			expect(import_map.imports["lit/decorators.js"]).to be == "https://cdn.jsdelivr.net/npm/lit@2.7.5/decorators.js"
		end
		
		it "supports nested with(base:) blocks" do
			import_map = subject.build do |map|
				map.import("app", "./app.js")
				
				map.with(base: "/_components/") do |m|
					m.import "mermaid", "mermaid/mermaid.esm.min.mjs"
				end
				
				map.with(base: "https://cdn.jsdelivr.net/npm/") do |m|
					m.import "lit", "lit@2.7.5/index.js"
				end
			end
			
			expect(import_map.imports["app"]).to be == "./app.js"
			expect(import_map.imports["mermaid"]).to be == "/_components/mermaid/mermaid.esm.min.mjs"
			expect(import_map.imports["lit"]).to be == "https://cdn.jsdelivr.net/npm/lit@2.7.5/index.js"
		end
		
		it "supports with(base:) with instance_eval style" do
			import_map = subject.build do |map|
				map.with(base: "https://esm.sh/") do
					import "react", "react@18"
					import "vue", "vue@3"
				end
			end
			
			expect(import_map.imports["react"]).to be == "https://esm.sh/react@18"
			expect(import_map.imports["vue"]).to be == "https://esm.sh/vue@3"
		end
	end
	
	with "#initialize" do
		it "creates an empty import map" do
			import_map = subject.new
			
			expect(import_map.imports).to be(:empty?)
			expect(import_map.scopes).to be(:empty?)
			expect(import_map.integrity).to be(:empty?)
		end
		
		it "accepts base parameter" do
			import_map = subject.new(base: "/_components/")
			
			expect(import_map.base.to_s).to be == "/_components/"
		end
	end
	
	with "#import" do
		it "adds an import" do
			import_map = subject.new
			import_map.import("react", "https://esm.sh/react")
			
			expect(import_map.imports).to have_keys("react")
		end
		
		it "supports integrity" do
			import_map = subject.new
			import_map.import("react", "https://esm.sh/react", integrity: "sha384-abc123")
			
			expect(import_map.integrity["react"]).to be == "sha384-abc123"
		end
		
		it "returns self for chaining" do
			import_map = subject.new
			result = import_map.import("react", "https://esm.sh/react")
			
			expect(result).to be == import_map
		end
	end
	
	with "#scope" do
		it "adds a scope mapping" do
			import_map = subject.new
			import_map.scope("pages/", {"app" => "./pages-app.js"})
			
			expect(import_map.scopes["pages/"]).to have_keys("app")
		end
		
		it "returns self for chaining" do
			import_map = subject.new
			result = import_map.scope("pages/", {"app" => "./pages-app.js"})
			
			expect(result).to be == import_map
		end
	end
	
	with "#relative_to" do
		it "creates a new import map with relative base" do
			import_map = subject.new(base: "/_components/")
			page_map = import_map.relative_to("/foo/bar/")
			
			expect(page_map.base.to_s).to be == "../../_components/"
		end
		
		it "preserves imports, scopes, and integrity" do
			import_map = subject.build(base: "/_components/") do |map|
				map.import("react", "https://esm.sh/react", integrity: "sha384-abc123")
				map.scope("pages/", {"app" => "./app.js"})
			end
			
			page_map = import_map.relative_to("/foo/bar/")
			
			expect(page_map.imports).to have_keys("react")
			expect(page_map.scopes).to have_keys("pages/")
			expect(page_map.integrity).to have_keys("react")
		end
		
		it "works with nil base" do
			import_map = subject.new
			page_map = import_map.relative_to("/foo/bar/")
			
			expect(page_map.base).to be_nil
		end
		
		it "returns a frozen instance" do
			import_map = subject.new(base: "/_components/")
			page_map = import_map.relative_to("/foo/bar/")
			
			expect(page_map).to be(:frozen?)
		end
	end
	
	with "#to_json" do
		with "without base" do
			let(:import_map) do
				subject.build do |map|
					map.import("react", "https://esm.sh/react@18")
					map.import("@myapp/utils", "./js/utils.js")
					map.import("components/button", "/components/button.js")
				end
			end
			
			it "returns imports as-is for URIs" do
				json = import_map.as_json
				expect(json["imports"]["react"]).to be == "https://esm.sh/react@18"
			end
			
			it "returns imports as-is for relative paths" do
				json = import_map.as_json
				expect(json["imports"]["@myapp/utils"]).to be == "./js/utils.js"
			end
			
			it "returns imports as-is for absolute paths" do
				json = import_map.as_json
				expect(json["imports"]["components/button"]).to be == "/components/button.js"
			end
		end
		
		with "with base" do
			let(:import_map) do
				subject.build(base: "../") do |map|
					map.import("react", "https://esm.sh/react@18")
					map.import("utils", "./js/utils.js")
					map.import("components/button", "/components/button.js")
				end
			end
			
			it "returns URIs unchanged" do
				json = import_map.as_json
				expect(json["imports"]["react"]).to be == "https://esm.sh/react@18"
			end
			
			it "resolves relative paths using base" do
				json = import_map.as_json
				# "../" + "./js/utils.js" should simplify to "../js/utils.js"
				expect(json["imports"]["utils"]).to be == "../js/utils.js"
			end
			
			it "resolves absolute paths using base" do
				json = import_map.as_json
				# "../" + "/components/button.js" should resolve correctly
				expect(json["imports"]["components/button"]).to be == "/components/button.js"
			end
		end
		
		with "complex path resolution" do
			let(:import_map) do
				subject.build(base: "pages/blog/") do |map|
					map.import("app", "./app.js")
					map.import("vendor", "../vendor/lib.js")
					map.import("cdn", "https://cdn.example.com/lib.js")
					map.import("root", "/api/config.js")
				end
			end
			
			it "resolves multiple relative path styles" do
				json = import_map.as_json
				
				# "pages/blog/" + "./app.js" => "pages/blog/app.js"
				expect(json["imports"]["app"]).to be == "pages/blog/app.js"
			end
			
			it "resolves parent directory references" do
				json = import_map.as_json
				
				# "pages/blog/" + "../vendor/lib.js" => "pages/vendor/lib.js"
				expect(json["imports"]["vendor"]).to be == "pages/vendor/lib.js"
			end
			
			it "keeps CDN URLs unchanged" do
				json = import_map.as_json
				
				expect(json["imports"]["cdn"]).to be == "https://cdn.example.com/lib.js"
			end
			
			it "handles protocol-relative URLs" do
				import_map = subject.build(base: "pages/") do |map|
					map.import("protocol", "//example.com/lib.js")
				end
				
				json = import_map.as_json
				expect(json["imports"]["protocol"]).to be == "//example.com/lib.js"
			end
		end
		
		with "scopes" do
			it "includes scopes in output" do
				import_map = subject.build do |map|
					map.scope("pages/", {"app" => "./pages-app.js"})
				end
				
				json = import_map.as_json
				expect(json["scopes"]).to have_keys("pages/")
				expect(json["scopes"]["pages/"]["app"]).to be == "./pages-app.js"
			end
			
			it "resolves scoped imports with base" do
				import_map = subject.build(base: "pages/") do |map|
					map.scope("src/", {"utils" => "../utils.js"})
				end
				
				json = import_map.as_json
				# "pages/" + "src/" = "pages/src/" for the scope prefix
				# "../utils.js" resolved from scope base
				expect(json["scopes"]["pages/src/"]).to have_keys("utils")
			end
		end
		
		with "integrity" do
			it "includes integrity values" do
				import_map = subject.build do |map|
					map.import("react", "https://esm.sh/react", integrity: "sha384-abc123")
					map.import("vue", "https://esm.sh/vue", integrity: "sha384-def456")
				end
				
				json = import_map.as_json
				expect(json["integrity"]["react"]).to be == "sha384-abc123"
				expect(json["integrity"]["vue"]).to be == "sha384-def456"
			end
		end
	end
	
	with "#to_html" do
		it "generates an HTML script tag with importmap type" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react")
			end
			
			html = import_map.to_html
			
			expect(html.to_s).to be(:match?, /<script type="importmap">/)
			expect(html.to_s).to be(:match?, /<\/script>/)
		end
		
		it "includes the import map as JSON" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react")
			end
			
			html = import_map.to_html
			
			expect(html.to_s).to be(:match?, /react/)
			expect(html.to_s).to be(:match?, /esm.sh/)
		end
		
		it "uses base for path resolution" do
			import_map = subject.build(base: "pages/") do |map|
				map.import("app", "./app.js")
			end
			
			html = import_map.to_html
			
			expect(html.to_s).to be(:match?, /pages\/app\.js/)
		end
		
		it "properly escapes JSON data" do
			import_map = subject.build do |map|
				map.import("app", "./app.js")
			end
			
			html = import_map.to_html.to_s
			
			# Should have valid JSON (escaped for HTML)
			expect(html).to be(:match?, /app/)
			expect(html).to be(:match?, /app\.js/)
		end
	end
	
	with "#to_s" do
		it "returns a string representation" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react")
			end
			
			expect(import_map.to_s).to be_a(String)
			expect(import_map.to_s).to be(:match?, /importmap/)
		end
		
		it "uses base for path resolution" do
			import_map = subject.build(base: "pages/") do |map|
				map.import("app", "./app.js")
			end
			
			expect(import_map.to_s).to be(:match?, /pages\/app\.js/)
		end
		
		it "produces the same output as to_html.to_s" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react")
			end
			
			expect(import_map.to_s).to be == import_map.to_html.to_s
		end
	end
	
	with "integration" do
		it "handles empty import map" do
			import_map = subject.new
			
			expect(import_map.to_s).to be(:match?, /<script type="importmap">/)
			expect(import_map.to_s).to be(:match?, /\{\}/)
		end
		
		it "handles mixed URI types and paths" do
			import_map = subject.build(base: "pages/about/") do |map|
				map.import("react", "https://esm.sh/react@18")
				map.import("preact", "//esm.sh/preact")
				map.import("app", "./app.js")
				map.import("config", "/config.js")
				map.import("vendor/lib", "../vendor/lib.js")
			end
			
			json = import_map.as_json
			
			# URIs unchanged
			expect(json["imports"]["react"]).to be(:include?, "https")
			expect(json["imports"]["preact"]).to be(:start_with?, "//")
			
			# Paths resolved with base
			expect(json["imports"]["app"]).to be(:start_with?, "pages")
		end
		
		it "supports full import map specification" do
			import_map = subject.build do |map|
				map.import("react", "https://esm.sh/react", integrity: "sha384-abc123")
				map.scope("pages/", {"app" => "./pages-app.js"})
			end
			
			html = import_map.to_html
			expect(html.to_s).to be(:match?, /react/)
			expect(html.to_s).to be(:match?, /esm.sh/)
		end
		
		it "supports relative_to method for page-specific import maps" do
			# Global import map with base: "/_components/"
			import_map = subject.build(base: "/_components/") do |map|
				map.import("app", "./app.js")
			end
			
			# For a page at /foo/bar/, create relative base
			page_map = import_map.relative_to("/foo/bar/")
			
			json = page_map.as_json
			expect(json["imports"]["app"]).to be == "../../_components/app.js"
		end
	end
end
