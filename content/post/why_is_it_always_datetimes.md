+++
title = "Why is it always datetimes"
date = 2022-02-07

draft = true

[taxonomies]
tags = ["azure", "timezone", "data science"]
+++

Azure Synapse is Microsoft's fancy data analytics platform
designed to handle all kinds of data analytics tasks.
Unfortunately, there are significant deficiencies
in how this platform handles datetime data and timezones.
Making it incredibly difficult to use Synpase
in conjunction with other tools within the Data Science ecosystem.

Dealing with time and timezones is an incredibly difficult problem,
not at all helped by the 6 separate timezones currently in use on mainland Australia[^1].
However, despite all the complexity of dealing with time
and the corresponding timezones,
there are two main ways of storing and working with time information;

1. Use a naive datetime that just includes the date and the time which we are going to call _Local Time_, or
2. use a timezone aware datetime that includes the date, time, and a timezone offset
  which we are going to call _Instantaneous Time_.

It is really important to note that these two types of times,
_Local Time_ and _Instantaneous Time_ are different representations,
and converting between them is an incredibly complex process
&mdash;talking to you daylight savings, [Samoa][Samoa date line], and all the other exceptions.
This conversion needs to be done carefully and deliberately,
that is, use a library specifically designed for handling the conversion
and trust that whoever spent years handling all the edge cases
knows far, far better than you.

Both of these approaches have their use cases,
_Local Time_ is simpler and suited to collecting data locally,
for example most of our daily activities,
or monitoring cycling patterns across a bridge.
_Instantaneous Time_ is required for data collected remotely
where we need the additional context of where the time was taken
allowing the comparison of the instant the event occurred.
As such see plenty of use in computer systems,
and also when travelling by aeroplane.
The major difference between _Local Time_ and and _Instantaneous Time_
is we can convert the timezone of _Instantaneous Time_
without changing the instant at which the event occured,
allowing for the comparison and ordering of events across timezones.

This ability to change the timezone of _Instantaneous Time_
also gives us the ability to convert all the times to a standard timezone,
which makes for an easy comparison of events.
The standard timezone to use for this comparison is
Co-ordinated Universal Time (UTC), which has a timezone offset of +0.
Working with this standard timezone allows for
an important simplification of _Instantaneous Time_.
Rather than storing the date, time, and timezone offset,
we can store just the date, the time in the UTC timezone,
and that we have an _Instantaneous Time_.
This is how many programming languages handle timezones,
performing the conversion to a local time when displaying the data.
This is also the approach used by the parquet file format,
which natively supports a TIMESTAMP data type.
The parquet format is designed to hold columnar data,
that is data where all the values within a column have the same data type.
They will all be integers, strings, ...or TIMESTAMPs.
The metadata of a parquet file describes the contents,
including the name of each column and the type of data stored within it.
When the data type is TIMESTAMP,
there is a option to specify whether we are storing _Local Time_, or _Instantaneous Time_.
This flag that we set has the name `isAdjustedtoUTC` documenting
whether we are using the trick of converting everything to UTC described above.

The Parquet file format is the enabler of the Data Lake,
allowing software to read and write data to disk
in an efficient and portable way.
[Azure Synapse][Synapse] is Microsoft's fancy serverless database,
specifically designed to work alongside a Data Lake.
So it makes sense that there is built in support
for working with Parquet files.

Like the Parquet file format,
Synapse has different timestamp types for _Local Time_ and _Instantaneous Time_.
The `datetime2` type is used for _Local Time_,
while the `datetimeoffset` type is used for _Instantaneous Time_.

Unfortunately the handling of datetime data within synapse is significantly lacking.
When trying to read a _Local Time_ from a parquet file
into the `datetime2` type Synapse gives us this really helpful error message

```
Column 'datetime' of type 'DATETIME2' is not compatible with external data type
'Parquet physical type: INT64', please try with 'BIGINT'. File/External table
name: 'local.parquet'.
```

Under the covers, the TIMESTAMP within a Parquet file is an INT64 type,
counting the number of milliseconds [^1] since 1 January 1970 (1970-01-01 00:00).
Even more confusing about this error message is that the documentation
for the [OPENROWSET function][openrowset docs] which is how we are opening the file
clearly states that TIMESTAMP (MILLIS / MICROS) are converted to the `datetime2` type.
You might think that there would be a function built into Synapse
to allow for the manual conversion of a TIMESTAMP to the internal `datetime2` format,
however, there is absolutely no mention of it within the documentation.
So we can't even perform this conversion ourselves
without first implementing the function to perform that conversion.

So if reading in a _Local Time_ doesn't work, how about an _Instantaneous Time_?
When we reading the _Instantaneous Time_ using the same approach,
rather than the cryptic error message, the file reads with no problems.
So we can just use _Instantaneous Time_ and everything works right???

No.

Remember how I mentioned we want to be really careful about the conversion
between _Instantaneous Time_ and _Local Time_,
well here Synapse is completely ignoring our _Instantaneous Time_
and just reading the data into its `datetime2` type representing _Local Time_.
The problem here is that other tools[^2] actually pay attention to these details,
so the 'quick fix' of flicking the switch to using the _Instantaneous Time_
is going to cause far more problems with other tools using this data.
To solve this problem properly,
we need changes at both sides of the data pipeline.
Firstly, the _Local Time_ needs to be converted to _Instantaneous Time_,
assuming we know the locale in which the times were collected.
We will need this locale at the end,
so better hope it is documented somewhere
(I know that might be asking too much).
If we have no idea trying UTC and hoping for the best
at least allows us to read the file,
even if it causes problems down the track.
With the data having a locale,
one of the [Apache Arrow Parquet writers][Apache Arrow: Parquet]
will automatically convert the timezone to UTC upon writing the file.
Now when reading the file within Synapse
we need to do two conversions when selecting our timestamp column,
the first to convert Synapse's _Local Time_ to
an _Instantaneous Time_ in the UTC time zone,
followed by a conversion to the local timezone we identified earlier.

```SQL
SELECT timestamp AT TIME ZONE 'UTC' AT TIME ZONE 'Cen. Australia Standard Time'
```

So how about doing the conversion manually.
Well it turns out this acutally isn't possible
with the tools available within Synapse.
There is no inbuilt method to convert from this TIMESTAMP
to the inbuilt date types.
Additionally,
if we want to try and do this conversion manually
the `DATEADD` function within Synapse only supports a 32 bit signed integer,
of which the largest is 2^16-1 (~2.1 billion).
In the most optimistic case supported by the Parquet file,
that is, using milliseconds since 1970-01-01 00:00:00,
the only dates we can describe are the 25 days surrounding it.
Which really doesn't solve the problem here.

What I find really unusual about this whole situation
is that this is definitely not a result of using a really old Parquet reader.
We can know this because there has been a change in how the
TIMESTAMP type is defined within the Parquet file.
The previous types had no notion of _Local Time_
and were either annotated as `TIMESTAMP_MILLIS` or `TIMESTAMP_MICROS`.
For compatibility reasons these old types are still annotated on the files
with the filetype specifications noting

  Despite there is no exact corresponding ConvertedType for local timestamp semantic, in order to support forward compatibility with those libraries, which annotated their local timestamps with legacy TIMESTAMP_MICROS and TIMESTAMP_MILLIS annotation, Parquet writer implementation _must_ annotate local timestamps with legacy annotations too, as shown below.

If the Parquet reader for Synapse was only looking at these legacy annotations
then both _Local Time_ and _Instantaneous Time_ would work
since they have the same type defined.
It is only in the newer file format definition
that there is anything differentiating _Local_ and _Instantaneous_ time.
So the new types are supported, but not properly
which in my opinion is worse than not supporting them at all.
To add even more confusion to the mix,
the type provided when trying to read the parquet timestamp
into a `datetimeoffset` type annotates the type
in the Parquet file as `TIMESTAMP_MILLIS`,
that is, using the legacy annotation.

For Synapse to be a properly fulfil a role within a Data Science toolkit
Microsoft really needs to properly support TIMESTAMPs 
from the Parquet file format.
Currently, Synapse is unsuitable as part of a data pipeline
that handles datetime data.
The lack of both inbuilt support for TIMESTAMPs
and the tools for individuals to support them
severly limits the usefullness of Synapse,
and makes it difficult to recommend
as part of a broader data analytics platform.

[^1]: During summer these are: AEST, AEDT, ACDT, ACST, AWST, and Eucla. 
  There are also at least 4 more in use off mainland Australia.

[^2]: Microseconds are also a supported option. And in newer versions of the
  parquet file format, Nanoseconds are also supported.

[^3]: For example, the entire python Data Science ecosystem.

[Samoa date line]: https://www.timeanddate.com/news/time/samoa-dateline.html
[Synapse]: https://docs.microsoft.com/en-us/azure/synapse-analytics/overview-what-is
[openrowset docs]: https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-openrowset
[Apache Arrow: Parquet]: https://arrow.apache.org/docs/python/timestamps.html
