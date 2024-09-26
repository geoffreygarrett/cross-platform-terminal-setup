{ lib, ... }:
{
  options.nixus = {
    useNerdFonts = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = lib.mdDoc "Use Nerd Fonts icons instead of emojis for formatting output.";
    };
  };
}
