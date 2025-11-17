#include "hello_node.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void HelloNode::_bind_methods() {
    // No methods needed for this simple example
}

HelloNode::HelloNode() {
}

HelloNode::~HelloNode() {
}

void HelloNode::_ready() {
    UtilityFunctions::print("Hello world from C++!");
}
