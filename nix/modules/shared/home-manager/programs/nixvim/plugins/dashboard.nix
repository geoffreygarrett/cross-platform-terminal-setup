{
  pkgs,
  lib,
  config,
  ...
}:
{

  programs.nixvim = {
    plugins.dashboard.enable = true;
    #event = "VimEnter";
    extraConfigLua = ''
        require('dashboard').setup {
        theme = 'hyper' --  theme is doom and hyper default is hyper
        -- disable_move    --  default is false disable move keymap for hyper
      --  shortcut_type   --  shorcut type 'letter' or 'number'
      --  shuffle_letter  --  default is true, shortcut 'letter' will be randomize, set to false to have ordered letter.
      --  change_to_vcs_root -- default is false,for open file in hyper mru. it will change to the root of vcs
      --  config = {},    --  config used for theme
      --  hide = {
      --    statusline    -- hide statusline default is true
      --    tabline       -- hide the tabline
      --    winbar        -- hide winbar
      --  },
      --  preview = {
      --    command       -- preview command
      --    file_path     -- preview file path
      --    file_height   -- preview file height
      --    file_width    -- preview file width
      --  },
      }
    '';
  };
}
