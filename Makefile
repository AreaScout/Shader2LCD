#Shader2LCD Makefile
CXX = g++
#CXXFLAGS = -mfloat-abi=hard -marm -mtune=cortex-a15.cortex-a7 -mcpu=cortex-a15

ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

ifneq ($(findstring windows,$(MAKECMDGOALS)),)
	CXX = cl
endif

all: Shader2LCD

Shader2LCD: SDL2Shader.cpp
	$(CXX) -o Shader2LCD SDL2Shader.cpp -lSDL2 -lGLESv2 -lSOIL $(CXXFLAGS)
native: SDL2Shader.cpp
	$(CXX) -o Shader2Monitor SDL2Shader.cpp -lSDL2 -lGLESv2 -lSOIL $(CXXFLAGS) -DNATIVE=1
macos: SDL2Shader.cpp
	$(CXX) -o Shader2Monitor SDL2Shader.cpp -lSDL2 -lSOIL -framework OpenGL -I /opt/local/include/ -L /opt/local/lib -DNATIVE=1
windows: SDL2Shader.cpp
	$(CXX) //D "NATIVE=1" //D "NDEBUG" //D "_CONSOLE" //D "_MBCS" //EHsc //sdl- SDL2Shader.cpp //link //OUT:"Shader2Monitor.exe" //SUBSYSTEM:CONSOLE //MACHINE:X64 //FORCE:MULTIPLE //NODEFAULTLIB:libcmt //LTCG //DYNAMICBASE "SDL2-static.lib" "SOIL.lib" "opengl32.lib" "setupapi.lib" "winmm.lib" "imm32.lib" "version.lib" "user32.lib" "gdi32.lib" "advapi32.lib" "shell32.lib" "ole32.lib" "oleaut32.lib"
clean:
	rm -f Shader2LCD Shader2Monitor

install:
	install -d $(PREFIX)/bin/
	install -m 4755 Shader2LCD $(PREFIX)/bin/
	install -m 4755 Shader2Monitor $(PREFIX)/bin/
