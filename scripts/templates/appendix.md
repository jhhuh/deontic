## Appendix: Verification Methodology

### Match Verification Subagent

Each case is verified by an LLM subagent that compares the framework
output against the actual court judgment. The subagent operates under
these constraints:

- **Model**: Claude (claude-opus-4-6 via Claude Code Agent tool)
- **Context provided**: None — only `fulltext.md` and `framework-output.md`
- **Directive**: [`scripts/directives/verify-match.md`](https://github.com/jhhuh/deontic/blob/master/scripts/directives/verify-match.md)

The subagent has no knowledge of the project architecture, Haskell code,
or any other case. It reads only the two specified files and outputs a
YAML verdict.

### Match Criteria

- **true**: Framework's final judgment essentially aligns with the court's holding
- **partial**: Alignment on some issues, divergence on others
- **false**: Framework's conclusion contradicts the court's decision
