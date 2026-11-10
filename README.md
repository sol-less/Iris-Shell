<div align="center">
  <h2>Iris Shell</h1>
  This page is dedicated to Iris-Shell, also see <a href="https://github.com/sol-less/Iris-Theme">Iris Theme</a>.
</div>

## About
**Iris Shell** is a simple shell for Hyprland, and one of the core component of the **Iris Ecosystem**.

## Dependencies
```bash
cmake
git
quickshell-git
hyprland
iris-theme # see on github.com/sol-less/Iris-Theme
Ninja
qt6
g++
cava
```

## Installing
> [!NOTE]
> Please make sure you have every Dependencies installed correctly, and Iris-Shell is only available on `git`, not repositories.

### Manual Installation
```bash
cd ~
mkdir -p ~/.config/quickshell
git clone https://github.com/sol-less/Iris-Shell ~/.config/quickshell
cd ~/.config/quickshell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

## Running
Run `qs & disown` after building and installing the build.

> [!IMPORTANT]
> If you see the shell bugging with the small width, try to slide to the left first. If bug still persist, try to restart the shell.
