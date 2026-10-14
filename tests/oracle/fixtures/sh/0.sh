# `httpfetch.m31`: git's smart-HTTP protocol, against a real `git
# http-backend` -- the task this file exists for names it plainly: "stand up
# your own real smart-HTTP git server as the test oracle", never a hand-rolled
# stand-in, so this is `git http-backend` run as a genuine CGI script behind
# Python's `http.server.CGIHTTPRequestHandler`, serving a disposable bare
# repository this script builds itself. Nothing here ever touches a real
# remote or anyone else's server.
#
# Sourced from `test.sh`, sharing its shell, `$WORK`, `build`, `note`/`bad`
# and the `pass`/`fail` counters, exactly as `test_write.sh`'s own header
# describes. **This is the one file in the suite that sets a `trap`**: every
# other sourced script reads fixtures it built itself, but this one also
# starts a real background server process, and that process must be killed
# by its own exact PID before the script exits -- never `pkill`, never by
# name -- whether every check below passes or one of them fails partway.
# The trap composes with `test.sh`'s own (`rm -rf "$WORK"`) rather than
# replacing its effect: it is rewritten, once, to do both.
#
# What each check proves, in the order `apps/git/design.md`'s task asks for:
#
#   1. the ref advertisement matches `git ls-remote` byte for byte;
#   2. a full clone (no `have`s) produces a verified pack that is byte for
#      byte the server's own delta-compressed pack, and real
#      `git index-pack --stdin` accepts it;
#   3. a real `git clone` seeds a local repository, the fixture gains a new
#      commit, and a `fetch` computing `have`s from that local repository
#      gets a smaller pack containing only the new objects -- negotiation
#      doing something, not just refetching everything -- again accepted by
#      real `index-pack`;
#   4. truncated, checksum-flipped, too-short and non-pack bytes are all
#      refused with nothing written to disk, checked directly against
#      `verify_pack` with no server involved (the task's own "simulate this
#      at the test level"); and, for the strongest version of the same
#      claim, a genuinely truncated response over the wire -- a small
#      corrupting proxy in front of the real server, adjusting
#      `Content-Length` to match so it is this module's own checksum check
#      catching it and not `lib/http.m31`'s transport-level framing.

hf_root="$WORK/httpfetch"
mkdir -p "$hf_root"

# --- 1. the source working tree: a real history worth repacking -------------
#
# Eight commits sharing enough content to delta well, a second branch two
# commits back, and an annotated tag -- so `git repack -ad` downstream
# produces genuine `OBJ_*_DELTA` objects, not just whole blobs.

hf_src="$hf_root/src"
mkdir -p "$hf_src"
(
    set -e
    cd "$hf_src"
    git init -q -b main .
    git config user.email httpfetch@example.com
    git config user.name "HTTP Fetch Tester"
    i=1
    while [ "$i" -le 8 ]; do
        printf 'line %d\nshared boilerplate content that repeats across commits\nmore filler text making deltas worthwhile\n' "$i" >>bigfile.txt
        echo "content $i" >"file$i.txt"
        git add -A
        GIT_AUTHOR_DATE="170000000$i +0000" GIT_COMMITTER_DATE="170000000$i +0000" \
            git commit -q -m "commit $i"
        i=$((i + 1))
    done
    git branch feature main~2
    git checkout -q feature
    echo "on the feature branch" >feature.txt
    git add -A
    GIT_AUTHOR_DATE="1700000099 +0000" GIT_COMMITTER_DATE="1700000099 +0000" \
        git commit -q -m "feature commit"
    git checkout -q main
    git tag -a v1.0 -m "release 1.0" main~3
) >"$WORK/httpfetch-src.log" 2>&1 && note "httpfetch: source fixture built (8 commits, a branch, an annotated tag)" ||
    bad "httpfetch source fixture" "$(tail -8 "$WORK/httpfetch-src.log")"

# --- 2. the "server": a bare clone, repacked so the pack it sends has deltas

hf_srv="$hf_root/srv/repo.git"
if git clone -q --bare "$hf_src" "$hf_srv" >"$WORK/httpfetch-bare.log" 2>&1 &&
    git -C "$hf_srv" repack -ad -q >>"$WORK/httpfetch-bare.log" 2>&1 &&
    git -C "$hf_srv" gc -q --prune=now >>"$WORK/httpfetch-bare.log" 2>&1; then
    hf_srv_pack=$(ls "$hf_srv"/objects/pack/*.pack 2>/dev/null | head -1)
    hf_chains=$(git -C "$hf_srv" verify-pack -v "${hf_srv_pack%.pack}.idx" 2>/dev/null | grep -c "^chain length")
    note "httpfetch: server repo repacked ($hf_chains delta chain length(s) present)"
else
    bad "httpfetch server fixture" "$(tail -8 "$WORK/httpfetch-bare.log")"
fi

# --- 3. the real oracle: `git http-backend` as a genuine CGI script ---------

hf_git_exec=$(git --exec-path)
hf_backend="$hf_git_exec/git-http-backend"
hf_web="$hf_root/www"
mkdir -p "$hf_web/cgi-bin"

if command -v python3 >/dev/null 2>&1 && [ -x "$hf_backend" ]; then
    cat >"$hf_web/cgi-bin/git-http-backend" <<WRAP
#!/bin/sh
export GIT_PROJECT_ROOT="$hf_root/srv"
export GIT_HTTP_EXPORT_ALL=1
exec "$hf_backend"
WRAP
    chmod +x "$hf_web/cgi-bin/git-http-backend"

    cat >"$hf_root/serve.py" <<'PY'
import http.server
import os
import sys

port = int(sys.argv[1])
os.chdir(sys.argv[2])


class Handler(http.server.CGIHTTPRequestHandler):
    cgi_directories = ["/cgi-bin"]

    def log_message(self, fmt, *args):
        pass


