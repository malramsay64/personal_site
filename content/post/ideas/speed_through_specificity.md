+++
title = "Speed Through Specificity"
date = "2017-12-10"
draft = true

highlight = true
+++

One of the main complaints of Python is it's lack of speed. Jake van der Plass has an excellent
[blogpost][why python is slow] explaining the technical details of what occurs in a function call.
The basic premise of this post is that in being a dynamically typed language python code is written
for a general case, regardless of the intention of the  developer.

- There are a number of excellent articles explaining why python is slow
    - links to them
- While I don't disagree with them I think there is an essence of speed which is not captured.
    - Python is 'slow' because it is a generalist language

- Speed in computing comes from specificity.
    - Look at C, which is generally regarded as the smallest overhead
    - There was originally pushback -> why not use assembly
    - even for BLAS operations we still use hand optimised assembly
    - highly specific code
- Only we don't want specificity
    - Sorry your code doesn't work on the latest processors, you have to rewrite it
    - We want to port our desktop app to mobile, you are going to have to take your x86 assembly and
    rewrite it for ARM.
- Why not FPGAs or ASICs

- ML libraries have completely different implementations for CPU and GPU

- Specificity doesn't just come from the processor the code is running on.
    - We also have type specificity
    - in most programming languages you can define an addition operator for any types
        - python allows for duck typing
            - functions which are designed to take many different classes 
                - this is all functions in python whether we want it or not
            - In the cases where we do want specificity there are techniques to deal with it
                - numpy finds the type information once for all elements in an array
                - Cython accepts a single type in a function
                    - have to rewrite for different types (yes there are templates)
                - Numba compiles the code for specific type assuming there will be more
        - it has to work out what the types are
        - many 

- Above all we have the specificity of application
    - A small application that can optimise one thing
    - Large application that has to handle everything
    - Python is not optimised for numerical computing, for the web, for command line scripts; it is
    a general purpose programming language. Python is slower than Y for some specific scenario is
    primarily that Y is more optimised for that task.

[why python is slow]: https://jakevdp.github.io/blog/2014/05/09/why-python-is-slow/
