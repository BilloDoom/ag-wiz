#include "data_buffer.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void DataBuffer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("clear"), &DataBuffer::clear);
    ClassDB::bind_method(D_METHOD("push_value", "value"), &DataBuffer::push_value);
    ClassDB::bind_method(D_METHOD("get_value", "index"), &DataBuffer::get_value);
    ClassDB::bind_method(D_METHOD("size"), &DataBuffer::size);
    ClassDB::bind_method(D_METHOD("get_all_data"), &DataBuffer::get_all_data);
    ClassDB::bind_method(D_METHOD("set_data", "data"), &DataBuffer::set_data);

    ClassDB::bind_method(D_METHOD("set_metadata", "key", "value"), &DataBuffer::set_metadata);
    ClassDB::bind_method(D_METHOD("get_metadata", "key"), &DataBuffer::get_metadata);
    ClassDB::bind_method(D_METHOD("get_all_metadata"), &DataBuffer::get_all_metadata);
}

DataBuffer::DataBuffer() {
    UtilityFunctions::print("DataBuffer created");
}

DataBuffer::~DataBuffer() {
    UtilityFunctions::print("DataBuffer destroyed");
}

void DataBuffer::clear() {
    data_array.clear();
    metadata.clear();
}

void DataBuffer::push_value(const Variant& value) {
    data_array.push_back(value);
}

Variant DataBuffer::get_value(int index) const {
    if (index >= 0 && index < data_array.size()) {
        return data_array[index];
    }
    UtilityFunctions::printerr("DataBuffer: Index out of bounds: ", index);
    return Variant();
}

int DataBuffer::size() const {
    return data_array.size();
}

Array DataBuffer::get_all_data() const {
    return data_array;
}

void DataBuffer::set_data(const Array& data) {
    data_array = data;
}

void DataBuffer::set_metadata(const String& key, const Variant& value) {
    metadata[key] = value;
}

Variant DataBuffer::get_metadata(const String& key) const {
    if (metadata.has(key)) {
        return metadata[key];
    }
    return Variant();
}

Dictionary DataBuffer::get_all_metadata() const {
    return metadata;
}

} // namespace godot
