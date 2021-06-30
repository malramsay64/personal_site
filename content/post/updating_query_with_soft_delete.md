+++
title = "Updating Query with Soft Delete for SQLAlchemy 1.4"
date = 2021-03-31

draft = false

[taxonomies]
tags = ["sqlalchemy", "python"]
+++

When working on a database,
there are times where we want to delete a row,
but at the same time we still want to keep around
the record that the particular row was referring to.
There can be many reasons for this,
however the basic idea is that we want the row to generally be hidden.
The Soft Delete pattern allows for the 'delete' operation,
to hide the row from the external interface,
while it remains within the database.
Miguel Grinberg has a great writeup of the pattern
and implementation in SQLAlchemy on [their blog](https://blog.miguelgrinberg.com/post/implementing-the-soft-delete-pattern-with-flask-and-sqlalchemy).

This implementation is great,
however the SQLAlchemy 1.4 release changed some of the internals
meaning Miguel's implementation no longer works,
giving the below error

```python
AttributeError: 'QueryWithSoftDelete' object has no attribute '_mapper_zero'
```

The fix for this issue is to replace the `_mapper_zero` method with the `_entity_from_pre_ent_zero` method, giving a `with_deleted` method as below.

```python
class QueryWithSoftDelete(BaseQuery):
    ...

    def with_deleted(self):
        return self.__class__(
            db.class_mapper(self._entity_from_pre_ent_zero().class_),
            session=db.session(),
            _with_deleted=True
        )

```

## Why does this work?

With the fix out of the way,
we can have a look at what the `with_deleted` method is doing.
The entire code snippet for the `QueryWithSoftDelete` is reproduced below for reference.

```python
class QueryWithSoftDelete(BaseQuery):
    def __new__(cls, *args, **kwargs):
        obj = super(QueryWithSoftDelete, cls).__new__(cls)
        with_deleted = kwargs.pop('_with_deleted', False)
        if len(args) > 0:
            super(QueryWithSoftDelete, obj).__init__(*args, **kwargs)
            return obj.filter_by(deleted=False) if not with_deleted else obj
        return obj

    def __init__(self, *args, **kwargs):
        pass

    def with_deleted(self):
        return self.__class__(
            db.class_mapper(self._entity_from_pre_ent_zero().class_),
            session=db.session(),
            _with_deleted=True
        )
```

The `with_deleted` method provides a way to transform the Query
from one that filters out deleted values to one that does.
Now there isn't a straightforward method for removing filters from a query,
so the approach taken here is to create a new Query,
this time setting `_with_deleted=True`.
The problem now becomes,
which model are we trying to query?
When we call the `with_deleted` method,
we are doing so from an instance of the `QueryWithSoftDelete` class,
so we are unable to extract the model being used through
methods like `__class__`, it gives us the `QueryWithSoftDelete` class.
So instead we can look to SQLAlchemy to get this information.
Within SQLAlchemy, every query from the database needs a `FROM` clause,
the table that we are going to be using to initially select our data.
This table we are selecting,
is the same one that we want to query
though this time instead of filtering the deleted items,
we will be including them.

Previously the `_mapper_zero` method provided that table in the `FROM` clause.
However the restructuring of the Query to consolidate the core and ORM components
meant the method disappeared,
completely fine given it is a 'hidden' method.
We need the function that will give the equivalent behaviour,
which happens to be the much more verbose, `_entitiy_from_pre_ent_zero`.
