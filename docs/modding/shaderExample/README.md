------------
This is an example shader for getting started with shaders.
If you don't know what a shader is, it's a way to modify how the way the game is rendered to make visual effects.
For example, a vhs can be made using a shader.

<img src="https://images.gamebanana.com/img/ss/tools/63a08481d308c.jpg" width="750"/>

Surprising right?
If you want more showcases, Shadertoy has fantastic shaders to look at. (Its literally entire worlds omfg) https://www.shadertoy.com/
## Please note that Shadertoy uses its own rendering and shader engine, so you will have to modify some shader code if you wanna port a simple Shadertoy shader.
### Some shaders are not portable at all due to their complexity, but Shadertoy shaders support is coming soon.

A shader can be applied into:
- Sprites
- Cameras
- `FlxG.game`

In order to make a shader, you need these following files:
- Frag File (fragment source of the shader)
- HScript File (shader coding)
- OPTIONAL: Vert File (vertex source of the shader)

Add the files into the following folders:
```
assets/

    data/
     | YOURSHADERSCRIPT.extension

    shaders/
     | YOURSHADERFRAG.frag
     | YOURSHADERVERT.vert
```

For more information about HScript or to get an available extension for HScript, Scripting.md explains everything about it.