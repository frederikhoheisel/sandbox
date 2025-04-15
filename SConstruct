#!/usr/bin/env python
import os
import sys



# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

opts = Variables([], ARGUMENTS)
opts.Add(PathVariable('k4a_include_path', 'Pfad zu Azure Kinect SDK Includes', 'C:/Program Files/Azure Kinect SDK v1.4.2/sdk/include'))
opts.Add(PathVariable('k4a_lib_path', 'Pfad zu Azure Kinect SDK Libs', 'C:/Program Files/Azure Kinect SDK v1.4.2/sdk/windows-desktop/amd64/release/lib'))

env = SConscript("godot-cpp/SConstruct")

opts.Update(env)

# Azure Kinect SDK-Pfade - passe diese an deine Installation an
k4a_include_path = env['k4a_include_path']
k4a_lib_path = env['k4a_lib_path']

# Include-Pfade hinzufügen
env.Append(CPPPATH=[
    '.',
    k4a_include_path
])

# Bibliothekspfade und Bibliotheken hinzufügen
env.Append(LIBPATH=[k4a_lib_path])
env.Append(LIBS=['k4a'])

# tweak this if you want to use different folders, or more folders, to store your source code in.
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "demo/bin/libkinect.{}.{}.framework/libkinect.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "demo/bin/libkinect.{}.{}.simulator.a".format(env["platform"], env["target"]),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "demo/bin/libkinect.{}.{}.a".format(env["platform"], env["target"]),
            source=sources,
        )
else:
    library = env.SharedLibrary(
        "demo/bin/libkinect{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
