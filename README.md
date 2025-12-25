# Portable Python Maker

A standalone PowerShell script that creates portable Python environments with all dependencies bundled.

**No Python installation required** - just run the script on any Windows machine.

## Quick Start

```powershell
.\make_portable_python.ps1 -Requirements requirements.txt
```

## Features

- **Standalone** - No Python needed to run this tool
- Downloads official Python embeddable package (3.9, 3.10, 3.11, 3.12)
- Automatically sets up pip
- Installs all packages from requirements.txt
- Supports local module imports (current working directory added to path)
- Output is fully portable - copy to any Windows PC

## Usage

```
.\make_portable_python.ps1 -Requirements <path> [-PythonVersion <ver>] [-OutputDir <path>]
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `-Requirements` | Path to requirements.txt | required |
| `-PythonVersion` | 3.9, 3.10, 3.11, 3.12 | 3.11 |
| `-OutputDir` | Output directory | .\portable_python |

### Examples

```powershell
# Basic usage
.\make_portable_python.ps1 -Requirements requirements.txt

# Python 3.12
.\make_portable_python.ps1 -Requirements requirements.txt -PythonVersion 3.12

# Custom output directory
.\make_portable_python.ps1 -Requirements requirements.txt -OutputDir .\my_env

# All options
.\make_portable_python.ps1 -Requirements requirements.txt -PythonVersion 3.10 -OutputDir .\my_env
```

## Output Structure

```
portable_python/
├── python.exe
├── python311.dll
├── Lib/
│   └── site-packages/
│       └── sitecustomize.py
└── ...
```

## Using the Portable Python

Copy the output folder to any Windows machine:

```batch
.\portable_python\python.exe                   :: Python interpreter
.\portable_python\python.exe script.py         :: Run a script
.\portable_python\python.exe -m pip install X  :: Install more packages
.\portable_python\python.exe -m pip list       :: List installed packages
```

## Requirements

- Windows x64
- PowerShell 5.1+
- Internet connection

## Libraries & Licenses

| Library | Source | License |
|---------|--------|---------|
| Python Embeddable | [python.org](https://www.python.org/ftp/python/) | PSF License |
| pip | [pypa/pip](https://github.com/pypa/pip) | MIT |
| get-pip.py | [pypa/get-pip](https://github.com/pypa/get-pip) | MIT |

## License

MIT
