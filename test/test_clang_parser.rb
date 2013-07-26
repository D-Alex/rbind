require 'minitest/spec'
require 'rbind'

MiniTest::Unit.autorun
describe Rbind::ClangParser do
    before do
    end

    after do
    end

    describe "parse" do
        it "must parse std vector types" do
            file = File.join(File.dirname(__FILE__),'headers','std_vector.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file
            #assert_equal("_test123",result)
        end
    end
end
