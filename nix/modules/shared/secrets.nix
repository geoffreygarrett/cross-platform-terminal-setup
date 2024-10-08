{
  self,
  config,
  pkgs,
  user,
  ...
}:
{
  sops = {
    # Define the default options for all secrets
    defaultSopsFile = "${self}/secrets/default.yaml";
    age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    # Permission modes are in octal representation (same as chmod),
    # the digits represent: user|group|others
    # 7 - full (rwx)
    # 6 - read and write (rw-)
    # 5 - read and execute (r-x)
    # 4 - read only (r--)
    # 3 - write and execute (-wx)
    # 2 - write only (-w-)
    # 1 - execute only (--x)
    # 0 - none (---)
    secrets = {
      "github-token" = {
        mode = "0400"; # read permission for owner only
        key = "github-token";
      };

      "openai-api-key" = {
        mode = "0400"; # read permission for owner only
        key = "openai-api-key";
      };

      "cachix-auth-token" = {
        mode = "0400"; # read permission for owner only
        key = "cachix-auth-token-value";
      };

      "tailscale-auth-key" = {
        mode = "0400"; # read permission for owner only
        key = "tailscale-auth-key-value";
      };
    };
  };
}
