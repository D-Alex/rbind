#ifndef RBIND_CLASSES_HPP
#define RBIND_CLASSES_HPP


class TestClass
{
public:
    bool public_field;

    void public_function();

    class PublicClass
    {
    };

private:
    bool private_field;

    void private_function();

    class PrivateClass
    {
    };

protected:
    bool protected_field;

    void protected_function();

    class ProtectedClass
    {
    };
};

#endif
