# StableForge Launchpad

A decentralized stablecoin factory on Base mainnet that enables users to deploy and manage custom stablecoins with integrated Aave lending and Aerodrome liquidity provision.

## Prerequisites

- GitHub repo with Actions enabled
- Node.js 18+ (for local deployment)
- Hardhat
- Funded deployer account on Base mainnet

## Setup

### GitHub Secrets

Add these secrets in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Description | Example |
|--------|-------------|---------|
| `PK` | Deployer private key (funded on Base) | `0x...` |
| `BASE_RPC` | Base mainnet RPC URL | `https://api.developer.coinbase.com/rpc/v1/base/...` |

Optional:
- `BASESCAN_API_KEY` - For contract verification

### Local Setup

```bash
# Clone repository
git clone https://github.com/coxcelot/stableforgefactory.git
cd stableforgefactory

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Update .env with your values
# PK=your_private_key
# BASE_RPC=your_base_rpc_url
```

## Smart Contracts

### EUSD
Custom stablecoin (ERC20) with mint/burn capabilities (owner only)

### Bootstrapper
Manages launch, collateral, and liquidity provision on Aerodrome

### StableForgeFactory
Main factory that deploys EUSD and Bootstrapper instances

## Key Addresses (Base Mainnet)

| Contract | Address |
|----------|---------|
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Aerodrome Router | `0x6cb442acf35158d5eda88fe602221b67b400be3e` |
| Aave Pool | TBD (update in deploy script) |
| Creator | `0xfbdb59298ea0b9d867897cceddb0de1e2b03909c` |

## License

MIT

## Deployment

### Via GitHub Actions (Automated)

1. **Add secrets** to your GitHub repository:
   - Go to **Settings → Secrets and variables → Actions**
   - Add `PK` (funded Base deployer account)
   - Add `BASE_RPC` (Base mainnet RPC endpoint)

2. **Commit and push** to main branch, or **manually trigger** the workflow:
   - Go to **Actions → Deploy StableForgeFactory**
   - Click **"Run workflow"**

3. **CI/CD pipeline** will:
   - Compile smart contracts
   - Deploy StableForgeFactory to Base mainnet
   - Capture contract address
   - Inject BaseScan link into `frontend/index.html`
   - Upload artifacts

4. **Download artifacts** or host `frontend/index.html` via static server

### Local Deployment

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Deploy to Base mainnet
npx hardhat run scripts/deploy.ts --network base
```

**Note:** Update `AAVE_POOL` address in `scripts/deploy.ts` with the actual Base V3 Pool address before deploying.

## Deployment Script

The `scripts/deploy.ts` script:

1. Deploys **StableForgeFactory** with:
   - Aerodrome Router: `0x6cb442acf35158d5eda88fe602221b67b400be3e`
   - USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
   - Aave Pool: (Update in script)

2. Writes deployment info to `deploy.out`

3. Injects factory address into `frontend/index.html`
   - Replaces `FACTORY_ADDRESS_PLACEHOLDER`
   - Creates clickable BaseScan link

## Verification

After deployment:
- Click the BaseScan link in the Factory card
- Your contract will open on BaseScan explorer
- Verify contract source if desired

## Project Structure

```
├── contracts/
│   ├── EUSD.sol
│   ├── Bootstrapper.sol
│   ├── StableForgeFactory.sol
│   └── interfaces/
│       ├── IAavePool.sol
│       └── IAerodromeRouter.sol
├── scripts/
│   └── deploy.ts
├── frontend/
│   └── index.html
├── .github/
│   └── workflows/
│       └── deploy.yml
├── hardhat.config.ts
├── package.json
└── .env.example
```
