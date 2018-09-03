+++
title = "Reproducability in Science"
date = "2018-01-03"
authors = ["Malcolm Ramsay"]
tags = []

draft = true
math = true
highlight = true
+++

One of the key reasons we use version numbers,
particularly in programming,
is for repeatability.
We know that some code we wrote will
run on python 3.6 so we can tell
anyone who wants to run the code to use python 3.6.
Except today when we write code we typically
don't just have a python version,
there is a collection of packages
each with it's own version number
that need to be installed for the code we wrote to run.
There are a number of constructs to help us manage
these often byzantine dependency trees.
With `pip` we have dependency management
in the `setup.py` file,
`requirements.txt`, and
more recently `Pipfile` through `pipenv`.
While `conda` can manage dependencies through
the build file `meta.yaml`, and
also using an `environment.yml` file.

Each of these methods has
their own strengths and weaknesses,
`conda` excels at deploying packages with
compiled dependencies,
while `pip` works on any python version and
has a truly enormous library of packages.
The reason that all these options exist
is that they don't cover all use cases,
with each having various strengths and weaknesses.

When packaging content
there are two types of dependencies,
the dependencies required to build the package,
and the dependencies for the installation of the package.
