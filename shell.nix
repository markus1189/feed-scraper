{ pkgs ? import <nixpkgs> { } }:

let
  scrapeSubreddit = pkgs.writeShellScriptBin "scrape-subreddit" (pkgs.lib.readFile ./scripts/scrape-subreddit.sh);

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
    [ git curl jq yq pup cacert coreutils bash ] ++ [ scrapeSubreddit commitAndPush ];
}
