+++
title = "Altair in Anger"
date = "2018-03-12"

draft = true
math = true
highlight = true
+++

[Altair][altair-viz] is a relatively new addition to the python visualisation landscape,
with the goal of making it simpler to investigate your data.
I think that Altair really nails this goal,
currently being my preferred plotting library 
(and I have tried a lot of them of late).
However, while Altair makes it really simple to get started and explore a visualisation,
it is more difficult to take the figure and make it publication ready,
primarily because of a lack of good documentation.

Firstly what do I mean by 'publication ready'.
I view this as having the figure in a state that requires little additional understanding,
so details including;
- properly labelled axes,
- axes scaled correctly, and
- popper formatting of axes labels.

To understand the formatting that is taking place here,
it is important to understand that Altair is 
a wrapper around Vega-Lite.
It takes your python code and converts it into a json string
adhering to the Vega-Lite specification.
Because of this the python code we are using
closely matches the resulting json string.
So to work out how to format something in Altair
it is often easier to look up the comprehensive [Vega-Lite Documentation][vega-lite docs]
and guess at the python code (which is basically the same).

Setting Up Altair
-----------------

All the examples listed here are for the development release of Altair 2.0,
however most of the same recipes will apply to the 1.3 release.
Installation of the development release of Altair can be done using the command
```sh
$ pip install git+git://github.com/altair-viz/altair
```

Getting altair workin


Labelling Axes
--------------

This is a complicated question with no single answer.
Both the `X` and `Y` axes have labels set through the `axis` parameter,

