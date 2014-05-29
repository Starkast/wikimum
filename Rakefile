require 'rake/testtask'

Dir['tasks/*.rake'].each { |f| load f }

task default: [:test]
task test: ['test:unit']

namespace(:test) do
  Rake::TestTask.new(:unit) do |t|
    t.pattern = "test/unit/*_test.rb"
  end
end
