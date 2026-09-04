# users/george/home.nix
{ config, lib, pkgs, ... }:
let
  georgeCrownShySignKeyId = "1336EFE416D0D0CF919FF650AFEE9B60134C05E9";
  georgeCrownShyAuthKeygrip= "41D34B4B72809D3A88C301FF891CB4E9EFF19F15";
in
{

  # Required Home Manager state version
  home.stateVersion = "26.05";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    settings."*" = {
      KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256";
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
        email = "george@crown-shy.com";
        name = "George Hulme";
        signingKey = georgeCrownShySignKeyId;
      };
    };
  };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.useGlobalPackages = true;

    extraPackages = with pkgs; [
      lldb
    ];

    plugins = {
      oil.enable = true;
      dap.enable = true;
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
      rustaceanvim.enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<F5>";
        action = "<cmd>lua require('dap').continue()<CR>";
        options.desc = "Debug: Start/Continue";
      }
      {
        mode = "n";
        key = "<F10>";
        action = "<cmd>lua require('dap').step_over()<CR>";
        options.desc = "Debug: Step Over";
      }
      {
        mode = "n";
        key = "<F11>";
        action = "<cmd>lua require('dap').step_into()<CR>";
        options.desc = "Debug: Step Into";
      }
      {
        mode = "n";
        key = "<F12>";
        action = "<cmd>lua require('dap').step_out()<CR>";
        options.desc = "Debug: Step Out";
      }
      {
        mode = "n";
        key = "<Leader>b";
        action = "<cmd>lua require('dap').toggle_breakpoint()<CR>";
        options.desc = "Debug: Toggle Breakpoint";
      }
      {
        mode = "n";
        key = "<Leader>B";
        action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>";
        options.desc = "Debug: Conditional Breakpoint";
      }
      {
        mode = "n";
        key = "<Leader>dr";
        action = "<cmd>lua require('dap').repl.open()<CR>";
        options.desc = "Debug: Open REPL";
      }
      {
        mode = "n";
        key = "<Leader>dl";
        action = "<cmd>lua require('dap').run_last()<CR>";
        options.desc = "Debug: Run Last";
      }
    ];

    extraConfigLua = ''
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "''${port}",
        executable = {
          command = "${pkgs.lldb}/bin/lldb-vscode",
          args = { "--port", "''${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Launch executable",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "''${workspaceFolder}",
          stopOnEntry = false,
        },
      }
    '';

    lsp.servers.nil_ls.enable = true;
    lsp.servers.rust_analyzer.enable = true;
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
