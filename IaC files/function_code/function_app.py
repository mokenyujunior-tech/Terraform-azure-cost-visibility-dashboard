"""
WeeklyCostReport Function App
------------------------------
Timer-triggered Azure Function that:
  1. Queries Azure Cost Management for last 7 days of spend
  2. Compares against the previous 7 days
  3. Groups costs by the 'costcategory' tag
  4. Posts a summary to the Logic App webhook (which emails it)

Runs every Monday 08:00 UTC by default (overridable via
WEEKLY_REPORT_CRON app setting).
"""

import json
import logging
import os
from datetime import datetime, timedelta, timezone

import azure.functions as func
import requests
from azure.identity import DefaultAzureCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import (
    QueryDefinition,
    QueryDataset,
    QueryAggregation,
    QueryGrouping,
    QueryTimePeriod,
)

app = func.FunctionApp()

SUBSCRIPTION_ID = os.environ["AZURE_SUBSCRIPTION_ID"]
LOGIC_APP_URL = os.environ["LOGIC_APP_URL"]
CRON_EXPRESSION = os.environ.get("WEEKLY_REPORT_CRON", "0 0 8 * * 1")


def _query_cost_by_category(client, scope, start, end):
    """Return a dict of {costcategory_tag_value: total_cost_cad}."""
    query = QueryDefinition(
        type="Usage",
        timeframe="Custom",
        time_period=QueryTimePeriod(from_property=start, to=end),
        dataset=QueryDataset(
            granularity="None",
            aggregation={
                "totalCost": QueryAggregation(name="Cost", function="Sum")
            },
            grouping=[
                QueryGrouping(type="TagKey", name="costcategory")
            ],
        ),
    )

    result = client.query.usage(scope=scope, parameters=query)
    totals = {}
    for row in result.rows or []:
        # Row shape: [cost, tag_value, currency]
        cost = float(row[0] or 0)
        tag = row[1] if len(row) > 1 and row[1] else "Untagged"
        totals[tag] = totals.get(tag, 0.0) + cost
    return totals


@app.function_name(name="WeeklyCostReport")
@app.schedule(
    schedule=CRON_EXPRESSION,
    arg_name="timer",
    run_on_startup=False,
    use_monitor=True,
)
def weekly_cost_report(timer: func.TimerRequest) -> None:
    logging.info("WeeklyCostReport starting — cron=%s", CRON_EXPRESSION)

    credential = DefaultAzureCredential()
    client = CostManagementClient(credential)
    scope = f"/subscriptions/{SUBSCRIPTION_ID}"

    now = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    this_week_end = now
    this_week_start = now - timedelta(days=7)
    last_week_end = this_week_start
    last_week_start = this_week_start - timedelta(days=7)

    try:
        this_week = _query_cost_by_category(client, scope, this_week_start, this_week_end)
        last_week = _query_cost_by_category(client, scope, last_week_start, last_week_end)
    except Exception as exc:
        logging.exception("Cost Management query failed: %s", exc)
        raise

    all_tags = set(this_week.keys()) | set(last_week.keys())
    rows = []
    total_this = 0.0
    total_last = 0.0
    for tag in sorted(all_tags):
        this_val = this_week.get(tag, 0.0)
        last_val = last_week.get(tag, 0.0)
        diff = this_val - last_val
        total_this += this_val
        total_last += last_val
        rows.append({
            "costcategory": tag,
            "this_week_cad": round(this_val, 2),
            "last_week_cad": round(last_val, 2),
            "diff_cad":      round(diff, 2),
        })

    payload = {
        "schemaId": "WeeklyCostReport",
        "data": {
            "essentials": {
                "alertRule":     "Weekly Cost Report",
                "severity":      "Sev4",
                "firedDateTime": now.isoformat(),
                "description":   _build_description(rows, total_this, total_last),
            },
            "rows": rows,
        },
    }

    logging.info("Posting weekly cost report to Logic App (total CAD %.2f vs %.2f)", total_this, total_last)
    response = requests.post(LOGIC_APP_URL, json=payload, timeout=30)
    response.raise_for_status()
    logging.info("WeeklyCostReport posted successfully (HTTP %s)", response.status_code)


def _build_description(rows, total_this, total_last):
    diff = total_this - total_last
    arrow = "▲" if diff > 0 else ("▼" if diff < 0 else "→")
    lines = [
        f"Total this week: CA${total_this:.2f}",
        f"Total last week: CA${total_last:.2f}",
        f"Change: {arrow} CA${abs(diff):.2f}",
        "",
        "Breakdown by costcategory:",
    ]
    for row in rows:
        lines.append(
            f"  {row['costcategory']}: CA${row['this_week_cad']:.2f} "
            f"(prev CA${row['last_week_cad']:.2f}, diff CA${row['diff_cad']:.2f})"
        )
    return "<br>".join(lines)
