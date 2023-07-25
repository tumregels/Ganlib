# Ganlib (Version5.0.6_ev1910)

Initialize cmake project

    $ mkdir -p build
	$ cd build && cmake -DCMAKE_BUILD_TYPE=Debug .. && cd ..

Build/rebuild all targets

	$ cmake --build build --target all
	
Check Ganlib binary

    $ make tests

To check the *.so file content

    nm -D --defined-only /path/to/libGanlib.so

To check the *.a file content

    ar -t /path/to/libGanlib.a
