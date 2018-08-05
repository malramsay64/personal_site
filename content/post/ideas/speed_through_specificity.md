+++
title = "Speed Through Specificity"
date = "2017-12-10"
draft = true

highlight = true
+++

A common complaint about the Python programming language is that it is slow, often with reference to
some benchmark comparing various tasks. There are a number of articles explaining why Python is
slow, [Jake van der Plass] and [Anthony Shaw] are just two excellent examples. While I don't
disagree with any of the points raised in these articles, I think they miss an important aspect of
performance---specificity. Python is a general purpose language, used for nearly everything from
embedded devices in uPython to distributed processing of petabytes of data.

Speed comes through specificity for a task. Even when working with C or C++, which are generally
regarded to be the gold standard for performance, there is still an argument to be made for
increased performance through hand optimised assembly. Writing assembly, which is the stream of
instructions that the CPU interprets to do it's work, can result in faster code than a compiler if
you know what you doing. Only nearly no-one actually writes assembly because we want our
applications to work on different processor architectures and to take advantage of the features of
newer CPUs like out-of-order execution.[^1] Instead of writing the fastest possible code for a
particular processor we provide hints to the compiler to help it optimise performance, for the best
of both compatibility and performance.

The specificity of the hardware is also an important factor in performance. A CPU itself is a
general purpose tool being adaptable to many different workflows. To really understand what *fast*
is we can look to specialised hardware like GPUs, FPGAs, or ASICs. Graphics Processing Units (GPUs)
are designed for performing the same operation on large quantities of data at the same time, whether
that is working out the colour of each pixel on a display, or the values at each point of a large
matrix. GPUs are phenomenally good at these tasks because they are designed at the hardware level
for these workflows. An alternate method of hardware specific to a problem is a Field Programmable
Gate Array (FPGA), where the programming refers to arranging the circuits on the chip to perform
some processing. This allows for phenomenal processing capability, and is used in places like signal
processing and Mars rovers. While the circuits FPGAs can be rearranged to solve different problems,
or hardware updates, a Application-Specific Integrated Circuit (ASIC) is a piece of silicon for a
single task. A common use of ASICs is video decoding, enabling you to watch YouTube on your phone.
The progression of hardware from CPU to GPU to FPGA to ASIC represents a trade-off at each point of
performance for specificity.

Specificity doesn't just refer to the low level details of processor architecture. Python is a
dynamically typed language, allowing variables to change type during execution. A byproduct of
dynamic typing is that types need to be evaluated for each operation. Should we want to add the
values of two lists together like in the example below, each time the code reaches the line `result
= i + j` it has to evaluate the type of both `i` and `j` to know how to perform the addition
operation. With large numbers of values, the type evaluation takes far longer than the addition
operation.

```python
list1 = [1, 2, 3]
list2 = [4, 5, 6]
list_result = []
for i, j in zip(list1, list2):
    result = i + j
    list_result.append(result)
```

A key concept in optimising numerical python code is limiting the number of type evaluations, with
the canonical method being [NumPy]. Instead of having a list which can contain many different types,
NumPy uses arrays which only contain a single type, which means the type only needs to be evaluated
once for the entire array. Other optimisation techniques for numerical python, namely Cython and
Rumba, operate in a very similar way; reducing the calculation to a limited range of types evaluated
once.

Sitting above all the levels of flexibility mentioned above is the specificity of the application. A
program designed specifically to solve a particular problem is able to make assumptions and
optimisations specific to that problem. The general purpose tool has to optimise for everything,
which means optimising for nothing. Python is a general purpose programming language; not optimised
for numerical computing, for the web, for command line scripts, or any other use case. However, the
amazing community has developed tools to optimise performance for almost every use case. Where speed
is paramount, use a tool designed specifically for the desired application.


[^1]: I guess you could also consider this a [bug...][meltdown]

[Jake van der Plass]: https://jakevdp.github.io/blog/2014/05/09/why-python-is-slow/
[Anthony Shaw]: https://hackernoon.com/why-is-python-so-slow-e5074b6fe55b
[meltdown]: https://meltdownattack.com/

