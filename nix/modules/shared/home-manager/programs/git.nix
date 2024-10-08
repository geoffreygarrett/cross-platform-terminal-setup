{
  config,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "geoffreygarrett";
    userEmail = "26066340+geoffreygarrett@users.noreply.github.com";
    aliases = {
      undo = "reset HEAD~1 --mixed";
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      use-ssh = "remote set-url origin $(git remote get-url origin | sed -E 's#^https?://([^/]+)/(.+)$#git@\1:\2#')";
      use-https = "remote set-url origin $(git remote get-url origin | sed -E 's#^git@([^:]+):(.+)$#https://\1/\2#')";
    };
    extraConfig = {
      init.defaultBranch = "main";
      color = {
        ui = "auto";
      };
      push = {
        default = "simple";
      };
      fetch = {
        prune = true;
      };
      pull = {
        rebase = true;
      };
    };
  };
}
