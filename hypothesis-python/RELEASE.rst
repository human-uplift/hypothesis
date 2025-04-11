RELEASE_TYPE: patch

This patch enhances the :doc:`the Ghostwriter <ghostwriter>` module to recursively
flatten multiple nested :func:`~hypothesis.strategies.one_of` strategies.
Previously, it would only flatten a single level of nesting, which could lead
to unnecessarily complex strategy representations in the generated code.