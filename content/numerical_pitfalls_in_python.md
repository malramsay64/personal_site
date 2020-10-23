+++
title= "Numerical Pitfalls in Python"
date = 2020-10-19

draft = true
math = true
highlight = true
+++

The numerical computing capabilities of the Python ecosystem
are incredibly varied and powerful,
with the [Numpy] and [Scipy], and [Pandas] packages
providing high performance, well tested tools.
Additionally there are tools building upon these,
for working with larger datasets,
like [Desk] and [Rapids].
All these tools are fantastic 
when the data is well formed and has the expected values.
It is when we are handling the error cases
that we can run into issues.

During my PhD,
I was using scipy for the analysis of molecular dynamics simulations.
This is effectively throwing a bunch of things in a box
and shaking it up for a while to see what happens.
The novel component of my research
was shaking the box for a really, really, really, long time.
So long that the software I was using ran out of numbers to count.
Having run the simulation,
I then needed to go though the terabytes of data
to calculate values of interest.

The huge benefit of python is the ability to quickly prototype a solution,
working through the ideas on a small scale
that can then be applied to the larger dataset.

TODO: Example of analysis

The molecular dynamics simulations I am running
are effectively a random number generator,
which over the course of a long simulation
will express all possible values.
When performing tests on small numbers of values,
we typically choose the ones that behave as we expect.
However in my simulations,
the values I test only cover a small selection of
the total space of values.
If the program encounters a value
that doesn't encompass the types of values we are expecting,
rather than succeeding,
our hours long calculation fails unexpectedly.

TODO: Example of bad value

When moving from the prototyping
to the production step of the process,
We now have to consider all the places
where our code might fail.
We can no longer go from testing ideas
in 


[Dask]: post/Dask
[Numpy]: post/Numpy
[Pandas]: post/Pandas
[Rapids]: post/Rapids
[Scipy]: post/Scipy
[Desk]: post/Desk
