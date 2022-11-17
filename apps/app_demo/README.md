# Api Handler Setup
# Minor change - Add featureasasdasdasd
# asdFix for featureasdasdsasdasasddasdasd
## Install Python3 if not already installed

### If using pyenv (suggested)

- Install pyenv and set the version you want before installing poetry

```bash
brew install pyenv
pyenv install 3.8.13
pyenv global 3.8.13
curl -sSL https://install.python-poetry.org | python3 -
```

## [Install poetry](https://python-poetry.org/docs/master/#installing-with-the-official-installer)

Not recommended to use pip to do the install as it will also install Poetry’s dependencies which might cause conflicts with other packages.

```bash
curl -sSL https://install.python-poetry.org | python -
```

You can see what poetry is up to with (details will be different):

```bash
> poetry debug

Poetry
Version: 1.1.13
Python:  3.8.13

Virtualenv
Python:         3.8.13
Implementation: CPython
Path:           /Users/rahulsalla/Library/Caches/pypoetry/virtualenvs/app-nnMCBjWd-py3.8
Valid:          True

System
Platform: darwin
OS:       posix
Python:   /Users/rahulsalla/.pyenv/versions/3.8.13
```

### Install Poetry Plugins

#### [Dynamic versioning plugin for Poetry](https://github.com/mtkennerly/poetry-dynamic-versioning)

``` bash
poetry self add "poetry-dynamic-versioning[plugin]"
```
### Use poetry to install all the dependencies from `pyproject.toml`

```bash
poetry install
```

## Development

```bash
poetry shell
```

Starts a new terminal shell that uses the virtual environment. If you run python from within this shell, you’ll have access to all of your dependencies (including development dependencies). It’s useful if you do REPL-based development.

## Testing

```bash
poetry run pytest
```

Runs a Python package from within the virtual environment. This is the way to run tests.

## Deploy to lambda

Refer this [wiki](https://github.com/Informed/techno-core/wiki/Deploying-apps-to-different-env-using-tags)
