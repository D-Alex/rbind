
#ifndef RBIND_ENUMS_HPP
#define RBIND_ENUMS_HPP

enum Test1
{
    VAL1 = 1,
    VAL2,
    VAL3
};

namespace ns_enum
{
    enum Test2
    {
        VAL1 = 1
        VAL2 = VAL1+3,
        VAL3
    };
}

#endif
