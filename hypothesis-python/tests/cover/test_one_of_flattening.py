# This file is part of Hypothesis, which may be found at
# https://github.com/HypothesisWorks/hypothesis/
#
# Copyright the Hypothesis Authors.
# Individual contributors are listed in AUTHORS.rst and the git log.
#
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.

import pytest

from hypothesis.strategies import just, one_of
from hypothesis.strategies._internal.strategies import OneOfStrategy


def test_one_of_flattens_single_level():
    # Test that one_of(one_of(just(1), just(2)), just(3)) becomes equivalent to
    # one_of(just(1), just(2), just(3))
    s1 = one_of(just(1), just(2))
    s2 = just(3)
    s = one_of(s1, s2)
    
    assert isinstance(s, OneOfStrategy)
    assert len(s.original_strategies) == 3
    assert all(strat.value == i for i, strat in enumerate(s.original_strategies, 1))


def test_one_of_flattens_multiple_levels():
    # Test that deeply nested one_of calls are flattened
    s1 = one_of(just(1), just(2))
    s2 = one_of(just(3), one_of(just(4), just(5)))
    s3 = one_of(s1, s2)
    s = one_of(s3, just(6))
    
    assert isinstance(s, OneOfStrategy)
    assert len(s.original_strategies) == 6
    assert all(strat.value == i for i, strat in enumerate(s.original_strategies, 1))


def test_one_of_maintains_order():
    # Test that the order of strategies is maintained after flattening
    s1 = one_of(just(1), just(2))
    s2 = one_of(just(3), just(4))
    s = one_of(s1, s2)
    
    assert isinstance(s, OneOfStrategy)
    assert len(s.original_strategies) == 4
    assert all(strat.value == i for i, strat in enumerate(s.original_strategies, 1))