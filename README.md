![Shader2LCD](https://www.hardkernel.com/main/_Files/prdt/2018/201805/201805120009102637.jpg)

# Shader2LCD
An SDL2 port of oShaderToy that Displays GPU Shaders onto the OGST Gaming Kit LCD 

## Building

```
$ sudo apt-get install libsoil-dev libsdl2-dev
$ git clone https://github.com/AreaScout/Shader2LCD.git
$ cd Shader2LCD
$ make -j7
$ sudo make install
```

## Usage

If you run this application under X11 you should add the DISPLAY prefix or set it as an environment variable

```
$ DISPLAY=:0.0 Shader2LCD shaders/relentless.f.glsl
```

some shaders needs textures, there are three examples that uses unique textures all others you can just choose from texl0.jpg - texl2.jpg
the easiest way to check if a shader needs an texture is to just start it without texture path command line argument, if the display 
stays black you can just add from texl0.jpg to texl2.jpg, except on those three:

```
Shader2LCD shaders/amigademos1.f.glsl textures/texl3.png
Shader2LCD shaders/basicscroll.f.glsl textures/texl3.png
Shader2LCD shaders/sunsurface.f.glsl textures/texl4.png
```
## See also

[ODROID Forum](https://forum.odroid.com/viewtopic.php?f=156&t=30979&p=223798#p223798)

![Shader2LCD2](https://forum.odroid.com/download/file.php?id=7403)


