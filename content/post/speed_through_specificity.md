+++
title = "Speed Through Specificity"
date = "2017-12-10"
draft = True

highlight = true
+++

One of the main complaints of Python is it's lack of speed.
Jake van der Plass has an excellent [blogpost][why python is slow]
explaining the technical details of what occurs in a function call.
The basic premise of this post is that in being a dynamically typed language
python code is written for a general case,
regardless of the intention of the  developer.
A simple `add` function

    def add(a: int, b: int) -> int:
        return a + b

is written to handle the addition of any two python objects
not just the `int` types that we intend.

When writing in statically typed C we write code for highly specific cases.
The same add function in C code will _only_ work with with integer values.

    int add(int a, int b){
        return a + b
    }

The specificity of the C code allows it to forgo many of the checks
the python code has to perform,
resulting in code that appears to run faster
because it is doing much less work.

This idea of specificity to improve performance
is not just present in the programming languages we use,
it is also also in the code we use and write.

A

<!--So I don't really know where I am going here,
I have an excellent thesis
with what I think is an excellent introduction.

What is required now is a concrete example,
a simple to explain case where the specificity of code
makes a huge impact on the running time.
Ideally this would be an example that is simple
and will run slowly on C++.

Essentially the idea that Python isn't slow,
rather code to handle the general case is.
-->


[why python is slow]:
