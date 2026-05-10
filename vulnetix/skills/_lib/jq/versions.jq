# versions.jq — extract Pix-relevant fields from `vulnetix vdb versions <package> -o json`.
#
# Verified against: `versions express` (8 KB raw → ~7 KB filtered, modest reduction;
# the response is already lean). Top-level keys: _links, hasMore, limit, offset,
# packageName, timestamp, total, versions[].
# Each version: ecosystem, sources[], version. Some entries have ecosystem="" for
# CVE-affected versions that don't map cleanly to a package registry.

{
  package: .packageName,
  total: .total,
  hasMore: .hasMore,
  limit: .limit,
  offset: .offset,
  versions: ([(.versions // [])[] | {
    version: .version,
    ecosystem: (.ecosystem // ""),
    sources: (.sources // [])
  }])
}
