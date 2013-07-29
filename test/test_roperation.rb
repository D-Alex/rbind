require 'minitest/spec'
require 'rbind'

MiniTest::Unit.autorun
describe Rbind::ROperation do
    before do
        @root = Rbind::RNamespace.new
        @root.add_default_types
    end

    after do
    end

    describe "signature" do
        it "must generate a correct signature for simple methods" do
            op = @root.add_operation("testOperation")
            assert_equal "void testOperation()", op.to_s

            op = @root.add_operation("testOperation2") do |op|
                op.return_type = int
            end
            assert_equal "int testOperation2()", op.to_s

            op = @root.add_operation("testOperation3") do |op|
                op.add_parameter("para") do |p|
                    p.type = int
                end
            end
            assert_equal "void testOperation3(int para)", op.to_s

            op = @root.add_operation("testOperation4") do |op|
                op.add_parameter("para") do |p|
                    p.type = int.to_ptr
                end
                op.return_type = char.to_ref
            end
            assert_equal "char& testOperation4(int* para)", op.to_s
        end
    end
end

