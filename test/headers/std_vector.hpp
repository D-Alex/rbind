
#ifndef RBIND_STD_HPP
#define RBIND_STD_HPP

#include <vector>
#include <stdlib.h>

class TestClass
{
    private:
        std::vector<float> private_var;

    public:
        class MStruct{};
        std::vector<int> public_var;

        // basic types
        void setValues(std::vector<int> ints){};
        void setValues1(std::vector<int> &ints){};

        void setValues2(const std::vector<unsigned int> uints){};
        void setValues3(const std::vector<unsigned int*> &uints){};

        void setValues4(std::vector<MStruct> objs){};
        void setValues5(std::vector<MStruct*> objs){};
        void setValues6(std::vector<MStruct**> objs){};

        std::vector<float> &getFloats(){ return private_var;};
};

#endif
