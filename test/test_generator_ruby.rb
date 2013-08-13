require 'minitest/spec'
require 'rbind'

MiniTest::Unit.autorun
describe Rbind::GeneratorRuby do
    before do
    end

    after do
    end

    describe "normalize_method_name" do
        it "must remove the cprefix" do
            result = Rbind::GeneratorRuby.normalize_method_name("rbind__test123")
            assert_equal("_test123",result)
        end

        it "must change upper case letters to lower case and add a _ if there is none" do
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_Cv")
            assert_equal("cv",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv")
            assert_equal("cv",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_FeatureDetector")
            assert_equal("cv_feature_detector",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_FeatureDetector__create")
            assert_equal("cv_feature_detector__create",result)
        end

        it "must preserve __ in a method name" do
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_FeatureDetector__create")
            assert_equal("cv_feature_detector__create",result)
        end

        it "must regard upper case letters in a sequence as block " do
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_CV_TEST")
            assert_equal("cv_test",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_CV_TEST_get_Test")
            assert_equal("cv_test_get_test",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_RNG")
            assert_equal("cv_rng",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_RNG_gaussian")
            assert_equal("cv_rng_gaussian",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_KDTree")
            assert_equal("cv_kd_tree",result)
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_cv_RNG2")
            assert_equal("cv_rng2",result)
        end

        it "must regard upper case letters in a sequence as block " do
            result = Rbind::GeneratorRuby.normalize_method_name("rbind_CV_TEST")
            assert_equal("cv_test",result)
        end
    end

    describe "normalize_default_value" do
        it "must remove f from float values" do
            p = Rbind::RParameter.new("p1",Rbind::RDataType.new("float"),"1.0f")
            result = Rbind::GeneratorRuby.normalize_default_value(p)
            assert_equal("1.0",result)
        end

        it "must add zero to double values if missing" do
            p = Rbind::RParameter.new("p1",Rbind::RDataType.new("double"),"1.")
            result = Rbind::GeneratorRuby.normalize_default_value(p)
            assert_equal("1.0",result)
        end

        it "must add zero to double values if missing" do
            p = Rbind::RParameter.new("p1",Rbind::RDataType.new("double"),"1.")
            result = Rbind::GeneratorRuby.normalize_default_value(p)
            assert_equal("1.0",result)
        end
    end
end
