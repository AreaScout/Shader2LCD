#Shader2LCD Makefile
CXX = g++
#CXXFLAGS = -mfloat-abi=hard -marm -mtune=cortex-a15.cortex-a7 -mcpu=cortex-a15

ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

all: Shader2LCD

Shader2LCD: SDL2Shader.cpp
	$(CXX) -o Shader2LCD SDL2Shader.cpp -lSDL2 -lGLESv2 -lSOIL $(CXXFLAGS)
native: SDL2Shader.cpp
	$(CXX) -o Shader2Monitor SDL2Shader.cpp -lSDL2 -lGLESv2 -lSOIL $(CXXFLAGS) -DNATIVE=1
macos: SDL2Shader.cpp
	$(CXX) -o Shader2Monitor SDL2Shader.cpp -lSDL2 -framework OpenGL -I /opt/local/include/ -L /opt/local/lib -DNATIVE=1
clean:
	rm -f Shader2LCD Shader2Monitor

install:
	install -d $(PREFIX)/bin/
	install -m 4755 Shader2LCD $(PREFIX)/bin/
	install -m 4755 Shader2Monitor $(PREFIX)/bin/
