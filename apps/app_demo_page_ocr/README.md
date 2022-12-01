# Page Ocr asdSetup


## [Install poetry](https://python-poetry.org/docs/master/#installing-with-the-official-installer)

Not recommended to use pip to do the install as it will also install Poetry’s dependencies which might cause conflicts with other packages.

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

- Use poetry to install all the dependencies from `pyproject.toml`

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

## Notes if using pyenv

- Install pyenv and set the version you want before installing poetry

```bash
brew install pyenv
pyenv install 3.7.13
pyenv local 3.7.13
curl -sSL https://install.python-poetry.org | python3 -
```

`

- Tell poetry to use 3.10 (not sure if you have to do this if you did the above)
  - Based on [Stackoverflow Poetry doesn't use the correct version of Python](https://stackoverflow.com/a/59810606/38841)

```bash
poetry env use 3.10
```

Then do the

```bash
poetry install
```

to install all the deplendencies.

You can see what poetry is up to with:

```bash
> poetry debug

Poetry
Version: 1.1.13
Python:  3.7.13

Virtualenv
Python:         3.7.13
Implementation: CPython
Path:           /Users/rahulsalla/Library/Caches/pypoetry/virtualenvs/app-demo-page-ocr-7E-CUEjg-py3.7
Valid:          True

System
Platform: darwin
OS:       posix
Python:   /Users/rahulsalla/.pyenv/versions/3.7.13
```

If the Virtualenv is not right (not the same Python version) things are screwed up. I deleted the `/Users/rberger/Library/Caches/pypoetry/virtualenvs` and then I could redo the `poetry install`
