+++
title = "A Workflow for the Computational Sciences"
date = 2018-06-30

draft = true

[taxonomies]
tags = ["research", "jupyter"]
+++

Jupyter notebooks have drastically changed how I do science,
putting the emphasis on real time interaction with data and code.

While this shift is primarily for the better,
with the amazing communication and sharing capabilities
Jupyter notebooks provide.
There are detractors.

- why I hate jupyter notebooks -> talk at jupytercon

How do you take the amazing productivity that jupyter offers
while retaining good software development practices.

## Idea Development

An idea
- no code yet
- develop code interactively in jupyter

- build up each cell to do something useful
    - playground aspect of the notebooks
    - easy to regenerate previous state
    - easy to introspect state -> debugging
    - visualisations

- particularly when the first step is computationally expensive
    - reading dataset
    - downloading stuff

As you work out what each cell is actually doing,
build the cell into a function
- generalisation
- what variables are required
- default values


## Solidification of Idea

*I need this in multiple notebooks*

- Developed a function to do a thing in the notebook
- likely that function is useful in other notebooks
- testing function operates as expected
- Abstraction

A notebook tells a story
- the details of loading and cleaning some data into a notebook are probably not part of
  that story
- what does the reader really need to know about
- Are the many lines of code to format a figure nicely important?

This is the movement of these functions to a .py file to be imported into the notebook
- not having to bother the reader with these details
- allow all the tooling developed for python projects to run
    - black -> code formatting
    - mypy -> static type checking
    - pylint -> static analysis
    - pytest -> runtime testing

Importing into project

```python
import sys

sys.path.append('../src')
import utils.load_dataset
```

## Package Creation

*I need this in multiple projects*

- The realisation that the tools you are using are more widely applicable
    - new projects
    - they are now really general
    - separate development from project

The project now becomes a dependency
- now everyone else can use it
- simple to install

- Natural progression from a src file in a project
    - now just relocating to it's own project

- PyPA user guide
- Conda user guide

## Conclusion

Jupyter notebooks are amazing for interactive computing
They are also a great storytelling tool
Use the right tool for the job
    - makes your life easier
