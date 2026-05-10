# vuln.jq — extract Pix-relevant fields from `vulnetix vdb vuln <id> -o json`.
#
# Verified against: CVE-2021-44228 (4.0 MB raw → ~80 KB filtered, ~98% reduction).
# Source struct: vdb-api uses CVE5 record format; response is an ARRAY of container
# views, one per upstream source / ecosystem. Each container has its own
# `cna.affected` slice (different ecosystems carry different affected lists —
# Amazon Linux entries in one, npm/maven log4j-core in another, etc.), but the
# Vulnetix enrichment under `adp[0].x_*` is the same composite score across
# containers.
#
# Strategy:
#   - Take enrichment fields from the first container that carries them.
#   - AGGREGATE the cna.affected lists across all containers (with optional dedup
#     by vendor+product+collectionURL+packageName) — this is the canonical
#     "what's affected" view across ecosystems.
#   - Aggregate references too (most CVEs share refs across sources, dedup by URL).
#   - Drops: x_aliases (large cross-reference lists), provenance/timestamp metadata,
#     duplicated descriptions per container.

(. | if type == "array" then . else [.] end) as $arr
| ($arr[0]) as $v
| ([$arr[] | .containers.adp[0]? | select(.x_threatExposure != null)] | .[0]) as $enrich
| ([$arr[] | .containers.cna.affected // []] | flatten) as $all_affected
| ([$arr[] | .containers.cna.references // []] | flatten | unique_by(.url)) as $all_refs
| ([$arr[] | .containers.cna.descriptions // []] | flatten | unique_by(.value)) as $all_descs
| {
    id: ($v.cveMetadata.cveId // null),
    state: ($v.cveMetadata.state // null),
    datePublished: ($v.cveMetadata.datePublished // null),
    dateUpdated: ($v.cveMetadata.dateUpdated // null),
    title: ($v.containers.cna.title // null),
    descriptions: ([$all_descs[] | {
      lang: .lang,
      value: ((.value // "") | if length > 600 then .[:597] + "..." else . end)
    }] | .[0:3]),

    # Vulnetix enrichment (adp[0].x_*). Keep all decision data; drop noise.
    threatExposure: ($enrich.x_threatExposure | if . then {
      level: .level,
      amplified: .amplified,
      multiplier: .amplifierMultiplier,
      score: (.score // null),
      rules: ([.rules[]? | {key, label, points, max, value: .value, reason}])
    } else null end),
    attackSurface: ($enrich.x_attackSurface | if . then {
      exposureLevel: .exposureLevel,
      score: .score,
      reasoning: .reasoning,
      factors: .factors
    } else null end),
    ssvc: ($enrich.x_ssvc | if . then {
      decision: .decision,
      priority: .priority,
      methodology: .methodology,
      inputs: .inputs
    } else null end),
    kev: ($enrich.x_kev | if . then {
      vendorProject: .vendorProject,
      product: .product,
      vulnerabilityName: .vulnerabilityName,
      dueDate: .dueDate,
      knownRansomware: .knownRansomwareCampaignUse,
      requiredAction: .requiredAction
    } else null end),
    epss: ($enrich.x_epss | if . then {
      score: .score,
      percentile: .percentile,
      date: .date
    } else null end),
    exploitationMaturity: ($enrich.x_exploitationMaturity | if . then {
      level: .level,
      score: .score,
      confidence: .confidence,
      reasoning: .reasoning,
      factors: .factors
    } else null end),
    remediationTimeline: ($enrich.x_remediationTimeline | if . then {
      lifecycleStage: .lifecycleStage,
      currentAgeDays: .currentAgeDays,
      publicationToFirstPatchDays: .publicationToFirstPatchDays,
      publicationToKevDays: .publicationToKevDays,
      insights: (.insights // []),
      milestones: ([(.milestones // [])[] | {date, event, daysFromPublication}])
    } else null end),
    crit: ($enrich.x_crit // null),
    purls: ([$arr[] | .containers.adp[0].x_purls // []] | flatten | unique),
    tags: ($enrich.tags // []),

    # Aggregated affected list across ALL containers (each container scopes a
    # different ecosystem). Cap at 200 entries to bound output size for CVEs
    # like log4j with 600+ entries; if truncated, the LLM should call
    # `vulnetix vdb affected $ARG -V v2` for the full paginated list.
    affectedTotal: ($all_affected | length),
    affected: ([$all_affected[] | {
      vendor: (.vendor // null),
      product: (.product // null),
      packageName: (.packageName // null),
      collectionURL: (.collectionURL // null),
      defaultStatus: (.defaultStatus // null),
      versions: ([(.versions // [])[] | {
        version: (.version // null),
        status: (.status // null),
        versionType: (.versionType // null),
        lessThan: (.lessThan // null),
        lessThanOrEqual: (.lessThanOrEqual // null)
      }]),
      ranges: (.ranges // [])
    }] | .[0:200]),

    # Top 20 deduped references across all containers — advisory + patch links.
    references: ([$all_refs[0:20][] | {
      url: .url,
      name: (.name // ""),
      tags: (.tags // [])
    }])
  }
