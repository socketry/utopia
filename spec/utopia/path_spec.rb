#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2020, by Samuel Williams.

require 'utopia/path'

RSpec.describe Utopia::Path do
	describe '#load / #dump' do
		subject {"foo/bar/baz"}
		let(:instance) {described_class.load(subject)}
		
		it "loads a string" do
			expect(instance).to be_a described_class
		end
		
		it "dump generates the original string" do
			expect(described_class.dump(instance)).to be == subject
		end
	end
	
	describe '.root' do
		subject(:path) {described_class.root}
		
		it {is_expected.to be == [""]}
		it {is_expected.to_not be_relative}
		it {is_expected.to be_absolute}
		it {is_expected.to have_attributes(local_path: '')}
	end
	
	describe '.create' do
		subject(:path) {described_class.create(value)}
		
		context 'with root path' do
			let(:value) {"/"}
			it {is_expected.to be == ["", ""]}
			it {is_expected.to have_attributes(local_path: '/')}
		end
		
		context 'with nil path' do
			let(:value) {nil}
			it {is_expected.to be_nil}
		end
		
		context 'with symbol path' do
			let(:value) {:symbol}
			it {is_expected.to be == [:symbol]}
			it {is_expected.to be_relative}
			it {is_expected.to_not be_absolute}
		end
		
		context 'with empty string path' do
			let(:value) {""}
			it {is_expected.to be == []}
			it {is_expected.to be_relative}
			it {is_expected.to_not be_absolute}
		end
		
		context 'with relative string path' do
			let(:value) {"foo/bar"}
			it {is_expected.to be == ["foo", "bar"]}
			it {is_expected.to be_relative}
			it {is_expected.to_not be_absolute}
		end
		
		context 'with absolute string path' do
			let(:value) {"/foo/bar"}
			it {is_expected.to be == ["", "foo", "bar"]}
			it {is_expected.to_not be_relative}
			it {is_expected.to be_absolute}
		end
	end
	
	describe '#first' do
		subject(:path) {described_class.create(value)}
		
		context 'with absolute path' do
			let(:value) {'/foo/bar'}
			
			it {is_expected.to have_attributes(first: 'foo')}
		end
		
		context 'with relative path' do
			let(:value) {'foo/bar'}
			
			it {is_expected.to have_attributes(first: 'foo')}
		end
	end
	
	describe '#last' do
		subject(:path) {described_class.create(value)}
		
		context 'with file path' do
			let(:value) {'/foo/bar'}
			
			it {is_expected.to have_attributes(last: 'bar')}
		end
		
		context 'with empty absolute path' do
			let(:value) {'/'}
			
			it {is_expected.to have_attributes(last: '')}
		end
		
		context 'with root path' do
			subject(:path) {described_class.root}
			
			it {is_expected.to have_attributes(last: nil)}
		end
		
		context 'with directory path' do
			let(:value) {'/foo/bar/'}
			
			it {is_expected.to have_attributes(last: '')}
		end
	end
	
	describe '#+' do
		it "can add root path as string" do
			root = Utopia::Path["/invoices/_template"]
			
			expect(root + "/foo/_bar").to be == Utopia::Path["/foo/_bar"]
		end
	end
	
	it "should concatenate absolute paths" do
		root = Utopia::Path["/"]
		
		expect(root).to be_absolute
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
		expect(path.simplify.components).to be == ['', 'foo', 'baz']
		
		path = Utopia::Path["/foo/bar/../baz/./"]
		expect(path.simplify.components).to be == ['', 'foo', 'baz', '']
	end
	
	it "should remove the extension from the basename" do
		path = Utopia::Path["dir/foo.html"]
		
		expect(path.basename).to be == 'foo'
		expect(path.extension).to be == 'html'
	end
	
	describe '#to_directory' do
		subject(:path) {Utopia::Path["foo/bar"]}
		
		it {is_expected.to_not be_directory}
		
		it "should be able to convert into a directory" do
			expect(subject.to_directory).to be_directory
		end
		
		it "should convers to the correct directory" do
			expect(subject.to_directory).to be == Utopia::Path["foo/bar/"]
		end
		
		it "should remain the same directory" do
			directory = subject.to_directory
			expect(directory.to_directory).to be == directory
		end
	end
	it "should start with the given path" do
		path = Utopia::Path["/a/b/c/d/e"]
		
		expect(path.start_with?(path.dirname)).to be true
	end
	
	it "should split at the specified point" do
		path = Utopia::Path["/a/b/c/d/e"]
		
		expect(path.split('c')).to be == [Utopia::Path['/a/b'], Utopia::Path['d/e']]
	end
	
	it "shouldn't be able to modify frozen paths" do
		path = Utopia::Path["dir/foo.html"]
		
		path.freeze
		
		expect(path.frozen?).to be true
		
		expect{path[0] = 'bob'}.to raise_exception(RuntimeError)
	end
	
	it "should give the correct locale" do
		path = Utopia::Path["foo.en"]
		
		expect(path.extension).to be == 'en'
	end
	
	it "should give no locale" do
		path = Utopia::Path["foo"]
		
		expect(path.extension).to be == nil
	end
	
	it "should expand relative paths" do
		root = Utopia::Path['/root']
		path = Utopia::Path["dir/foo.html"]
		
		expect(path.expand(root)).to be == (root + path)
	end
	
	it "shouldn't expand absolute paths" do
		root = Utopia::Path['/root']
		
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
