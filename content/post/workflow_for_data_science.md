+++
title = "A Workflow for Data Science"
date = 2021-06-29

draft = false

[taxonomies]
tags = ["research", "jupyter", "python"]
+++

Jupyter notebooks are a phenomenal tool
for investigating and interacting with data.
The interactive nature of the notebooks
allows for quick and effective interrogation of the data
and more generally the prototyping of an idea.
By combining interaction, the documentation, the code,
and the visualisations,
the notebooks are also a fantastic tool for communicating ideas.
However, notebooks are not the most appropriate for all the code we write,
with many there being many detractors to [using notebooks][i dont like notebooks]
and there are definitely valid reasons for disliking the notebook.
However, most of the issues can be addressed by recognising that
the jupyter notebook is one of many tools that we have available,
and knowing when to move beyond the notebook
can help us make the most of it.

While I am using python to illustrate these steps and examples,
the same ideas apply for any language being used in the notebook
just with some slightly different specifics on the how.

## Idea Development

The first step within the process is the exploration and development of an idea.
This is where we are just getting started looking at a problem
and we probably haven't written any code yet.
In this phase of development we want to make full use
of the interactivity of jupyter.
This is where we can easily play around
to make sure we are using the right options for reading in our file,
trying lots of different types of analysis,
while having a record of what we have done
so that we can easily regenerate a previous state when we break something.

It is here where the interactive nature of the juptyer notebook really stands out.
It is easy to introspect the state at each step in the process,
looking at the problem in different ways to properly understand what is going on.
We also have the visualisations,
which allow us to generate nice figures representing the data,
however also includes the pretty printed outputs,
like the nicely formatted tables of dataframes,
which make working with the data easier.

The way we retain state within the notebook
is incredibly appealing,
particularly where the first step of the process is time consuming,
like loading the data from a URL,
performing a complex database query,
or doing some intermediate processing.

## Organisation of Thoughts

As you start to get an understanding of the problem you are solving
and the types of analyses and steps that you will be performing.
You are going to start grouping cells together,
to make it easier to run.
Reading the dataset and the initial transformations in one cell,
another to calculate some interesting values,
and one to generate a visualisation.

This process of organising related lines of code together
is the first step towards looking at creating functions.
The functions allow you to abstract away the details
of what is going on in a particular step,
like the data loading, and focus on the important parts.

We might have the following code to read in a file
```python
df = pd.read_csv("data/gapminder_data.csv")
df["country"] = df["country"].astype("category")
df["continent"] = df["continent"].astype("category")
```
where the datafile `gapminder_data.csv` is from the software carpentry training courses
and can be downloaded [here][gapminder_data].
In loading this file we are concerned with two inputs,
firstly, the name of the file that we are loading,
and secondly the names of the fields
we want to load as categorical columns.
This results in a dataframe that is ready for us to use.
The function we might write could look something like what we have below,
where I have used type annotations to be clear about the data passed as input.

```python
def read_csv_dataset(filename: str, categorical_columns: List[str] = []):
  df = pd.read_csv("data/gapminder_data.csv")
  for column in categorical_columns:
    df[column] = df[column].astype("category")
  return df
```

By transforming our code snippet into a function,
we can make our intent clearer within the narrative of the notebook.
Now when we load the dataset we can use the line

```python
df = read_csv_dataset(
  filename="data/gapminder_data.csv",
  categorical_columns=["country", "continent"]
)
```

which makes it clear to the reader that we want the `country` and `continent` columns to be categorical
while everything else is less important to our analysis.
This function can then be re-used within a notebook,
serving slightly different purposes each time,
loading a different file,
or allowing us to investigate whether setting columns to categorical
changes the performance of our analysis.

## Solidification of Idea

Once we have defined a function within one notebook,
it often becomes something we want to reach for within other notebooks.
Alternatively the definition of the function
could be detracting from the story we are trying to tell within the notebook.
Once we have solidified an idea and defined a function,
we can move that function to a `.py` file.

By creating a file `loading.py` in the same directory as the jupyter notebook
with the `read_csv_dataset` function as its contents

```python
# loading.py
import pandas as pd

def read_csv_dataset(filename: str, categorical_columns: List[str] = []):
  df = pd.read_csv("data/gapminder_data.csv")
  for column in categorical_columns:
    df[column] = df[column].astype("category")
  return df
```

we can import this function into the notebook as follows

```
from loading import read_csv_dataset
```

This works because the file loading is in the same directory as the juptyer notebook,
if it was located elsewhere, we would need to modify where jupyter looks for files to import.
I will commonly locate all my notebooks within a `notebook` directory of a project,
while all the python files in the `src` directory of a project,
a structure like below.

```
project/
├── notebook
│   └── gapminder.ipynb
└── src
    └── loading.py
```

To import the `loading.py` file (in this context it is called a module) from the `gapminder.ipynb` notebook,
the simplest method is to tell python to look in that `src` folder.

If we change the import to

```
import sys
sys.path.append("../src")

from loading import read_csv_dataset
```

where the `sys` module is one of python's built in modules
and `sys.path` is the list of places that python looks
for things to import.
By manually adding the relative path to the `src` directory
we are able to import from any files defined within it.

One disadvantage of the move to importing from a file
is that it becomes harder to update the function,
requiring a restart of the kernel to reload the module.
This can be worked around by using the `%autoreload` magic
built into IPython.

```
%load_ext autoreload
%autoreload 2
import sys
sys.path.append("../src")

from loading import read_csv_dataset
```

which means that any time we edit the file `../src/loading.py`,
python will reload the file and its definitions
replacing the previous version of `read_csv_dataset` with the new one.

## Does this code actually work

Once we have moved code from a jupyter notebook to a python file
we have a range of tools available to help evaluate whether
the code we have written works.
Within the notebook this would normally be a quick process of running the code,
within a python file this can become a little harder,
particularly as the size of the file gets larger.

To help with this there are a number of tools making this process easier,

- `black` provides automatic code formatting so you can worry about the code
  rather than how it is laid out.
- `mypy` provides static type checking, which can be really useful for finding
  all the places `None` can show up in the code. Note that this only applies if
  you are using type annotations.
- `flake8` provides a range of checks that the code works, primarily checking
  for common mistakes.

None of these tools however actually run the code,
for that we want to look towards `pytest`
providing tools to run the code to make sure it works.

## Package Creation

In the vast majority of data analysis projects,
having the code in a separate file is as far as we need to go.
All the tooling is going to work in helping us keep our code working.
However, there are some cases where the functionality you are working on
is more widely applicable and needed in multiple projects.

For this we can create a package for the code,
with the package becoming a dependency of the project.
This allows for anyone to install the package
and we can use the same tools `pip` and/or `conda`
that we use to manage the rest of our external dependencies.
For information on packaging the Python Package Authority (PyPA)
has a useful [user guide][pypa user guide]
and conda also has a [user guide][conda user guide] for getting started.

## Conclusion

The Jupyter notebook is the starting place for code,
it allows us to quickly iterate and try ideas out to see what works.
Additionally notebooks they are a fantastic storytelling tool,
however to make the most of them and to keep the story engaging,
we sometimes need to look beyond the notebook.
How far we go depends heavily on the type of project being undertaken
and the tools we want to use.

[i dont like notebooks]: https://www.youtube.com/watch?v=7jiPeIFXb6U
[gapminder_data]: "https://raw.githubusercontent.com/swcarpentry/r-novice-gapminder/gh-pages/_episodes_rmd/data/gapminder_data.csv"
[pypa user guide]: https://packaging.python.org/
[conda user guide]: https://docs.conda.io/projects/conda-build/en/latest/user-guide/tutorials/index.html
