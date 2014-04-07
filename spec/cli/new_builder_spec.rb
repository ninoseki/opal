require 'cli/spec_helper'
require 'opal/new_builder'
require 'cli/shared/path_reader_shared'

describe Opal::NewBuilder do
  subject(:builder)     { described_class.new(options, path_reader, compiler_class) }

  let(:filepath)        { 'foo/bar.rb' }
  let(:compiled_source) { "compiled source" }
  let(:compiler_class)  { double('compiler_class') }
  let(:compiler)        { double('compiler', :requires => requires) }
  let(:path_reader)     { double('path reader') }
  let(:source)          { 'file source' }
  let(:requires)        { [] }
  let(:options)         { Hash.new }

  before do
    path_reader.stub(:read) { |path| raise ArgumentError, path }
    path_reader.stub(:read).with(filepath) { source }
    compiler_class.stub(:new).with(source, :file => filepath) do
      double('compiler', :compiled => compiled_source, :requires => requires)
    end
  end

  it 'can build from a string' do
    expect(builder.build_str(source, filepath)).to eq(compiled_source)
  end

  context 'without requires' do
    include_examples :path_reader do
      let(:path) {filepath}
      let(:contents) {"file source"}
    end

    it 'just delegates to Compiler#compile' do
      expect(builder.build(filepath)).to eq("compiled source")
    end
  end

  context 'with requires' do
    let(:requires) { [foo_path, bar_path] }
    let(:foo_path) { 'foo' }
    let(:bar_path) { 'bar' }
    let(:required_foo) { "required foo" }
    let(:required_bar) { "required bar" }
    let(:foo_contents) { "foo source" }
    let(:bar_contents) { "bar source" }

    before do
      path_reader.stub(:read).with(foo_path) { foo_contents }
      path_reader.stub(:read).with(bar_path) { bar_contents }
      foo_compiler = double('compiler', :compiled => required_foo, :requires => [])
      bar_compiler = double('compiler', :compiled => required_bar, :requires => [])
      compiler_class.stub(:new).with(foo_contents, :file => foo_path, :requirable => true) { foo_compiler }
      compiler_class.stub(:new).with(bar_contents, :file => bar_path, :requirable => true) { bar_compiler }
    end

    it 'includes the required files' do
      expect(builder.build(filepath)).to eq([
        required_foo,
        required_bar,
        compiled_source,
      ].join("\n"))
    end

    context 'with prerequired files' do
      let(:prerequired) { [foo_path] }

      it 'skips their compilation' do
        expect(builder.build(filepath, prerequired)).to eq([
          required_bar,
          compiled_source,
        ].join("\n"))
      end
    end

    include_examples :path_reader do
      let(:path) {'foo'}
      let(:contents) { foo_contents }
    end

    context 'including a js' do
      let(:foo_path) { 'foo.js' }

      it 'includes the required files' do
        expect(builder.build(filepath)).to eq([
          foo_contents,
          required_bar,
          compiled_source,
        ].join("\n"))
      end
    end

  end

end