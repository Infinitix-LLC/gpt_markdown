# Task runner for gpt_markdown. `just` with no argument lists everything.
#
# Notes that do not fit on a recipe's one-line summary:
#
# * `score` takes a couple of minutes — it resolves dependencies and runs a
#   full analysis. pana awards 160 points across eleven categories, and two of
#   them ("dependencies support latest version", "supports latest stable SDKs")
#   decay without anyone touching the code, so a score that was 160 last month
#   may not be today. That is why `score.sh` also runs on a weekly schedule.
# * `publish-dry` catches what pana does not: oversized archives, files that
#   are committed but gitignored, layout conventions.

_default:
    @just --list --unsorted

# pub.dev points you will get after publishing. Fails under the threshold.
score threshold="160":
    ./scripts/score.sh {{threshold}}

# Same, but never fails — for seeing where the points went.
score-soft:
    ./scripts/score.sh 0

# Full pana report from the last `just score`, with every suggestion.
score-report:
    @test -f /tmp/pana-report.md || (echo "run 'just score' first" && exit 1)
    @cat /tmp/pana-report.md

# Packaging check only. Much faster than a full score.
publish-dry:
    flutter pub publish --dry-run

# Format, analyse and test the package and both apps. CI runs this exact script.
check:
    ./scripts/check.sh

# Same, applying formatting instead of failing on it.
fix:
    ./scripts/check.sh --fix

# Everything a release needs to pass, ordered to fail fastest.
release-check: check publish-dry score
