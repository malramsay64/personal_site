+++
title= "Numerical Pitfalls in Python"
date = 2020-10-19

draft = true

[taxonomies]
tags = ["python"]
+++

The numerical computing capabilities of the Python ecosystem are incredibly powerful,
with the [Numpy] and [Scipy], and [Pandas] packages
providing high performance, well tested tools.
Additionally, tools like [Dask] and [Rapids]
build upon these foundational packages supporting larger datasets.
All these tools are excellent 
when the data is well formed and contains the expected values.
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
We could come up with the following solution
for fitting line of best fit to a region of a curve,
returning both the best parameters and the standard deviation.

```python
import scipy

def linear(x, m, b):
    """Define the linear relationship y=mx+b."""
    return m * x + b

def fit_linear_region(x, y):
    """Fit a linear curve where the points lie within a region of 2D space."""
    # Select a region of points
    region = np.logical_and(2 < y, y < 50)
    # Perform the curve fitting only using the linear region
    popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
    # Calculate the standard deviation of the fit parameters
    perr = 2 * np.sqrt(np.diag(pcov))
    # Returns the optimal curve and associated error
    return popt, perr
```

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

There are a number of different failure modes we have to consider in this example.
The first is not having enough values
for which to fit to our data.

```python
>>> scipy.optimise.curve_fit(linear, [1], [1])
----------------------------------------------------------------------
TypeError                            Traceback (most recent call last)
...
TypeError: Improper input: N=2 must not exceed M=1
```

We can handle this error condition using a `try` block,
catching the `TypeError`.

When moving from the prototyping
to the production step of the process,
We now have to consider all the places
where our code might fail.
We can no longer go from testing ideas
straight to deploying to production.

## Exploring the Solution Space

This is a problem that programmers face
in a wide range of disciplines.
Accordingly,
there are a range of approaches
that look to address the issue
of ensuring our code doesn't unexpectedly fail.

### Catch-all

One of the possible approaches is to capture all exceptions with a naked `except` block,
that is

```python
try:
    popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
except:
    return np.nan, np.nan
```

While this approach handles all possible issues that could occur,
it is also heavy handed in its application.
The general goal is to prevent unexpected errors
in a particular configuration halting the execution of our program.
However, in capturing all possible errors,
we also capture errors that can be problematic. 
For example a `KeyboardInterrupt`,
meaning that rather than `<Ctrl>-c` stopping the execution of the program,
it instead describes a curve that doesn't fit.
This could also be hugely problematic with a `FileNotFoundError`,
where instead of getting an error at the start of the program
we have to work out why our file is empty after it ran.

While the idea of the catch-all is useful,
it is pushing the problems from those identified when the program runs
to issues in subsequent steps
which become even more difficult to solve.

### Hypothesis

The issue with the catch-all case
is that we are overly broad 
in the types of exceptions that we catch.
What if we could determine all the types of exceptions
that we would expect,
and only catch that subset.
This is the approach that you would take
if you kept adding the exceptions that come up
to the list of those caught and handled.
As an alternative to finding the exceptions that arise manually,
[hypothesis] is a package for enhancing test suites
using a directed random search to probe for values that may cause problems.
Hypothesis works to test the values likely to cause issues,
small values, large values, zero, NaN, and Inf
ensuring they are handled appropriately.
Hypothesis can be considered a tool that allows us
to understand the assumptions we make about our datasets.

Working with hypothesis requires a fair amount of setup,
working with a test framework like pytest.
Additionally, as a property testing framework,
rather than testing specific values
we instead need to test properties.
In this particular case,
the property we want to test is that our function
is not going to unexpectedly raise an exception,
which can be achieved by running the function
as shown in the code snippet below.

```python
from hypothesis import given
from hypothesis.extra.numpy import arrays

@given(x=arrays(dtype=float, shape=10), y=arrays(dtype=float, shape=10))
def test_example(x, y):
    fit_linear_region(x, y)
```

In this example,
we are using hypothesis to generate two numpy arrays, `x` and `y`,
with each having having a shape of 10 elements.
In this code snippet
we are making clear some assumptions that we have made about our data.
Firstly that we are expecting floating point values,
being the `dtype` that we are generating.
The second is that the `shape` of both `x` and `y` is equal.
One of the fantastic advantages of hypothesis
is that it brings to light these occasionally hidden assumptions
about the inputs to our functions.

Using hypothesis to generate inputs to our function
helps us find some additional errors that can occur.
We get a `ValueError`, when there are no points
that lie within our specified range,
a `TypeError` when there is only a single value within our range,
and an `OptimizeWarning` when scipy is unable to find
and appropriate line of best fit.
This results in the following `fit_linear_region` function.

```python
def fit_linear_region(x, y):
    """Fit a linear curve where the points lie within a region of 2D space."""
    # Select a region of points
    region = np.logical_and(2 < y, y < 50)
    # Perform the curve fitting only using the linear region
    try:
        popt, pcov = scipy.optimize.curve_fit(linear, x[region], y[region])
    except (ValueError, TypeError, scipy.optimize.OptimizeWarning) as e:
        return np.nan, np.nan
    # Calculate the standard deviation of the fit parameters
    perr = 2 * np.sqrt(np.diag(pcov))
    # Returns the optimal curve and associated error
    return popt, perr
```

While using hypothesis allows us to easily find
some of the failure modes of the functions that we use,
it is another thing to learn how to use.
What if there was a simpler solution
that made use of existing tools.

### Documentation

The documentation for a function
is something that is regularly referred to,
so it makes sense that this a fantastic place
for information about the exceptions a function will raise.
The scipy docs already include this information
for some of the functions, including [curve fit][curve_fit_docs].
Within the **Raises** section,
it notes there are three different exceptions the function can raise,
a `ValueError`, `RuntimeError`, or `OptimizeWarning`.
This also demonstrates a limitation of using hypothesis,
it won't always find all the possible errors from a function,
where we previously hadn't noted the `RuntimeError`.
However on the flip side, 
the `TypeError` we found when using is currently missing
from the documentation as a possible exception.
This is a limitation of the documentation approach,
the exception comes from a function called by `curve_fit`,
propagating beyond the initial call site,
making it difficult to notice.
The documentation approach is also prone to degrading over time,
as the code gets updated and changed,
the documentation has to be changed and updated alongside it,
and this can mean in multiple unrelated locations.
If we represent the possible errors in code, 
then there is no longer a problem with
the documentation going out of date.

### Rust

One of the excellent parts of the Rust programming language,
is the comprehensive type system,
which includes the `Result` type.
In a similar way to exceptions within Python,
the `Result` type within Rust
is a way of stating that something has gone wrong.
The big difference however,
is that in Rust you *must* explicitly handle the error,
which in the simplest case is equivalent to a python exception,
stopping the execution of the program and exiting.

The key enhancement with the Rust approach
is that because there there is now a record of every place 
an error could halt the execution of the program.
When prototyping on the sample datasets,
halting the execution of the program using `.unwrap()`
where there is an error is completely fine,
and exactly what we had with our exceptions in Python.
When moving to a more complex analysis pipeline,
where failure is not a good option,
it is relatively simple to find all instances of `.unwrap()`
and find appropriate ways to handle those error conditions.

When using type checking within python code,
we have a similar approach to handle `None` values,
being the `Optional` type.
The type checker requires that the `None` value
is handled when working with the `Optional` type,
and so we have to either explicitly handle the `None`
or propagate it to a calling function to handle 
through a `return` statement.
In principle, supporting a `Result` type within python
like exists within Rust is possible, however,
what makes the type so useful within Rust
is that it *must* be handled,
a guarantee that can't be enforced within python.

## Conclusion

One of the key principles of python
is the ease of getting started.
Advanced parts of the language,
can be ignored until they are required.
This is not just for those learning the language,
but also the projects that we start.
When working with long running processes,
exception handling becomes an important part of the development,
however, there appears to be no clear way
to find all ways an exception could be raised.
This makes the development process a continually iterative one,
run the code until you find an exception,
handle the exception and start again,
a process that is not ideal.

[Dask]: https://dask.org/
[Numpy]: https://numpy.org/
[Pandas]: https://pandas.pydata.org/
[Rapids]: https://rapids.ai/
[Scipy]: https://www.scipy.org/
[curve_fit_docs]: https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.curve_fit.html
