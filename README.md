# Algorithm Wizard

### Required Software
- **CMake** (3.20 or higher)
- **Python 3.8+**

### Required Python Packages
```bash
pip install pybind11
```

## Initial Setup

```bash
git clone "https://github.com/BilloDoom/ag-wiz.git"
git submodule update --init --recursive
```

## Building the Extension

### Build All Platforms
```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

### Build Output Location

- **Windows:** `build/bin/Release/algorithm_wizard.dll`
- **Linux:** `build/bin/libalgorithm_wizard.so`
- **macOS:** `build/bin/libalgorithm_wizard.dylib`

## Rebuilding After Changes

For relese or debug
```bash
cmake --build . --config Release
```
```bash
cmake --build . --config Debug
```

### Full Rebuild
```bash
rm -rf build

mkdir build
cd build
cmake ..
cmake --build . --config Release
```