#!/bin/bash
# INTEL FEED v2 Complete Setup Script
# Run: chmod +x setup-intel-feed.sh && ./setup-intel-feed.sh

set -e

echo "🚀 Setting up INTEL FEED v2 Dashboard..."

# Create directories
mkdir -p src/app/trading
mkdir -p src/components/trading
mkdir -p src/hooks
mkdir -p src/lib
mkdir -p src/types
mkdir -p src/app/api/{prices,finnhub-news,economic-calendar,rss-proxy}
mkdir -p public

# ========== CONFIGURATION FILES ==========

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  compress: true,
};
module.exports = nextConfig;
EOF

cat > .gitignore << 'EOF'
node_modules
.next
.env.local
.env.*.local
*.log
.DS_Store
dist
build
.vercel
EOF

# ========== TYPE DEFINITIONS ==========

cat > src/types/trading.ts << 'EOF'
export interface FeedDef {
  id: string;
  name: string;
  cat: 'markets' | 'macro' | 'geo' | 'fx' | 'commodities' | 'alt';
  color: string;
  on: boolean;
  url: string;
}

export interface PriceTile {
  symbol: string;
  label: string;
  price: number;
  change$: number;
  change%: number;
  session: 'RTH' | 'ETH' | 'CLOSED';
  lastUpdate: number;
  contractInfo: {
    tickValue: number;
    pointValue: number;
  };
}

export interface NewsItem {
  id: string;
  headline: string;
  source: string;
  url: string;
  image?: string;
  summary?: string;
  datetime: number;
  category?: string;
}

export interface EconomicEvent {
  id: string;
  event: string;
  country?: string;
  impact: 'HIGH' | 'MEDIUM' | 'LOW';
  forecast?: string;
  previous?: string;
  actual?: string;
  releaseDateTime: number;
}

export interface StorageSchema {
  keys: {
    finnhub?: string;
    rss2json?: string;
    tradovate_user?: string;
    tradovate_pass?: string;
    tradovate_cid?: string;
    tradovate_did?: string;
    tradovate_secret*

