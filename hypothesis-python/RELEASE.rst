RELEASE_TYPE: minor

The :func:`~hypothesis.strategies.one_of` strategy now flattens nested :func:`~hypothesis.strategies.one_of` strategies
to improve the probability distribution of generated values.

This change ensures that when strategies like ``one_of(one_of(a, b), c)`` are used, each of ``a``, ``b``, and ``c``
will be selected with equal probability, rather than ``a`` and ``b`` sharing half the probability and ``c`` getting
the other half.