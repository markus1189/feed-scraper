{ pkgs ? import <nixpkgs> { } }:

let
  redditGit = pkgs.writeShellScriptBin "reddit-git" ''
    set -ex

    TEMP_DIR="$(mktemp -d -p . tmp.XXXXXXXXXX)"

    if [[ -f feeds/reddit/git.xml ]]; then
      xq . feeds/reddit/git.xml > $TEMP_DIR/reddit-git-old.json
    fi

    curl -H 'User-Agent: Mozilla/5.0 (Linux; Android 8.0.0; SM-G960F Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.84 Mobile Safari/537.36' -s 'https://www.reddit.com/r/git.rss' | xq -x . > $TEMP_DIR/reddit-git-new.xml

    if [[ -f feeds/reddit/git.xml ]]; then
      xq -x --slurpfile old $TEMP_DIR/reddit-git-old.json '.feed.entry |= ($old[0].feed.entry + . | unique)' $TEMP_DIR/reddit-git-new.xml > feeds/reddit/git.xml
    else
      cp -v $TEMP_DIR/reddit-git-new.xml feeds/reddit/git.xml
    fi

  '';

  commitAndPush = pkgs.writeShellScriptBin "commit-and-push" ''
    git config user.name "Bot"
    git config user.email "bot@github.com"
    git add -A
    timestamp=$(date -u --iso-8601=s)
    git commit -m "Update on ''${timestamp}" || exit 0
    git push
  '';
in pkgs.mkShell {
  nativeBuildInputs = with pkgs;
    [ git curl jq yq pup cacert coreutils bash ] ++ [ redditGit commitAndPush ];
}
