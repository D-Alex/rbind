#ifndef RBIND_CLASSES_HPP
#define RBIND_CLASSES_HPP


struct TestClass
{
    TestClass(int i1,char c){};
    void setB(bool val){};
    void setF(float &val){};
    void setF2(const float &val){};
    void setD(double &val)const{};

    void setS(TestClass other)const{};
    void setS2(TestClass *other)const{};
    void setS3(TestClass **other)const{};
    void setS4(TestClass &other)const{};
    void setS5(const TestClass &other)const{};
    void setS6(const TestClass *other)const{};

    TestClass getS(){};
    TestClass* getS2(){};
    TestClass& getS3(){};
    const TestClass& getS4(){};

    bool bfield;
    int ifield;
};

#endif
