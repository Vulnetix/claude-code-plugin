# vuln.jq — extract Pix-relevant fields from `vulnetix vdb vuln <id> -o json`.
#
# Verified against: CVE-2021-44228 (4.0 MB raw → ~3 KB filtered, ~99.9% reduction).
# Source struct: vdb-api uses CVE5 record format; response is an ARRAY of container
# views (one per upstream source). Vulnetix's own enrichment lives in adp[0].x_*.
#
# Note: pick the array element where adp[0] carries Vulnetix enrichment (x_threatExposure).
# In practice this is .[0]; if the input order ever changes, fall back to scanning.
#
# Output: a single object with id, severity (composite), CVSS source rules,
# KEV, EPSS, exploitation maturity factors, top references.

(. | if type == "array" then .[0] else . end) as $v
| {
    id: ($v.cveMetadata.cveId // null),
    state: ($v.cveMetadata.state // null),
    datePublished: ($v.cveMetadata.datePublished // null),
    title: ($v.containers.cna.title // null),
    threatExposure: ($v.containers.adp[0].x_threatExposure | if . then {
      level: .level,
      amplified: .amplified,
      multiplier: .amplifierMultiplier,
      rules: ([.rules[]? | {key, label, points, max, reason}])
    } else null end),
    kev: ($v.containers.adp[0].x_kev | if . then {
      vendorProject: .vendorProject,
      product: .product,
      vulnerabilityName: .vulnerabilityName,
      dueDate: .dueDate,
      knownRansomware: .knownRansomwareCampaignUse,
      requiredAction: ((.requiredAction // "") | if length > 200 then .[:197] + "..." else . end)
    } else null end),
    epss: ($v.containers.adp[0].x_epss | if . then {
      score: .score, percentile: .percentile, date: .date
    } else null end),
    exploitationMaturity: ($v.containers.adp[0].x_exploitationMaturity | if . then {
      level: .level,
      score: .score,
      confidence: .confidence,
      reasoning: .reasoning,
      factors: .factors
    } else null end),
    affectedCount: (($v.containers.cna.affected // []) | length),
    references: ([($v.containers.cna.references // [])[0:5][] | {url, name: (.name // ""), tags: (.tags // [])}])
  }
