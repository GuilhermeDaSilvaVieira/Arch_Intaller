# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

{
  imports = [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # (__getFlake "github:fortuneteller2k/nixpkgs-f2k").nixosModules.stevenblack
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (__getFlake "github:fortuneteller2k/nixpkgs-f2k").overlays.default
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the Grub EFI boot loader.
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  networking = {
    hostName = "nixos"; # Define your hostname.
    networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  };

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8"; # Don't change

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    # LC_MESSAGES = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      extraRules = [{
	groups = [ "wheel" ];
	keepEnv = true;
	persist = true;  
      }];
    };
  };

  # Enable sound.
  sound.enable = true;

  hardware = {
    bluetooth.enable = true;
    pulseaudio.enable = true;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
    };
  };

  services = {
    # Enable the X11 windowing system.
    xserver = {
	enable = true;
	layout = "br";
	xkbVariant = "";
	excludePackages = with pkgs; [ xterm ];
	videoDrivers = ["nvidia"];
	displayManager.startx.enable = true;
	windowManager.awesome.enable = true;
    };
    # Enable CUPS to print documents.
    printing = {
      enable = true;
      drivers = with pkgs; [ epson-escpr ];
      browsing = true;
      defaultShared = true;
    };
    # Enable networking to print documents.
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
    # Enable the OpenSSH daemon.
    openssh.enable = true;
    # Enable Udisks2 for mounting
    udisks2.enable = true;
  };

  # Enable fonts
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      nerdfonts
      noto-fonts
      noto-fonts-emoji
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users = {
      work = {
	isNormalUser = true;
	extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
	packages = with pkgs; [ ];
      };
      fun = {
	isNormalUser = true;
	extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
	packages = with pkgs; [
	  ani-cli
	  mangal
	  mangohud
	  yuzu-mainline
	  cemu
	  zsnes2
	];
      };
    };
  };
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    shells = with pkgs; [ fish ];
    defaultPackages = with pkgs; [];
    systemPackages = with pkgs; [
      (__getFlake "github:fortuneteller2k/nixpkgs-f2k").packages.${system}.awesome-git
	picom
	virt-manager
	btop
	bat
	yt-dlp
	lazygit
	tokei
	stylua
	feh
	tree
	p7zip
	cava
	xclip
	cinnamon.warpinator
	maim
	neovim
	neofetch
	exa
	kitty
	lxappearance
	librewolf
	git
	fzf
	fd
	ripgrep
	zathura
	lf
	mpv
	thunderbird
	lld 
	gcc 
	glibc 
	clang 
	llvmPackages.bintools
	wget
	procps
	killall
	zip
	unzip
	lua
	starship
	rustup
	redshift
	btop
	pavucontrol
	ffmpeg
	transmission-gtk
	qemu
	];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs = {
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    dconf.enable = true;
  };

  # Laptop Options
  # powerManagement.cpuFreqGovernor = "performance";
  # services.xserver.libinput.enable = true; # Enable touchpad support

  system = {
    copySystemConfiguration = true;
    stateVersion = "23.05";
  };
}
