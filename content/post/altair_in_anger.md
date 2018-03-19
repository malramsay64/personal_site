+++
title = "Altair in Anger"
date = "2018-03-17"

draft = false
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
and passing that to Bokeh, Matplotlib, or Plotly
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
This is particularly helpful because this documentation is currently more extensive than
that for [Altair][altair docs].
t

a well written, extensive and
easily navigable technical reference.

It was reading this documentation that I finally understood the transform functions in Altair.
These are a set of functions that perform computations on the input dataset to generate the resulting figure.
This allows me to have a single canonical dataset,
with data transformations like ratios of two quantities tied to the figure,
rather than following awkwardly named variables around.

An example of why this is useful is demonstrated using the cars dataset as an example.
To make the data in the dataset useful for the majority of the world's population,
it is possible to define the required unit conversions within the figure.

```python
import altair as alt
from vega_datasets import data

cars = data.cars()

chart = alt.Chart(cars).mark_circle().transform_filter(
    alt.expr.datum.Miles_per_Gallon > 0
).transform_calculate(
    'Fuel Economy (L/100 km)', '235.2 / datum.Miles_per_Gallon'
).transform_calculate(
    'Weight (kg)', 'datum.Weight_in_lbs * 0.45'
)
chart.encode(
    x='Fuel Economy (L/100 km):Q',
    y='Weight (kg):Q',
    size='Acceleration:Q'
)
```
![Fuel economy (L/100km) vs weight (kg) from the cars dataset.](/static/img/altair-cars-metric.svg)

For my workflow this is hugely powerful,
allowing me to have a master dataset for all figures
from which I can calculate additional values as required.

This computing of values,
also extends to the computation of histograms,
complete with shortened notation.
Using the chart object from above it is possible to easily create a histogram

```python
chart.mark_bar().encode(
    x=alt.X('Fuel Economy (L/100 km):Q', bin=True),
    y='count():Q',
)
```
![Histogram of the fuel economy in the cars dataset.](/static/img/altair-cars-hist.svg)

Where setting `bin=True` will create bins with the default parameters,
and the `count():Q` on the `y` axis counts the elements in each bin.
Instead of `count()` it is also possible to perform other [aggregations][vega-lite aggregations],
like computing the mean of a column.

```python
chart.mark_bar().encode(
    x=alt.X('Fuel Economy (L/100 km):Q', bin=True),
    y='mean(Weight (kg)):Q',
)
```
![Histogram of the fuel economy in the cars dataset.](/static/img/altair-cars-weight.svg)

For a more comprehensive view of using Altiar,
have a look at either the [Example Gallery][altair example gallery],
or a [case study][altair case study].

Each of the visualisation libraries in python
have their own strengths and weaknesses,
types of visualisations they excel at,
and others you wouldn't want to try.
For me, while Altair does still have a some quirks,
particularly in the handling of [large datasets][altiar notebook size],
and a somewhat complicated method of [setting titles][altair setting titles],
it provides a simple and intuitive interface to data
which currently makes it the first tools I will reach for
to understand a dataset.



[jakevdp pycon vis]: https://youtu.be/FytuB8nFHPQ?t=3m53s
[xkcd competing standards]: https://xkcd.com/927/
[bokeh]: https://bokeh.pydata.org/en/latest/
[bokeh server]: https://bokeh.pydata.org/en/latest/docs/user_guide/server.html
[holoviews]: https://holoviews.org
[vega-lite docs]: https://vega.github.io/vega-lite/docs/
[vega-lite aggregations]: https://vega.github.io/vega-lite/docs/aggregate.html#ops
[altair docs]: https://altair-viz.github.io/index.html
[altair example gallery]: https://altair-viz.github.io/gallery/index.html
[altair case study]: https://altair-viz.github.io/case_studies/exploring-weather.html
[altair notebook size]: https://github.com/altair-viz/altair/issues/249
[altair setting titles]: https://github.com/altair-viz/altair/issues/585
