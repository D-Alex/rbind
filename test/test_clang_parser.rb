require 'minitest/spec'
require 'rbind'

MiniTest::Unit.autorun
describe Rbind::ClangParser do
    before do
    end

    after do
    end

    describe "parse" do

        it "must parse enums" do
            next
            file = File.join(File.dirname(__FILE__),'headers','enums.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file
            assert parser.Test1
            assert_equal({"VAL1" => "1", "VAL2" => nil ,"VAL3" => nil},parser.Test1.values)

            assert parser.ns_enum.Test2
            assert_equal({"VAL1" => "1", "VAL2" => "VAL1+3" ,"VAL3" => nil},parser.ns_enum.Test2.values)
        end

        it "must parse constants" do
            next
            file = File.join(File.dirname(__FILE__),'headers','constants.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file
            assert parser.INT_CONST
            assert_equal "11", parser.INT_CONST.default_value
            assert_equal "int", parser.INT_CONST.type.full_name
            assert_equal "12", parser.UINT_CONST.default_value
            assert_equal "uint", parser.UINT_CONST.type.full_name

            assert_equal "11", parser.ns_const.INT_CONST.default_value
            assert_equal "int", parser.ns_const.INT_CONST.type.full_name
            assert_equal "12", parser.ns_const.UINT_CONST.default_value
            assert_equal "uint", parser.ns_const.UINT_CONST.type.full_name
        end

        it "must parse c functions" do
            next
            file = File.join(File.dirname(__FILE__),'headers','cfunctions.h')
            parser = Rbind::ClangParser.new
            parser.parse file

            assert parser.test1
            assert_equal "int",parser.test1.parameters[0].type.full_name
            assert_equal "void",parser.test1.return_type.full_name

            assert parser.test2
            assert_equal "int",parser.test2.parameters[0].type.full_name
            assert_equal "int",parser.test2.return_type.full_name
        end

        it "must parse structs" do
            file = File.join(File.dirname(__FILE__),'headers','structs.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file

            assert_equal "TestStruct::TestStruct(int i1, char c)", parser.TestStruct.TestStruct.signature
            assert_equal "void TestStruct::setB(bool val)", parser.TestStruct.setB.signature
            assert_equal "void TestStruct::setF(float& val)", parser.TestStruct.setF.signature
            assert_equal "void TestStruct::setF2(const float& val)", parser.TestStruct.setF2.signature
            assert_equal "void TestStruct::setD(double& val)", parser.TestStruct.setD.signature
            assert_equal "void TestStruct::setS(TestStruct other)", parser.TestStruct.setS.signature
            assert_equal "void TestStruct::setS2(TestStruct* other)", parser.TestStruct.setS2.signature
            assert_equal "void TestStruct::setS3(TestStruct** other)", parser.TestStruct.setS3.signature
            assert_equal "void TestStruct::setS4(TestStruct& other)", parser.TestStruct.setS4.signature
            assert_equal "void TestStruct::setS5(const TestStruct& other)", parser.TestStruct.setS5.signature
            assert_equal "TestStruct TestStruct::getS()", parser.TestStruct.getS.signature
            assert_equal "TestStruct* TestStruct::getS2()", parser.TestStruct.getS2.signature
            assert_equal "TestStruct& TestStruct::getS3()", parser.TestStruct.getS3.signature
            assert_equal "const TestStruct& TestStruct::getS4()", parser.TestStruct.getS4.signature
            assert parser.TestStruct.attribute("bfield")
            assert parser.TestStruct.attribute("ifield")
            #TODO test csignature
        end

        it "must parse classes" do
            next
            file = File.join(File.dirname(__FILE__),'headers','classes.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file

            assert_equal "void TestClass::TestClass(int i1, char c)", parser.TestClass.TestClass.signature
            assert_equal "void TestClass::setB(bool val)", parser.TestClass.setB.signature
            assert_equal "void TestClass::setF(float& val)", parser.TestClass.setF.signature
            assert_equal "void TestClass::setF2(const float& val)", parser.TestClass.setF2.signature
            assert_equal "void TestClass::setD(double& val)", parser.TestClass.setD.signature
            assert_equal "TestClass TestClass::setS(TestClass other)", parser.TestClass.setS.signature
            assert_equal "TestClass TestClass::setS2(TestClass* other)", parser.TestClass.setS2.signature
            assert_equal "TestClass TestClass::setS3(TestClass** other)", parser.TestClass.setS3.signature
            assert_equal "TestClass TestClass::setS4(TestClass& other)", parser.TestClass.setS4.signature
            assert_equal "TestClass TestClass::setS5(const TestClass& other)", parser.TestClass.setS5.signature
            assert_equal "TestClass TestClass::setS6(const TestClass* other)", parser.TestClass.setS6.signature
            assert_equal "TestClass TestClass::getS()", parser.TestClass.getS.signature
            assert_equal "TestClass* TestClass::getS2()", parser.TestClass.getS2.signature
            assert_equal "TestClass& TestClass::getS3()", parser.TestClass.getS3.signature
            assert_equal "const TestClass& TestClass::getS4()", parser.TestClass.getS4.signature
            assert parser.TestClass.attribute("bfield")
            assert parser.TestClass.attribute("ifield")
        end

        it "must parse std vector types" do
            next
            file = File.join(File.dirname(__FILE__),'headers','std_vector.hpp')
            parser = Rbind::ClangParser.new
            parser.parse file

            assert_equal "void TestClass::setValues(std::vector<int> ints)", parser.TestClass.setValues.signature
            assert_equal "void TestClass::setValues1(std::vector<int>& ints)", parser.TestClass.setValues1.signature
            assert_equal "void TestClass::setValues2(const std::vector<uint> uints)", parser.TestClass.setValues2.signature
            assert_equal "void TestClass::setValues3(const std::vector<uint*>& uints)", parser.TestClass.setValues3.signature
            assert_equal "void TestClass::setValues4(std::vector<TestClass::MStruct> objs)", parser.TestClass.setValues4.signature
            assert_equal "void TestClass::setValues5(std::vector<TestClass::MStruct*> objs)", parser.TestClass.setValues5.signature
            assert_equal "void TestClass::setValues6(std::vector<TestClass::MStruct**> objs)", parser.TestClass.setValues6.signature
            assert_equal "std::vector<float>& TestClass::getFloats()", parser.TestClass.getFloats.signature
        end

        it "must parse std string types" do
            file = File.join(File.dirname(__FILE__),'headers','std_string.hpp')
            parser = Rbind::ClangParser.new
            parser.add_type(Rbind::StdString.new("std::string",parser))
            parser.type_alias["basic_string"] = parser.std.string
            parser.parse file

            assert_equal "void TestClass::setValues(std::string str)", parser.TestClass.setValues.signature
            assert_equal "void TestClass::setValues1(std::string& str)", parser.TestClass.setValues1.signature
            assert_equal "void TestClass::setValues2(std::string* str)", parser.TestClass.setValues2.signature
            assert_equal "std::string TestClass::getString()", parser.TestClass.getString.signature
            assert_equal "std::string& TestClass::getString2()", parser.TestClass.getString2.signature
            assert_equal "std::string* TestClass::getString3()", parser.TestClass.getString3.signature
        end

        # this is not fully supported yet
        #it "must parse templates" do
        #    file = File.join(File.dirname(__FILE__),'headers','templates.hpp')
        #    parser = Rbind::ClangParser.new
        #    parser.parse file
        #    #assert_equal("_test123",result)
        #end
    end
end
