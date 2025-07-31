![Shader2Monitor](https://forum.odroid.com/download/file.php?id=14567)

# Shader2Monitor
An SDL2 port of oShaderToy that Displays GPU Shaders onto your TV or Monitor

## Building

In order to compile on win32 you need a copy of SDL2 and libSOIL

[libSOIL-x64-dev](https://github.com/AreaScout/Shader2LCD/raw/dep-libs/libSOIL-x64-dev.zip)  
[SDL2-x64-dev](https://github.com/AreaScout/Shader2LCD/raw/dep-libs/sdl2-x64-dev.zip)  

For simplicity extract the libraries and include files to your Windows Kit SDK directory:

__Include__ files -> `C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um`  
__Libraries__ -> `C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22000.0\um\x64`  

__10.0.22000.0__ is the current Windows SDK version, you may have a different one

After this the include directory should contain SDL2 and SOIL folders
```
C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um\SOIL
C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um\SDL2
```
You need another header file in order to be able to compile this tool, go to ->  
https://registry.khronos.org/EGL/api/KHR/khrplatform.h and save the file into a folder called KHR like this:
```
C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um\KHR
```

Open up Visual Studio Command Prompt for x64, change the directory to your souce code location and issue this command

```
cl /D "NATIVE=1" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /EHsc /sdl- SDL2Shader.cpp /link /OUT:"Shader2Monitor.exe" /SUBSYSTEM:CONSOLE /MACHINE:X64 /FORCE:MULTIPLE /NODEFAULTLIB:libcmt /LTCG /DYNAMICBASE "SDL2-static.lib" "SOIL.lib" "opengl32.lib" "setupapi.lib" "winmm.lib" "imm32.lib" "version.lib" "user32.lib" "gdi32.lib" "advapi32.lib" "shell32.lib" "ole32.lib" "oleaut32.lib"
```

Or if you do have msys2 installed, open up Visual Studio Command Prompt x64, change to msys2 directory and issue this command

```
msys2_shell.cmd -use-full-path -ucrt64
```

From the now open msys2 shell change directory to Shader2LCD and type make

```
cd /d/Shader2LCD
make windows
````

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
