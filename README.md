# IaC Bootstrap

Minimal bootstrap utility to provision a fresh Linux server and securely connect it to the private Infrastructure-as-Code (IaC) repository.

This repository is intentionally small and stable.

## Installation

### Download a specific version

Always pin a version tag to ensure reproducibility.

```
curl -fsSL https://raw.githubusercontent.com/Tom-Pinnecker/iac-bootstrap/refs/heads/main/install.sh | sh
```

### Review the script

⚠️ Always review scripts before executing them on production systems.

```
less install.sh
```

### Execute

```
chmod +x install.sh
sudo ./install.sh
```

### What Happens During Installation

The script will:

1. Install required system packages (e.g., git)
2. Generate a new SSH key pair (ed25519)
3. Display the public key

## Versioning

This project follows Semantic Versioning:

```
vMAJOR.MINOR.PATCH
```

- MAJOR → Breaking bootstrap changes
- MINOR → Backwards-compatible improvements
- PATCH → Bug fixes

## License

This project is licensed under the MIT License - see the LICENSE file for details.
