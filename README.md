# Ganlib (Version5.0.6_ev1910)

Initialize cmake project

    $ mkdir -p cmake-build-debug
	$ cd cmake-build-debug && cmake -DCMAKE_BUILD_TYPE=Debug .. && cd ..

Build/rebuild all targets

	$ cmake --build cmake-build-debug --target all
	
Check Ganlib binary

    $ make tests
