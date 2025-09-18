mkdir build
cd build
cmake ..
make neuroflight
picotool load -f ./neuroflight.uf2
