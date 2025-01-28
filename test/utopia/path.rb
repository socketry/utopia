# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2025, by Samuel Williams.

require "utopia/path"

describe Utopia::Path do
	with "#load / #dump" do
		let(:string) {"foo/bar/baz"}
		let(:path) {subject.load(string)}
		
		it "loads a string" do
			expect(path).to be_a(subject)
		end
		
		it "dump generates the original string" do
			expect(subject.dump(path)).to be == string
		end
	end
	
	with ".root" do
		let(:path) {subject.root}
		
		it "is a root path" do
			expect(path).to be == [""]
			expect(path).not.to be(:relative?)
			expect(path).to be(:absolute?)
			expect(path).to have_attributes(local_path: be == "")
		end
	end
	
	with ".create" do
		let(:path) {subject.create(value)}
		
		with value: "/" do
			it "is a root path" do
				expect(path).to be == ["", ""]
				expect(path).not.to be(:relative?)
				expect(path).to be(:absolute?)
				expect(path).to have_attributes(local_path: be == "/")
			end
		end
		
		with value: nil do
			it "is nil path" do
				expect(path).to be_nil
			end
		end
		
		with value: :symbol do
			it "is symbol path" do
				expect(path).to be == [:symbol]
				expect(path).to be(:relative?)
				expect(path).not.to be(:absolute?)
				expect(path).to have_attributes(local_path: be == "symbol")
			end
		end
		
		with value: "" do
			it "is empty path" do
				expect(path).to be == []
				expect(path).to be(:relative?)
				expect(path).not.to be(:absolute?)
				expect(path).to have_attributes(local_path: be == "")
			end
		end
		
		with value: "foo/bar" do
			it "is a relative path" do
				expect(path).to be == ["foo", "bar"]
				expect(path).to be(:relative?)
				expect(path).not.to be(:absolute?)
				expect(path).to have_attributes(local_path: be == "foo/bar")
			end
		end
		
		with value: "/foo/bar" do
			it "is an absolute path" do
				expect(path).to be == ["", "foo", "bar"]
				expect(path).not.to be(:relative?)
				expect(path).to be(:absolute?)
				expect(path).to have_attributes(local_path: be == "/foo/bar")
			end
		end
	end
	
	with "#first" do
		let(:path) {subject.create(value)}
		
		with value: "/foo/bar" do
			it "is a root path" do
				expect(path.first).to be == "foo"
			end
		end
		
		with value: "foo/bar" do
			it "is a relative path" do
				expect(path.first).to be == "foo"
			end
		end
	end
	
	with "#last" do
		let(:path) {subject.create(value)}
		
		with value: "/foo/bar" do
			it "has a last component" do
				expect(path.last).to be == "bar"
			end
		end
		
		with value: "/" do
			it "can extract the last path component from an empty absolute path" do
				expect(path.last).to be == ""
			end
		end
		
		with "root path" do
			let(:path) {subject.root}
			
			it "can extract the last path component from a a root path" do
				expect(path.last).to be == nil
			end
		end
		
		with value: "/foo/bar" do
			it "can extract the last path component from an absolute path" do
				expect(path.last).to be == "bar"
			end
		end
	end
	
	with "#+" do
		it "can add root path as string" do
			root = Utopia::Path["/invoices/_template"]
			
			expect(root + "/foo/_bar").to be == Utopia::Path["/foo/_bar"]
		end
	end
	
	it "should concatenate absolute paths" do
		root = Utopia::Path["/"]
		
		expect(root).to be(:absolute?) 
		expect(root + Utopia::Path["foo/bar"]).to be == Utopia::Path["/foo/bar"]
	end
	
	it "should compute all descendant paths" do
		root = Utopia::Path["/foo/bar"]
		
		descendants = root.descend.to_a
		
		expect(descendants[0].components).to be == [""]
		expect(descendants[1].components).to be == ["", "foo"]
		expect(descendants[2].components).to be == ["", "foo", "bar"]
		
		ascendants = root.ascend.to_a
		
		expect(descendants.reverse).to be == ascendants
	end
	
	it "should be able to remove relative path entries" do
		path = Utopia::Path["/foo/bar/../baz/."]
		expect(path.simplify.components).to be == ["", "foo", "baz"]
		
		path = Utopia::Path["/foo/bar/../baz/./"]
		expect(path.simplify.components).to be == ["", "foo", "baz", ""]
	end
	
	it "should remove the extension from the basename" do
		path = Utopia::Path["dir/foo.html"]
		
		expect(path.basename).to be == "foo"
		expect(path.extension).to be == "html"
	end
	
	with "#to_directory" do
		let(:path) {Utopia::Path["foo/bar"]}
		
		it "can determine if it is a directory" do
			expect(path).not.to be(:directory?)
		end
		
		it "should be able to convert into a directory" do
			expect(path.to_directory).to be(:directory?) 
		end
		
		it "should convers to the correct directory" do
			expect(path.to_directory).to be == Utopia::Path["foo/bar/"]
		end
		
		it "should remain the same directory" do
			directory = path.to_directory
			expect(directory.to_directory).to be == directory
		end
	end
	it "should start with the given path" do
		path = Utopia::Path["/a/b/c/d/e"]
		
		expect(path.start_with?(path.dirname)).to be == true
	end
	
	it "should split at the specified point" do
		path = Utopia::Path["/a/b/c/d/e"]
		
		expect(path.split("c")).to be == [Utopia::Path["/a/b"], Utopia::Path["d/e"]]
	end
	
	it "shouldn't be able to modify frozen paths" do
		path = Utopia::Path["dir/foo.html"]
		
		path.freeze
		
		expect(path.frozen?).to be == true
		
		expect{path[0] = "bob"}.to raise_exception(RuntimeError)
	end
	
	it "should give the correct locale" do
		path = Utopia::Path["foo.en"]
		
		expect(path.extension).to be == "en"
	end
	
	it "should give no locale" do
		path = Utopia::Path["foo"]
		
		expect(path.extension).to be == nil
	end
	
	it "should expand relative paths" do
		root = Utopia::Path["/root"]
		path = Utopia::Path["dir/foo.html"]
		
		expect(path.expand(root)).to be == (root + path)
	end
	
	it "shouldn't expand absolute paths" do
		root = Utopia::Path["/root"]
		
		expect(root.expand(root)).to be == root
	end
	
	it "should give the shortest path for outer paths" do
		input = Utopia::Path.create("/a/b/c/index")
		output = Utopia::Path.create("/a/b/c/d/e/")
		
		short = input.shortest_path(output)
		
		expect(short.components).to be == ["..", "..", "index"]
		
		expect((output + short).simplify).to be == input
	end
	
	it "should give the shortest path for inner paths" do
		input = Utopia::Path.create("/a/b/c/index")
		output = Utopia::Path.create("/a/")
		
		short = input.shortest_path(output)
		
		expect(short.components).to be == ["b", "c", "index"]
		
		expect((output + short).simplify).to be == input
	end
end
