
#ifndef RBIND_TEMPLATES_HPP
#define RBIND_TEMPLATES_HPP

template<typename T> class TemplateType
{
    public:
        T field;
};

class Test
{
    public:
        void setType(TemplateType<int> type){};
};

#endif
