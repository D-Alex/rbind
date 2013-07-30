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

        it "must generate a correct signature for complex methods" do
            @root.add_type Rbind::RClass.new("MStruct")
            @root.add_type Rbind::StdVector.new("std::vector")

            op = @root.add_operation("testOperation") do |op|
                op.add_parameter("para") do |p|
                    p.type = type("MStruct").to_ptr
                end
                op.add_parameter("para2") do |p|
                    p.type = type("MStruct")
                end
                op.return_type = int
            end
            assert_equal "int testOperation(MStruct* para, MStruct para2)", op.to_s

            op = @root.add_operation("testOperation2") do |op|
                op.add_parameter("para") do |p|
                    p.type = type("std::vector<MStruct*>").to_ptr.to_const
                    p.default_value = "0"
                end
            end
            assert_equal "void testOperation2(const std::vector<MStruct*>* para = 0)", op.to_s
        end
    end

    describe "csignature" do
        it "must generate a correct csignature for simple methods" do
            op = @root.add_operation("testOperation")
            assert_equal "void rbind_testOperation()", op.csignature

            op = @root.add_operation("testOperation2") do |op|
                op.return_type = int
            end
            assert_equal "int rbind_testOperation2()", op.csignature

            op = @root.add_operation("testOperation3") do |op|
                op.add_parameter("para") do |p|
                    p.type = int
                end
            end
            assert_equal "void rbind_testOperation3(int para)", op.csignature

            op = @root.add_operation("testOperation4") do |op|
                op.add_parameter("para") do |p|
                    p.type = int.to_ptr
                end
                op.return_type = char.to_ref
            end
            assert_equal "char& rbind_testOperation4(int* para)", op.csignature
        end

        it "must generate a correct csignature for complex methods" do
            @root.add_type Rbind::RClass.new("MStruct")
            @root.add_type Rbind::StdVector.new("std::vector")

            op = @root.add_operation("testOperation") do |op|
                op.add_parameter("para") do |p|
                    p.type = type("MStruct").to_ptr
                end
                op.add_parameter("para2") do |p|
                    p.type = type("MStruct")
                end
                op.return_type = int
            end
            assert_equal "int rbind_testOperation(rbind_MStruct* para, rbind_MStruct* para2)", op.csignature

            op = @root.add_operation("testOperation2") do |op|
                op.add_parameter("para") do |p|
                    p.type = type("std::vector<MStruct*>").to_ptr.to_const
                    p.default_value = "0"
                end
            end
            assert_equal "void rbind_testOperation2(const rbind_std_vector_MStruct_ptr* para = 0)", op.csignature

            op = @root.add_operation("testOperation3") do |op|
                op.add_parameter("para") do |p|
                    p.type = type("std::vector<MStruct*>").to_ref.to_const
                    p.default_value = "0"
                end
            end
            assert_equal "void rbind_testOperation3(const rbind_std_vector_MStruct_ptr* para = 0)", op.csignature

            op = @root.add_operation("testOperation4") do |op|
                op.return_type = type("std::vector<MStruct*>").to_ref
            end
            assert_equal "rbind_std_vector_MStruct_ptr* rbind_testOperation4()", op.csignature
        end

        it "must enumerate overloaded methods" do
            # rbind does not care if two methods have the exact same signature
            op = @root.add_operation("testOperation")
            assert_equal "void rbind_testOperation()", op.csignature

            op = @root.add_operation("testOperation")
            assert_equal "void rbind_testOperation2()", op.csignature

            op = @root.add_operation("testOperation")
            assert_equal "void rbind_testOperation3()", op.csignature

            op = @root.add_operation("testOperation3")
            assert_equal "void rbind_testOperation31()", op.csignature
        end
    end
end

