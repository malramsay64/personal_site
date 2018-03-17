+++
title = "Altair in Anger"
date = "2018-03-17"

draft = true
math = true
highlight = true
+++

Calling the current python visualisation landscape fragmented would probably be an understatement
since itself requires a [visualisation][jakevdp pycon vis] to even begin to comprehend.
You are probably reasonably happy with the visualisation tool you currently use
and the various trade-offs that come with it,
so why should you care about [another tool][xkcd competing standards] in Altair.

About a year ago I was using Matplotlib for all my figures,
which enabled me to create anything I wanted
usually with a stackoverflow answer giving me a working example to adapt.
Problem was, basically everything required a stackoverflow post
making the process of building these figures slow and tedious.
Around the same time I was getting fed up with Matplotlib,
I found Jake VanderPlas' PyCon talk on [The Python Visualisation Landscape][jakevdp pycon vis]
which has since acted as somewhat of a list of achievements to unlock.

### Altair 1.X

Somewhat naturally the first package I looked at for improving my visualisation workflow was
[Altair][altair 1.3] which was a 1.X release.
At the time I thought it was great for simple figures,
however at the time my data was not formatted appropriately
to make the most of what Altair could offer.
Another sticking point with Altair was working out how to customise figures,
I was used to just putting what I wanted to do into Google
which returned the appropriate stackoverflow answer
on the first page of results.
With Altair being a new package,
this type of documentation didn't exist
so I never really worked out how to customise the figure.
The most frustrating of these issues was the axis labels
using the SI Prefix for large numbers
i.e. 1M for $1 \times 10^6$  and 1n for $1 \times 10^{-9}$
which I never actually worked out at the time.

The final issue I had with Altair was the lack of interactivity.
I was in the early stages of data investigation
which required both a high level overview of the trends
while also being able to look at smaller regions in more detail.

### Bokeh

So pretty, Panny, and Zoomy.
With an emphasis on interactivity,
[Bokeh][bokeh] was just what I was looking for to investigate data on different scales.
Additionally the [Bokeh server][bokeh server] is amazing for creating a web interface
to perform standard analyses on large volumes of data
like making sure a simulation is running properly.

Despite having excellent interactive visualisations,
bokeh is lacking in the same way as Matplotlib,
it takes a long time to create the figures.
While there was a start on a high level plotting interface in the form of bkcharts,
it is unmaintained and directs to Holoviews.

### Holoviews

Like Altair, [Holoviews][holoviews] is a declarative plotting interface,
formulated around the idea of rather than describing your data in constructing the figure,
you describe the data upon creating a dataset
which can then very simply be expressed in a visualisation.
Rather than being a library that actually creates the figure,
Holoviews performs the reasoning about the dataset
and passing that to Bokeh, Matplotlib, or Flatly
for the actual rendering.
This was a huge draw of Holoviews,
I could generate interactive visualisations in bokeh,
change the output to Matplotlib and have a figure for publication.
Turns out that in practice this is not so simple,
with modifications to plot style parameters
being different between the different output formats.

The drawback of having this special annotated data object
is that you lose all the flexibility of having a pandas DataFrame
and the vast array of operations that allows.
I care about this because my field of science 
has a long history of researchers taking some quantities,
combining them in a way which gives 
an easily describable temperature dependence
and calling it an astounding discovery.
Which led me back to Altair,
this time version 2.0.

### Altair 2.0

Why Altair again?
When I first tried Altair I was approaching it from Matplotlib,
with it's extensive documentation
in the form of the technical reference and also the many how to guides.
While this time I was approaching it from Bokeh and Holoviews,
both of which are relatively new and having teething problems.
I had become much better at problem solving and navigating technical reference materials.
Additionally, I made the connection that since Altair is based on the Vega-Lite specification,
maybe I should have a look at the [Vega-Lite documentation][vega-lite docs].
This was really helpful because they are well written, extensive and 
easily navigable technical reference.

It was reading this documentation that I finally understood the `transform_*` functions in Altair.
These are a set of functions that perform computations on the dataset 
to generate the resulting figure.
An example of this is a canonical Altair example figure, the histogram.
```
import altair as alt
from vega_datasets import data

movies = data.movies.url

chart = alt.Chart(movies).mark_bar().encode(
    alt.X("IMDB_Rating:Q", bin=True),
    y='count(*):Q',
)
```
![Movies dataset represented as histogram on the IMDB_Rating][images/altair_hist.png]

In this example the aggregation is a 


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

This is a complicated question with no single answer.
Both the `X` and `Y` axes have labels set through the `axis` parameter,

[jakevdp pycon vis]: https://youtu.be/FytuB8nFHPQ?t=3m53s
[xkcd competing standards]: https://xkcd.com/927/
[altiar 1.3]:
[bokeh]:
[bokeh server]:
[holoviews]: https://holoviews.org
[vega-lite docs]: https://vega.github.io/vega-lite/docs/
