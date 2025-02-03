{
  description = "elixir-phoenix-project";

  inputs = {
    # Using stable Nixpkgs as base
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    # Include unstable for latest Elixir/Erlang versions if needed
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake utils for easier multi-platform support
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        # Use unstable channel for latest Elixir
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir and Erlang
            unstable.elixir
            unstable.erlang

            # Build tools
            gcc
            gnumake

            # Phoenix dependencies
            nodejs_20
            postgresql
            inotify-tools # For file_system on Linux

            # Development tools
            direnv
            git
          ];

          shellHook = ''
            # Load environment variables from .env file
            if [ -f .env ]; then
              source .env
            fi

            # Add local mix and hex to PATH
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            # Initialize mix if not already done
            if [ ! -d $HEX_HOME ]; then
              mix local.hex --force
              mix local.rebar --force
              mix archive.install hex phx_new --force
            fi

            echo "Elixir/Phoenix development environment ready!"
            echo "Run 'mix phx.new your_app_name' to create a new Phoenix application"
          '';
        };

        # Formatter configuration
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
