require 'tool/equality_map'

describe Tool::EqualityMap do
  before { GC.disable }
  after { GC.enable }

  describe :fetch do
    subject { Tool::EqualityMap.new }
    specify 'with existing entry' do
      next if subject.is_a? Hash
      subject.fetch("foo") { "foo" }
      result = subject.fetch("foo") { "bar" }
      expect(result).to be == "foo"
    end

    specify 'with GC-removed entry' do
      next if subject.is_a? Hash
      subject.fetch("foo") { "foo" }
      expect(subject.map).to receive(:[]).and_return(nil)
      result = subject.fetch("foo") { "bar" }
      expect(result).to be == "bar"
    end
  end
end
