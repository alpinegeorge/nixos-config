# users/george/home.nix
{ config, lib, pkgs, ... }:
let
  georgeCrownShySignKeyId = "1336EFE416D0D0CF919FF650AFEE9B60134C05E9";
  georgePersonalSignKeyId = "56A3297ED2D7B65CFB4B8EAF169BF57B0372A57C";
  georgeCrownShyAuthKeygrip= "41D34B4B72809D3A88C301FF891CB4E9EFF19F15";
in
{

  # Required Home Manager state version
  home.stateVersion = "26.05";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    settings = {
      "*" = {
        KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256";
      };

      "github-hobby" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_hobby";
          IdentitiesOnly = "yes";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      commit.gpgsign = true;
      core = {
        editor = "nvim";
        sshCommand = "ssh -o IdentityAgent=\${SSH_AUTH_SOCK}";
      };
      gpg.format = "openpgp";
      safe.directory = [
        "/etc/nixos"
      ];
      tag.gpgsign = true;
      user = {
        name = "George Hulme";
        email = "george@crown-shy.com";
        signingKey = georgeCrownShySignKeyId;
      };
    };

    includes = [
    {
        condition = "gitdir:~/Projects/Personal/";
        contents = {
          user = {
            email = "georgehulme2@gmail.com";
            signingKey = georgePersonalSignKeyId;
          };
        };
      }
    ];
  };

  programs.gpg = {
    enable = true;

    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  programs.nixvim = {
    enable = true;

    nixpkgs.source = pkgs.path;

    extraPackages = with pkgs; [
      stylua
      prettier
      ripgrep
      lua-language-server
      rust-analyzer
      cargo
      typescript
    ];

    globals = {
      mapleader = " ";
      netrw_liststyle = 3;
      netrw_banner = 0;
      netrw_winsize = 25;
      netrw_browse_split = 0;
      netrw_altfile = 1;
    };

    opts = {
      number = true;
      relativenumber = true;
      tabstop = 2;
      softtabstop = 2;
      signcolumn = "yes";
      undofile = true;
      autoread = true;
      laststatus = 3;
      cmdheight = 0;
      grepprg = "rg --vimgrep --smart-case --hidden";
      grepformat = "%f:%l:%c:%m";
    };

    colorschemes.catppuccin = {
      enable = true;
      settings.transparent_background = true;
    };

    keymaps = [
      { mode = "n"; key = "<leader>w"; action = "<cmd>w<CR>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>q"; action = "<cmd>q<CR>"; options = { silent = true; }; }
      { mode = "n"; key = "U"; action = "<c-r>"; options = { silent = true; }; }
      { mode = "n"; key = "<C-h>"; action = "<cmd>wincmd h<CR>"; options = { silent = true; desc = "Move to left split"; }; }
      { mode = "n"; key = "<C-j>"; action = "<cmd>wincmd j<CR>"; options = { silent = true; desc = "Move to below split"; }; }
      { mode = "n"; key = "<C-k>"; action = "<cmd>wincmd k<CR>"; options = { silent = true; desc = "Move to above split"; }; }
      { mode = "n"; key = "<C-l>"; action = "<cmd>wincmd l<CR>"; options = { silent = true; desc = "Move to right split"; }; }
      { mode = "n"; key = "<leader>e"; action = "<cmd>Lexplore<CR>"; options = { silent = true; }; }
      { mode = "n"; key = "<leader>d"; action = "<cmd>lua vim.diagnostic.setqflist()<CR><cmd>copen<CR>"; options = { silent = true; }; }
    ];

    extraFiles = {
      "lsp/lua_ls.lua".source = ./nvim/lsp/lua_ls.lua;
      "lsp/rust_analyzer.lua".source = ./nvim/lsp/rust_analyzer.lua;
      "lsp/tsc.lua".source = ./nvim/lsp/tsc.lua;
    };

    extraConfigLua = ''
      -- Autocommands
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
        pattern = "*",
        desc = "highlight selection on yank",
        callback = function()
          vim.highlight.on_yank({ timeout = 200, visual = true })
        end,
      })

      vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(args)
          local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
          local line_count = vim.api.nvim_buf_line_count(args.buf)
          if mark[1] > 0 and mark[1] <= line_count then
            vim.api.nvim_win_set_cursor(0, mark)
            vim.schedule(function()
              vim.cmd("normal! zz")
            end)
          end
        end,
      })

      -- Netrw hacks
      vim.api.nvim_create_autocmd("WinEnter", {
        pattern = "*",
        callback = function()
          vim.schedule(function()
            if vim.bo.filetype == "netrw" and vim.fn.winnr("$") == 1 then
              vim.cmd("vertical rightbelow new")
              vim.cmd("wincmd p")
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "netrw",
        callback = function()
          -- [Paste your custom netrw '%' keymap override here]
        end,
      })

      -- Statusline
      local pms = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
      local dir = vim.api.nvim_get_hl(0, { name = "Directory", link = false })
      local vis = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
      vim.api.nvim_set_hl(0, "StlMode", { fg = pms.fg, bg = vis.bg })
      vim.api.nvim_set_hl(0, "StlGit", { fg = dir.fg, bg = pms.bg })

      local modes = { n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK", c = "COMMAND", t = "TERMINAL", R = "REPLACE", s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK" }

      function _G._statusline()
        local mode = modes[vim.fn.mode()] or vim.fn.mode():upper()
        local branch = vim.b.git_branch and "%#StlGit# " .. vim.b.git_branch .. " %*" or ""
        local path = vim.b.rel_path or "%f"
        local diag = ""
        local counts = vim.diagnostic.count(0) or {}
        local labels = { " ", " ", " ", " " }
        local hls = { "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint" }
        for i = 1, 4 do
          if counts[i] and counts[i] > 0 then
            diag = diag .. "%#" .. hls[i] .. "#" .. labels[i] .. counts[i] .. "%* "
          end
        end
        return "%#StlMode# " .. mode .. " %*" .. branch .. " " .. path .. "%=" .. diag .. vim.bo.filetype .. " %l:%c"
      end

      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+$", "")
          if root ~= "" then
            vim.b.git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("%s+$", "")
            vim.b.rel_path = vim.fn.expand("%:p"):sub(#root + 2)
          else
            vim.b.git_branch = nil
            vim.b.rel_path = vim.fn.expand("%:p:~")
          end
        end,
      })

      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function() vim.cmd("redrawstatus!") end,
      })
      vim.o.statusline = "%!v:lua._statusline()"

      -- Find & Grep functions
      -- [Paste your ignore_patterns, native_find, and formatters table here]
      vim.keymap.set("n", "<leader>f", ":find ", { silent = false })
      vim.keymap.set("n", "<leader>g", function()
        vim.ui.input({ prompt = "Grep: " }, function(pattern)
          if pattern then
            vim.cmd("silent grep! " .. vim.fn.fnameescape(pattern))
            vim.cmd("copen")
          end
        end)
      end, { silent = true })

      -- LSP Initialization
      vim.lsp.enable({ "lua_ls", "tsgo" })
      vim.diagnostic.config({ virtual_text = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client ~= nil and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
          end
        end,
      })
      vim.cmd("set completeopt+=noselect")
    '';
  };

  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    enableSshSupport = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };

  home = {
    activation = {
      importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        GPG="${pkgs.gnupg}/bin/gpg"
        KEY_ID="${georgeCrownShySignKeyId}"

        # Fetch key if not present in user keyring
        if ! $GPG --list-keys "$KEY_ID" >/dev/null 2>&1; then
          $GPG --keyserver hkps://keys.openpgp.org --recv-keys "$KEY_ID"
        fi

        # Set ultimate trust for signature signing
        echo "$KEY_ID:6:" | $GPG --import-ownertrust
      '';
    };

    file = {
      ".bashrc".text = ''
        # Source profile
        . "$HOME/.profile"
      '';

      ".cargo/config.toml".text = ''
        [build]
        rustc-wrapper = "sccache"

        [target.x86_64-unknown-linux-gnu]
        linker = "/usr/bin/clang"
        rustflags = ["-C", "link-arg=-fuse-ld=/usr/bin/mold"]
      '';

      ".gnupg/sshcontrol".text = ''
        ${georgeCrownShyAuthKeygrip}
      '';

      ".profile".text = ''
        # Setup direnv
        ## Run direnv shell hook
        eval "$(direnv hook bash)"

        ## Setup SSH auth via OpenPGP
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

        ## Set direnv timeout warning to 2 minutes (default=20s)
        export DIRENV_WARN_TIMEOUT=2m

        # Setup sccache
        ## Set cache size
        export SCCACHE_CACHE_SIZE="5G"

        ## Set cache directory
        export SCCACHE_DIR="$HOME/.sccache/"

        # Setup editor env
        export EDITOR="nvim"
        export FCEDIT="$EDITOR"
      '';
    };
  };
}
