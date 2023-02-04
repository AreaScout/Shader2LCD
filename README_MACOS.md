![Shader2Monitor](https://forum.odroid.com/download/file.php?id=14567)

# Shader2Monitor
An SDL2 port of oShaderToy that Displays GPU Shaders onto your TV or Monitor

## Building

In order to compile on macOS you need brew to install library dependencies (https://brew.sh/)
```
$ brew install sdl2 git gcc
$ brew tap zmarcantel/libsoil
$ brew install libsoil
$ git clone https://github.com/AreaScout/Shader2LCD.git
$ cd Shader2LCD
$ make macos
```

## Usage

```
$ Shader2Monitor shaders/relentless.f.glsl
```

The Shader2LCD tool was made to display shaders onto the OGST Gaming Kit LCD, while building with native option
it is made to test GPU capabilties for OpenGL ES and DRM/X11/Wayland driver across platforms (if supported) like
Linux/Windows/macOS

```
./Shader2Monitor shaders/dragoneye2.glsl
./Shader2Monitor shaders/onewarp.glsl
./Shader2Monitor shaders/generations4k.glsl
./Shader2Monitor shaders/heartfelt.f.glsl textures/texl5.jpg
./Shader2Monitor shaders/flower.f.glsl
./Shader2Monitor shaders/clover.f.glsl
./Shader2Monitor shaders/plasma.f.glsl
./Shader2Monitor shaders/plasmawaves.f.glsl
./Shader2Monitor shaders/relieftunnel.f.glsl textures/texl0.jpg
```
## See also

[ODROID Forum](https://forum.odroid.com/viewtopic.php?f=201&t=40962)

![Shader2Monitor](https://forum.odroid.com/download/file.php?id=7403)