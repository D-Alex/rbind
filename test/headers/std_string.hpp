
#ifndef RBIND_STD_STRING_HPP
#define RBIND_STD_STRING_HPP

#include <string>
#include <stdlib.h>

class TestClass
{
    private:
        std::string private_var;

    public:
        std::string public_var;

        // basic types
        void setValues(std::string str){};
        void setValues1(std::string &str){};
        void setValues2(std::string *str){};

        std::string getString(){ return private_var;};
        std::string &getString2(){ return private_var;};
        std::string *getString3(){ return &private_var;};
};

#endif
