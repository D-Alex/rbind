#ifndef RBIND_STRUCTS_HPP
#define RBIND_STRUCTS_HPP


struct TestStruct
{
    TestStruct(int i1,char c){};
    void setB(bool val){};
    void setF(float &val){};
    void setF2(const float &val){};
    void setD(double &val)const{};

    void setS(TestStruct other)const{};
    void setS2(TestStruct *other)const{};
    void setS3(TestStruct **other)const{};
    void setS4(TestStruct &other)const{};
    void setS5(const TestStruct &other)const{};

    TestStruct getS(){};
    TestStruct* getS2(){};
    TestStruct& getS3(){};
    const TestStruct& getS4(){};

    bool bfield;
    int ifield;
};

typedef struct
{
    int i;
}TestStruct2;


#endif
