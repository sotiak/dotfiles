{ pkgs }:
pkgs.writeShellApplication {
  name = "opencode-telemetry";

  # Packaged here so the systemd timer never depends on the caller's PATH.
  runtimeInputs = with pkgs; [
    coreutils
    curl
    jq
    opencode
  ];

  text = ''
    set -euo pipefail

    URL="''${OPENCODE_TELEMETRY_URL:-http://monitoring-01.tail852c00.ts.net:8428/api/v1/import/prometheus}"

    # Only use the official stats API. `--tools` asks for the per-tool
    # breakdown; the response also carries per-model totals. Every field is a
    # gauge republished on each run, not a counter increment.
    stats="$(opencode stats --all --tools --json)"

    {
      printf '%s' "$stats" | jq -r '
        "opencode_sessions \(.sessions)",
        "opencode_subagents \(.subagents)",
        "opencode_prompts \(.prompts)",
        "opencode_steps \(.steps)",
        "opencode_tokens_input_total \(.tokens.input)",
        "opencode_tokens_output_total \(.tokens.output)",
        "opencode_tokens_reasoning_total \(.tokens.reasoning)",
        "opencode_tokens_cache_read_total \(.tokens.cache.read)",
        "opencode_tokens_cache_write_total \(.tokens.cache.write)",
        "opencode_cost_usd_total \(.cost)",
        "opencode_tool_calls_total \(.tools.totals.calls)",
        "opencode_tool_succeeded_total \(.tools.totals.succeeded)",
        "opencode_tool_failed_total \(.tools.totals.failed)",
        "opencode_tool_unfinished_total \(.tools.totals.unfinished)",
        "opencode_active_days \(.activeDays)",
        "opencode_streak_days \(.streak)",
        # Cap the per-day series so the dashboard chart stays readable.
        (.activity[-90:][] | "opencode_activity_steps{date=\"\(.date)\"} \(.steps)"),
        # Per-model totals. Variants are kept as a label and aggregated by the
        # dashboard.
        (.models[] |
          .model.id as $model |
          (.model.providerID // "unknown") as $provider |
          (.model.variant // "") as $variant |
          "opencode_model_cost_usd_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\"} \(.cost)",
          "opencode_model_steps_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\"} \(.steps)",
          "opencode_model_tokens_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\",type=\"input\"} \(.tokens.input)",
          "opencode_model_tokens_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\",type=\"output\"} \(.tokens.output)",
          "opencode_model_tokens_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\",type=\"reasoning\"} \(.tokens.reasoning)",
          "opencode_model_tokens_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\",type=\"cache_read\"} \(.tokens.cache.read)",
          "opencode_model_tokens_total{model=\"\($model)\",provider=\"\($provider)\",variant=\"\($variant)\",type=\"cache_write\"} \(.tokens.cache.write)"
        ),
        # Per-tool reliability from the same stats response.
        (.tools.usage[] |
          "opencode_tool_calls_by_tool_total{tool=\"\(.name)\"} \(.calls)",
          "opencode_tool_succeeded_by_tool_total{tool=\"\(.name)\"} \(.succeeded)",
          "opencode_tool_failed_by_tool_total{tool=\"\(.name)\"} \(.failed)",
          "opencode_tool_unfinished_by_tool_total{tool=\"\(.name)\"} \(.unfinished)",
          "opencode_tool_duration_p50_ms{tool=\"\(.name)\"} \(.durationP50 // 0)"
        )
      '
    } | curl -fsS --max-time 20 --retry 2 --retry-delay 1 --data-binary @- "$URL"
  '';
}
