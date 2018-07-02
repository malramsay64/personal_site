+++
title = "Making the Move to Big Data"
date = "2018-02-26"

draft = true
math = true
highlight = true
+++

It is no real secret that pandas is [not optimised for memory management][wes_pandas_memory],
and there are a plethora of tools including [dask][dask], and [pyspark][pyspark], 
which enable the analysis of enormous datasets.
The migration to these tools can require 
a significant change to the approach used to solve the problem at hand.
During the course of my research the datasets I was investigating 
became too large to fit in memory on the machine I was using.
While a solution to this is to insert more RAM,
I am a student with a limited budget and RAM is expensive.
I looked at a range of different file IO solutions 
which don't require loading the entire dataset into memory at once.
The approaches are;
- HDF5
- Text files
- sqlite
- Apache parquet
chosen primarily because they are simple to use. 
Postgresql was also considered for inclusion,
however, I was unable to quickly get an instance running and working.



As a solution I looked at using a different tools for iteratively writing to a file
so 
I was investigating methods of storage 

Increasing 

Wit
and datasets are continually getting larger.

There are 
As a single person 
This is not nessle there is not a e
Even if you are not working at the scale of petabytes 


[wes_pandas_memory]:
[dask]:
[pyspark]:

