+++
title = "designing_interface_jupyter"
date = 2018-11-14

draft = true

[taxonomies]
tags = ["data science"]
+++

Jupyter is an awesome human computer interface
allowing highly interactive computing.
The tools we use with it
should also adhere to this design language
of being simple for a human to use.

- API design
    - Code is for humans
    - code written to be easy to read, manage, test, update, maintain
    - APIs should be designed to interact with
        - tab completion
        - easy to remember
        - docstrings
        - sensible argument names
        - easy to use types
        - import statements
        - consistency

Some packages are really good at this:

- scikit-learn
    - `.fit()`, `.predict()`
    - Setup of classes, <Shift>-<Tab> for all parameters

- Altair
    - `encode`
    - all charts have the same interface
    - single thing to remember
    - `transform_*` -> discoverability
        - all similar things are named similarly
        - can find functionality logically

For most simple interactions there is no need to dive into the documentation,
all the main interactions are close by.

A decision has to be made about what is important

- naming of functions
    - for the developer/maintainer
    - for the user
- Layout of modules
- `**kwargs`
- error messages

Enabling others to easily build upon what you have written
particularly those with either little programming knowledge
or little language/package specific knowledge.
Able to easily make minor changes to build upon
or adapt your work.

Code is not just for developers,
it is a method of communicating ideas
in the same way we have been using maths,
just on a different level.
Having an interface which is accessible to a non-technical audience
is important for the continued proliferation of programming
as a valuable skill.
