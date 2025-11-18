#ifndef DATA_BUFFER_HPP
#define DATA_BUFFER_HPP

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class DataBuffer : public RefCounted {
    GDCLASS(DataBuffer, RefCounted)

private:
    Array data_array;
    Dictionary metadata;

protected:
    static void _bind_methods();

public:
    DataBuffer();
    ~DataBuffer();

    // Data management
    void clear();
    void push_value(const Variant& value);
    Variant get_value(int index) const;
    int size() const;
    Array get_all_data() const;
    void set_data(const Array& data);

    // Metadata management (for passing additional info from Python)
    void set_metadata(const String& key, const Variant& value);
    Variant get_metadata(const String& key) const;
    Dictionary get_all_metadata() const;
};

} // namespace godot

#endif // DATA_BUFFER_HPP
