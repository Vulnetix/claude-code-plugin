# versions.jq — extract Pix-relevant fields from `vulnetix vdb versions <package> -o json`.
#
# Verified against: `versions express` (8 KB raw → ~3 KB filtered, ~63% reduction).
# Top-level keys: _links, hasMore, limit, offset, versions[].
# Each version item: ecosystem, sources[], version.

{
  total: ((.versions // []) | length),
  hasMore: .hasMore,
  versions: ([(.versions // [])[] | {
    version: .version,
    ecosystem: (.ecosystem // ""),
    sources: (.sources // [])
  }])
}
