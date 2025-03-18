# This file is part of Hypothesis, which may be found at
# https://github.com/HypothesisWorks/hypothesis/
#
# Copyright the Hypothesis Authors.
# Individual contributors are listed in AUTHORS.rst and the git log.
#
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.

import sys

import pytest

from hypothesis import given, strategies as st
from hypothesis.strategies._internal.types import is_a_type_alias

pytestmark = pytest.mark.skipif(
    sys.version_info < (3, 12), reason="TypeAliasType was added in Python 3.12"
)


def test_is_a_type_alias():
    # Define a type alias using the new syntax
    type Point = tuple[float, float]  # noqa
    assert is_a_type_alias(Point)


def test_from_type_with_type_alias():
    # Define a type alias using the new syntax
    type Point = tuple[float, float]  # noqa
    
    # This used to raise InvalidArgument: 'Point must be a type'
    strategy = st.from_type(Point)
    
    # The strategy should be the same as what we'd get from the underlying type
    expected_strategy = st.from_type(tuple[float, float])
    assert repr(strategy) == repr(expected_strategy)
    
    # We should be able to generate examples
    example = strategy.example()
    assert isinstance(example, tuple)
    assert len(example) == 2
    assert all(isinstance(x, float) for x in example)


@given(st.from_type(tuple[int, int]))
def test_given_with_type_alias(point):
    # Define a type alias using the new syntax
    type Point = tuple[int, int]  # noqa
    
    # This should also work with the @given decorator
    strat = st.from_type(Point)
    assert isinstance(point, tuple)
    assert len(point) == 2
    assert all(isinstance(x, int) for x in point)


def test_nested_type_alias():
    # Define nested type aliases
    type Coordinate = float  # noqa
    type Point = tuple[Coordinate, Coordinate]  # noqa
    
    # Both should be TypeAliasType instances
    assert is_a_type_alias(Coordinate)
    assert is_a_type_alias(Point)
    
    # Both should work with from_type
    coord_strat = st.from_type(Coordinate)
    point_strat = st.from_type(Point)
    
    # Check examples
    coord_example = coord_strat.example()
    assert isinstance(coord_example, float)
    
    point_example = point_strat.example()
    assert isinstance(point_example, tuple)
    assert len(point_example) == 2
    assert all(isinstance(x, float) for x in point_example)
