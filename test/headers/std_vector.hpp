
#ifndef RBIND_STD_HPP
#define RBIND_STD_HPP

#include <vector>
#include <stdlib.h>

#define BLA 21
const int bla = 202;

class Laser
{
    private:
        std::vector<float> private_var;

    public:
        class MStruct{};

        std::vector<int> public_var;

        // basic types
        void setValues(std::vector<int> ints){};
        void setValues1(std::vector<int> &ints){};
        void setValues2(std::vector<int> *ints){};
        void setValues3(std::vector<int> **ints){};

        void setValues4(std::vector<unsigned int> uints){};
        void setValues5(std::vector<unsigned int*> uints){};
        void setValues6(std::vector<unsigned int**> uints){};

        void setValues4(const std::vector<unsigned int> uints){};
        void setValues5(const std::vector<unsigned int*> &uints){};

        // complex types
        void setValues7(std::vector<MStruct> objs){};
        void setValues8(std::vector<MStruct*> objs){};
        void setValues9(std::vector<MStruct**> objs){};
};

#endif
