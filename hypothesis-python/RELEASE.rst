RELEASE_TYPE: minor

Added support for type aliases (using the `type X = Y` syntax) in `st.from_type`.
This allows Hypothesis to work with `typing.TypeAliasType` introduced in Python 3.12.
