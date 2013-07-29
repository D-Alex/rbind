require 'minitest/spec'
require 'rbind'

MiniTest::Unit.autorun
describe Rbind::RParameter do
    before do
        @root = Rbind::RNamespace.new
        @root.add_default_types
        @root.add_type Rbind::StdVector.new("std::vector")
    end

    after do
    end

    describe "signature" do
        it "must generate a correct signature for simple types" do
            parameter = Rbind::RParameter.new("para",@root.int)
            assert_equal "int para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int)
            parameter.default_value = "123"
            assert_equal "int para = 123", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_ref)
            assert_equal "int& para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_ref.to_const)
            assert_equal "const int& para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_ptr)
            parameter.default_value = "NULL"
            assert_equal "int* para = NULL", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_ptr.to_ptr)
            parameter.default_value = "NULL"
            assert_equal "int** para = NULL", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_ptr.to_ptr.to_const)
            parameter.default_value = "NULL"
            assert_equal "const int** para = NULL", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.int.to_const.to_ptr.to_ptr)
            parameter.default_value = "NULL"
            assert_equal "const int** para = NULL", parameter.to_s
        end

        it "must generate a correct signature for template types" do
            parameter = Rbind::RParameter.new("para",@root.type("std::vector<int>"))
            assert_equal "std::vector<int> para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.type("std::vector<int>").to_ref)
            assert_equal "std::vector<int>& para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.type("std::vector<int>").to_ref.to_const)
            assert_equal "const std::vector<int>& para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.type("std::vector<int>").to_ptr)
            assert_equal "std::vector<int>* para", parameter.to_s

            parameter = Rbind::RParameter.new("para",@root.type("std::vector<const unsigned int*>").to_ptr.to_const)
            assert_equal "const std::vector<uint*>* para", parameter.to_s
        end

    end

    describe "csignature" do
        it "must generate a correct signature for simple types" do
            parameter = Rbind::RParameter.new("para",@root.int)
            assert_equal "int para", parameter.csignature
        end
    end
end

