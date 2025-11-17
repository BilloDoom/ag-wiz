#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class HelloNode : public Node {
    GDCLASS(HelloNode, Node)

protected:
    static void _bind_methods();

public:
    HelloNode();
    ~HelloNode();

    void _ready() override;
};

}
