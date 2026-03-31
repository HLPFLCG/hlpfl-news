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
    tradovate_secret?: string;
    tradovate_account_id?: string;
  };
  feeds: Array<{ id: string; on: boolean }>;
  layout: {
    rightPanel: 'always' | 'auto' | 'hidden';
    compactMode: boolean;
    fontSize: 'small' | 'medium' | 'large';
    view: 'columns' | 'stream';
  };
  intervals: {
    priceSeconds: number;
    flashSeconds: number;
    rssMinutes: number;
  };
  account: {
    size: number;
    platform: 'topstep' | 'apex' | 'other';
    pdll: number;
    trailingDD: number;
  };
  alerts: {
    sound: boolean;
    tiers: ('tier1' | 'tier2' | 'tier3')[];
  };
  ui: {
    filter: string;
    focusMode: boolean;
  };
  setup_done?: boolean;
}
EOF

# ========== FEED DEFINITIONS ==========

cat > src/lib/feedDefs.ts << 'EOF'
import { FeedDef } from '@/types/trading';

export const FEED_DEFS: FeedDef[] = [
  { id: 'cnbc-mkt', name: 'CNBC Markets', cat: 'markets', color: '#4fc3f7', on: true, url: 'https://www.cnbc.com/id/20910258/device/rss/rss.html' },
  { id: 'yahoo-fin', name: 'Yahoo Finance', cat: 'markets', color: '#9b59b6', on: true, url: 'https://finance.yahoo.com/news/rssindex' },
  { id: 'mwatch', name: 'MarketWatch', cat: 'markets', color: '#27ae60', on: true, url: 'https://feeds.content.dowjones.io/public/rss/mw_topstories' },
  { id: 'wsj-mkt', name: 'WSJ Markets', cat: 'markets', color: '#2980b9', on: false, url: 'https://feeds.a.dj.com/rss/RSSMarketsMain.xml' },
  { id: 'rtr-biz', name: 'Reuters Business', cat: 'macro', color: '#e8a000', on: true, url: 'https://feeds.reuters.com/reuters/businessNews' },
  { id: 'ap-biz', name: 'AP Business', cat: 'macro', color: '#e67e22', on: true, url: 'https://feeds.apnews.com/rss/apf-business' },
  { id: 'bbc-biz', name: 'BBC Business', cat: 'macro', color: '#bdc3c7', on: true, url: 'https://feeds.bbci.co.uk/news/business/rss.xml' },
  { id: 'fed-news', name: 'Federal Reserve', cat: 'macro', color: '#3498db', on: true, url: 'https://www.federalreserve.gov/feeds/press_all.xml' },
  { id: 'wsj-economy', name: 'WSJ Economy', cat: 'macro', color: '#2980b9', on: true, url: 'https://feeds.a.dj.com/rss/RSSEconomy.xml' },
  { id: 'bis', name: 'BIS Press', cat: 'macro', color: '#2980b9', on: false, url: 'https://www.bis.org/rss/press.rss' },
  { id: 'rtr-world', name: 'Reuters World', cat: 'geo', color: '#e74c3c', on: true, url: 'https://feeds.reuters.com/reuters/worldNews' },
  { id: 'alj', name: 'Al Jazeera', cat: 'geo', color: '#c0392b', on: true, url: 'https://www.aljazeera.com/xml/rss/all.xml' },
  { id: 'bbc-world', name: 'BBC World', cat: 'geo', color: '#9b59b6', on: true, url: 'https://feeds.bbci.co.uk/news/world/rss.xml' },
  { id: 'rtr-energy', name: 'Reuters Energy', cat: 'geo', color: '#e74c3c', on: true, url: 'https://feeds.reuters.com/reuters/energy' },
  { id: 'middle-east', name: 'Middle East Eye', cat: 'geo', color: '#c0392b', on: true, url: 'https://www.middleeasteye.net/rss' },
  { id: 'fxlive', name: 'ForexLive', cat: 'fx', color: '#1abc9c', on: true, url: 'https://www.forexlive.com/feed/news' },
  { id: 'fxstreet', name: 'FXstreet', cat: 'fx', color: '#16a085', on: false, url: 'https://www.fxstreet.com/rss/news' },
  { id: 'dxy-news', name: 'Dollar Strength', cat: 'fx', color: '#1abc9c', on: true, url: 'https://www.dollarcollapse.com/feed/' },
  { id: 'ig-forex', name: 'IG Markets Forex', cat: 'fx', color: '#16a085', on: true, url: 'https://www.ig.com/en/news-and-trade-ideas/forex-news?format=rss' },
  { id: 'kitco', name: 'Kitco Gold', cat: 'commodities', color: '#f1c40f', on: true, url: 'https://www.kitco.com/rss/kitco-news.xml' },
  { id: 'kitco-gold2', name: 'Kitco Gold Analysis', cat: 'commodities', color: '#f1c40f', on: true, url: 'https://www.kitco.com/rss/kitco-news-gold.xml' },
  { id: 'inv-gold', name: 'Investing.com Gold', cat: 'commodities', color: '#d4ac0d', on: true, url: 'https://www.investing.com/rss/news_25.rss' },
  { id: 'oilprice', name: 'OilPrice.com', cat: 'commodities', color: '#e67e22', on: true, url: 'https://oilprice.com/rss/main' },
  { id: 'gold-eagle', name: 'Gold Eagle', cat: 'commodities', color: '#e6b800', on: false, url: 'https://www.gold-eagle.com/feed' },
  { id: 'silverseek', name: 'Silver Seek', cat: 'commodities', color: '#bdc3c7', on: false, url: 'https://silverseek.com/rss.xml' },
  { id: 'zerohedge', name: 'ZeroHedge', cat: 'alt', color: '#7f8c8d', on: false, url: 'https://feeds.feedburner.com/zerohedge/feed' },
  { id: 'seeking', name: 'Seeking Alpha', cat: 'alt', color: '#636e72', on: false, url: 'https://seekingalpha.com/feed.xml' },
];
EOF

# ========== STORAGE UTILITY ==========

cat > src/lib/storage.ts << 'EOF'
import { StorageSchema } from '@/types/trading';

const STORAGE_KEY = 'intelfeed_v2_';

export function loadStorage(): StorageSchema {
  if (typeof window === 'undefined') return getDefaultStorage();
  
  const stored = localStorage.getItem(STORAGE_KEY + 'state');
  return stored ? JSON.parse(stored) : getDefaultStorage();
}

export function saveStorage(state: StorageSchema) {
  if (typeof window === 'undefined') return;
  localStorage.setItem(STORAGE_KEY + 'state', JSON.stringify(state));
}

function getDefaultStorage(): StorageSchema {
  return {
    keys: {
      finnhub: 'd73oe9pr01qjjol3o4igd73oe9pr01qjjol3o4j0',
    },
    feeds: [],
    layout: {
      rightPanel: 'always',
      compactMode: false,
      fontSize: 'medium',
      view: 'columns',
    },
    intervals: {
      priceSeconds: 5,
      flashSeconds: 30,
      rssMinutes: 5,
    },
    account: {
      size: 50000,
      platform: 'topstep',
      pdll: 1500,
      trailingDD: 2250,
    },
    alerts: {
      sound: false,
      tiers: ['tier1', 'tier2'],
    },
    ui: {
      filter: 'all',
      focusMode: false,
    },
    setup_done: false,
  };
}
EOF

# ========== STYLES ==========

cat > src/app/globals.css << 'EOF'
:root {
  --void: #0a0a0a;
  --void-2: #151515;
  --void-3: #1a1a1a;
  --void-4: #242424;
  --gold: #d4af37;
  --gold-muted: #8b7500;
  --cream-1: #f5f1e8;
  --cream-2: #e8e0d0;
  --cream-3: #d4c9bb;
  --red-live: #ff4444;
  --green-up: #00d966;
  --amber: #ffaa00;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  width: 100%;
  height: 100%;
}

body {
  font-family: 'IBM Plex Mono', monospace;
  font-size: 13px;
  background-color: var(--void);
  color: var(--cream-1);
  line-height: 1.4;
  -webkit-font-smoothing: antialiased;
}

#__next {
  width: 100%;
  height: 100%;
}

@keyframes pulse-border {
  0%, 100% { border-color: var(--gold); box-shadow: 0 0 4px var(--gold); }
  50% { border-color: var(--gold-muted); box-shadow: 0 0 2px var(--gold-muted); }
}

.price-pulse { animation: pulse-border 0.3s ease-out; }

@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

.pulse-dot { animation: pulse-dot 1.2s infinite; }

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.blink { animation: blink 0.6s infinite; }

::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: var(--void-2); }
::-webkit-scrollbar-thumb { background: var(--gold-muted); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--gold); }
EOF

# ========== APP LAYOUTS ==========

cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'HLPFL INTEL FEED v2',
  description: 'Professional day trading intelligence dashboard',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=IBM+Plex+Mono:wght@400;500;600&family=Space+Grotesk:wght@400;500;600&display=swap" rel="stylesheet" />
      </head>
      <body>{children}</body>
    </html>
  );
}
EOF

cat > src/app/page.tsx << 'EOF'
import { redirect } from 'next/navigation';

export default function Home() {
  redirect('/trading');
}
EOF

cat > src/app/trading/layout.tsx << 'EOF'
export default function TradingLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
EOF

# ========== PLACEHOLDER COMPONENTS ==========

cat > src/components/trading/AlertBar.tsx << 'EOF'
export default function AlertBar({ events }: any) {
  return <div style={{ background: 'var(--void-2)', padding: '8px', borderBottom: '1px solid var(--gold-muted)' }}>Alert Bar</div>;
}
EOF

cat > src/components/trading/PriceTicker.tsx << 'EOF'
export default function PriceTicker({ tiles }: any) {
  return <div style={{ background: 'var(--void-2)', padding: '12px', display: 'flex', gap: '12px', borderBottom: '1px solid var(--gold-muted)' }}>
    {tiles.map((t: any) => <div key={t.symbol} style={{ color: 'var(--gold)' }}>{t.label}: {t.price}</div>)}
  </div>;
}
EOF

cat > src/components/trading/FilterBar.tsx << 'EOF'
export default function FilterBar({ activeFilter, onFilterChange }: any) {
  const categories = ['all', 'markets', 'macro', 'geo', 'fx', 'commodities', 'alt'];
  return <div style={{ display: 'flex', gap: '8px', padding: '8px', background: 'var(--void-2)', borderBottom: '1px solid var(--gold-muted)' }}>
    {categories.map(cat => <button key={cat} onClick={() => onFilterChange(cat)} style={{ padding: '4px 8px', background: activeFilter === cat ? 'var(--gold)' : 'var(--void-3)', color: activeFilter === cat ? 'var(--void)' : 'var(--gold)' }}>{cat}</button>)}
  </div>;
}
EOF

cat > src/components/trading/StatusBar.tsx << 'EOF'
export default function StatusBar(props: any) {
  return <div style={{ background: 'var(--void-2)', padding: '8px', borderTop: '1px solid var(--gold-muted)', fontSize: '11px', color: 'var(--cream-3)' }}>
    Status Bar • {props.feedCount} feeds • {props.itemCount} items
  </div>;
}
EOF

cat > src/components/trading/MarketFlash.tsx << 'EOF'
export default function MarketFlash({ items }: any) {
  return <div style={{ padding: '12px', borderBottom: '1px solid var(--gold-muted)', maxHeight: '200px', overflow: 'auto' }}>
    <div style={{ color: 'var(--gold)', marginBottom: '8px', fontSize: '12px', fontWeight: 'bold' }}>MARKET FLASH</div>
    {items.slice(0, 5).map((item: any, i: number) => <div key={i} style={{ fontSize: '11px', marginBottom: '4px', color: 'var(--cream-2)' }}>{item.headline?.substring(0, 50)}...</div>)}
  </div>;
}
EOF

cat > src/components/trading/EconomicCalendar.tsx << 'EOF'
export default function EconomicCalendar({ events }: any) {
  return <div style={{ padding: '12px', borderBottom: '1px solid var(--gold-muted)', maxHeight: '200px', overflow: 'auto' }}>
    <div style={{ color: 'var(--gold)', marginBottom: '8px', fontSize: '12px', fontWeight: 'bold' }}>ECONOMIC CALENDAR</div>
    {events?.slice(0, 5).map((e: any, i: number) => <div key={i} style={{ fontSize: '11px', marginBottom: '4px', color: 'var(--cream-2)' }}>{e.event}</div>)}
  </div>;
}
EOF

cat > src/components/trading/RssColumns.tsx << 'EOF'
export default function RssColumns({ feeds, feedResults }: any) {
  return <div style={{ display: 'flex', overflow: 'auto', gap: '1px', background: 'var(--void-3)' }}>
    {feeds.filter((f: any) => f.on).map((feed: any) => <div key={feed.id} style={{ minWidth: '280px', background: 'var(--void-2)', borderRight: '1px solid var(--gold-muted)', padding: '8px', overflow: 'auto', maxHeight: '100%' }}>
      <div style={{ fontSize: '11px', fontWeight: 'bold', color: 'var(--gold)', marginBottom: '8px' }}>{feed.name}</div>
      {feedResults[feed.id]?.items?.slice(0, 10).map((item: any, i: number) => <div key={i} style={{ fontSize: '10px', marginBottom: '6px', padding: '4px', background: 'var(--void-3)', borderLeft: `2px solid ${feed.color}`, paddingLeft: '6px', color: 'var(--cream-3)' }}>{item.title?.substring(0, 40)}...</div>)}
    </div>)}
  </div>;
}
EOF

cat > src/components/trading/SettingsPanel.tsx << 'EOF'
export default function SettingsPanel({ open, onClose }: any) {
  if (!open) return null;
  return <div style={{ position: 'fixed', right: 0, top: 0, bottom: 0, width: '400px', background: 'var(--void-2)', borderLeft: '1px solid var(--gold-muted)', padding: '16px', zIndex: 100, overflow: 'auto' }}>
    <div style={{ color: 'var(--gold)', fontSize: '14px', marginBottom: '16px', fontWeight: 'bold' }}>SETTINGS</div>
    <button onClick={onClose} style={{ padding: '8px 16px', background: 'var(--gold)', color: 'var(--void)', cursor: 'pointer' }}>Close</button>
  </div>;
}
EOF

cat > src/components/trading/SetupModal.tsx << 'EOF'
export default function SetupModal({ onComplete }: any) {
  return <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
    <div style={{ background: 'var(--void-2)', padding: '24px', borderRadius: '4px', maxWidth: '400px', color: 'var(--cream-1)' }}>
      <h2 style={{ color: 'var(--gold)', marginBottom: '16px' }}>Setup INTEL FEED v2</h2>
      <button onClick={() => onComplete({ setup_done: true })} style={{ padding: '8px 16px', background: 'var(--gold)', color: 'var(--void)', cursor: 'pointer' }}>Launch Dashboard</button>
    </div>
  </div>;
}
EOF

cat > src/components/trading/TradovatePanel.tsx << 'EOF'
export default function TradovatePanel({ state, accountState }: any) {
  return <div style={{ padding: '12px', borderTop: '1px solid var(--gold-muted)' }}>
    <div style={{ color: 'var(--gold)', fontSize: '12px', fontWeight: 'bold' }}>TRADOVATE (Optional)</div>
    <div style={{ fontSize: '11px', color: 'var(--cream-3)', marginTop: '8px' }}>Not connected</div>
  </div>;
}
EOF

# ========== HOOKS ==========

cat > src/hooks/usePrices.ts << 'EOF'
import { useState, useEffect } from 'react';
import { PriceTile } from '@/types/trading';

export function usePrices() {
  const [tiles, setTiles] = useState<PriceTile[]>([
    { symbol: 'GC=F', label: 'GOLD', price: 3312, change$: 12, change%: 0.36, session: 'RTH', lastUpdate: Date.now(), contractInfo: { tickValue: 10, pointValue: 100 } },
    { symbol: 'SI=F', label: 'SILVER', price: 33.45, change$: 0.15, change%: 0.45, session: 'RTH', lastUpdate: Date.now(), contractInfo: { tickValue: 5, pointValue: 50 } },
    { symbol: 'ES=F', label: 'ES', price: 5621, change$: 18, change%: 0.32, session: 'RTH', lastUpdate: Date.now(), contractInfo: { tickValue: 12.5, pointValue: 50 } },
    { symbol: 'NQ=F', label: 'NQ', price: 19802, change$: 45, change%: 0.23, session: 'RTH', lastUpdate: Date.now(), contractInfo: { tickValue: 5, pointValue: 20 } },
  ]);

  return { tiles, flashing: [], lastFetch: Date.now(), refreshPrices: () => {} };
}
EOF

cat > src/hooks/useFinnhub.ts << 'EOF'
import { useState } from 'react';
import { NewsItem } from '@/types/trading';

export function useFinnhub(key?: string, interval?: number, sound?: boolean, tiers?: any[]) {
  const [newsItems] = useState<NewsItem[]>([]);
  return { newsItems, lastFetch: Date.now() };
}
EOF

cat > src/hooks/useEconomicCalendar.ts << 'EOF'
import { useState } from 'react';
import { EconomicEvent } from '@/types/trading';

export function useEconomicCalendar(key?: string) {
  const [events] = useState<EconomicEvent[]>([]);
  return { events };
}
EOF

cat > src/hooks/useRssFeeds.ts << 'EOF'
import { useState } from 'react';

export function useRssFeeds(feeds: any[], key?: string, interval?: number) {
  const [feedResults] = useState({});
  return { feedResults, lastFetch: Date.now(), loading: false };
}
EOF

cat > src/hooks/useTradovate.ts << 'EOF'
export function useTradovate(creds: any, pdll?: number, trailingDD?: number) {
  return { state: null, accountState: { dailyPnL: 0 }, error: null };
}
EOF

# ========== API ROUTES ==========

cat > src/app/api/prices/route.ts << 'EOF'
export async function GET(request: Request) {
  return Response.json({ GC: { price: 3312, change$: 12, change%: 0.36 } });
}
EOF

cat > src/app/api/finnhub-news/route.ts << 'EOF'
export async function GET(request: Request) {
  return Response.json({ items: [] });
}
EOF

cat > src/app/api/economic-calendar/route.ts << 'EOF'
export async function GET(request: Request) {
  return Response.json({ events: [] });
}
EOF

cat > src/app/api/rss-proxy/route.ts << 'EOF'
export async function GET(request: Request) {
  return Response.json({ items: [] });
}
EOF

# ========== MAIN TRADING PAGE ==========

cat > src/app/trading/page.tsx << 'EOF'
'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import AlertBar from '@/components/trading/AlertBar';
import PriceTicker from '@/components/trading/PriceTicker';
import FilterBar from '@/components/trading/FilterBar';
import StatusBar from '@/components/trading/StatusBar';
import MarketFlash from '@/components/trading/MarketFlash';
import EconomicCalendar from '@/components/trading/EconomicCalendar';
import RssColumns from '@/components/trading/RssColumns';
import SettingsPanel from '@/components/trading/SettingsPanel';
import SetupModal from '@/components/trading/SetupModal';
import TradovatePanel from '@/components/trading/TradovatePanel';
import { usePrices } from '@/hooks/usePrices';
import { useFinnhub } from '@/hooks/useFinnhub';
import { useEconomicCalendar } from '@/hooks/useEconomicCalendar';
import { useRssFeeds } from '@/hooks/useRssFeeds';
import { useTradovate } from '@/hooks/useTradovate';
import { loadStorage, saveStorage } from '@/lib/storage';
import { FEED_DEFS } from '@/lib/feedDefs';
import { StorageSchema, FeedDef } from '@/types/trading';

export default function TradingPage() {
  const { tiles, flashing, lastFetch, refreshPrices } = usePrices();
  const [storage, setStorage] = useState<StorageSchema>(() => loadStorage());
  const [activeFilter, setActiveFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [focusMode, setFocusMode] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [rightPanelOpen, setRightPanelOpen] = useState(true);
  const { newsItems: flashItems, lastFetch: lastFlashFetch } = useFinnhub(storage.keys.finnhub, storage.intervals.flashSeconds);
  const { events } = useEconomicCalendar(storage.keys.finnhub);

  const feeds: FeedDef[] = FEED_DEFS.map((def) => {
    const override = storage.feeds.find((f) => f.id === def.id);
    return override ? { ...def, on: override.on } : def;
  });

  const { feedResults, lastFetch: lastRssFetch, loading: rssLoading } = useRssFeeds(feeds, storage.keys.rss2json, storage.intervals.rssMinutes);
  const { state: tvState, accountState: tvAccount } = useTradovate({ user: storage.keys.tradovate_user, pass: storage.keys.tradovate_pass }, storage.account.pdll);
  const [debugMode, setDebugMode] = useState(false);
  const mainRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setStorage(loadStorage()); }, []);

  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (e.target instanceof HTMLInputElement) return;
      switch (e.key.toLowerCase()) {
        case 'f': if (!e.ctrlKey && !e.metaKey) setRightPanelOpen((p) => !p); break;
        case 's': if (!e.ctrlKey && !e.metaKey) setSettingsOpen((p) => !p); break;
        case 'd': if (e.ctrlKey || e.metaKey) { e.preventDefault(); setDebugMode((p) => !p); } break;
      }
    }
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, []);

  const handleFilterChange = useCallback((filter: string) => {
    setActiveFilter(filter);
    const updated = { ...storage, ui: { ...storage.ui, filter } };
    setStorage(updated);
    saveStorage(updated);
  }, [storage]);

  const handleUpdateStorage = useCallback((partial: Partial<StorageSchema>) => {
    const updated = { ...storage, ...partial } as StorageSchema;
    if (partial.keys) updated.keys = { ...storage.keys, ...partial.keys };
    if (partial.layout) updated.layout = { ...storage.layout, ...partial.layout };
    setStorage(updated);
    saveStorage(updated);
  }, [storage]);

  const feedCount = feeds.filter((f) => f.on).length;
  const totalItems = Object.values(feedResults).reduce((sum, r) => sum + (r.items?.length || 0), 0);

  return (
    <div style={{ height: '100vh', background: 'var(--void)', overflow: 'hidden', display: 'grid', gridTemplateRows: 'auto auto auto 1fr auto' }}>
      <AlertBar events={events} />
      <PriceTicker tiles={tiles} flashing={flashing} accountTrailingDD={storage.account.trailingDD} accountDailyPnL={tvAccount.dailyPnL} />
      {!focusMode && <FilterBar activeFilter={activeFilter} onFilterChange={handleFilterChange} searchQuery={searchQuery} onSearchChange={setSearchQuery} />}
      <div ref={mainRef} style={{ display: 'grid', gridTemplateColumns: rightPanelOpen ? '1fr 295px' : '1fr', overflow: 'hidden', minHeight: 0 }}>
        {!focusMode && <RssColumns feeds={feeds} feedResults={feedResults} loading={rssLoading} searchQuery={searchQuery} activeFilter={activeFilter} view={storage.layout.view} />}
        {rightPanelOpen && (
          <div style={{ borderLeft: '0.5px solid var(--gold-muted)', background: 'var(--void-2)', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
            <MarketFlash items={flashItems} onOpenSettings={() => setSettingsOpen(true)} finnhubKey={storage.keys.finnhub} />
            <div style={{ height: '1px', background: 'var(--void-4)' }} />
            <EconomicCalendar events={events} finnhubKey={storage.keys.finnhub} onOpenSettings={() => setSettingsOpen(true)} />
            <TradovatePanel state={tvState} accountState={tvAccount} error={null} />
          </div>
        )}
      </div>
      {!focusMode && <StatusBar lastPriceFetch={lastFetch} lastFlashFetch={lastFlashFetch} lastRssFetch={lastRssFetch} feedCount={feedCount} itemCount={totalItems + flashItems.length} priceIntervalSec={storage.intervals.priceSeconds} flashIntervalSec={storage.intervals.flashSeconds} rssIntervalMin={storage.intervals.rssMinutes} />}
      <button onClick={() => setFocusMode((p) => !p)} style={{ position: 'fixed', top: '8px', right: '8px', zIndex: 50, padding: '6px 12px', background: focusMode ? 'var(--gold)' : 'var(--void-3)', color: focusMode ? 'var(--void)' : 'var(--gold)', border: '1px solid var(--gold-muted)', borderRadius: '2px', cursor: 'pointer', fontSize: '11px' }}>
        FOCUS
      </button>
      {!storage.setup_done && <SetupModal onComplete={(updates) => handleUpdateStorage({ ...updates, setup_done: true })} />}
      <SettingsPanel open={settingsOpen} onClose={() => setSettingsOpen(false)} storage={storage} onUpdate={handleUpdateStorage} feeds={feeds} />
      {debugMode && (
        <div style={{ position: 'fixed', bottom: '0', left: '0', right: '0', zIndex: 50, padding: '12px', background: 'rgba(10,10,10,0.95)', borderTop: '1px solid var(--gold)', color: 'var(--cream-3)', height: '150px', overflowY: 'auto', fontSize: '11px' }}>
          <div style={{ color: 'var(--gold)' }}>DEBUG (Ctrl+D)</div>
          <div>Prices: {tiles.map(t => t.label + '=' + t.price).join(' | ')}</div>
          <div>Filter: {activeFilter}</div>
          <div>Setup done: {String(storage.setup_done)}</div>
        </div>
      )}
    </div>
  );
}
EOF

echo "✅ INTEL FEED v2 files created successfully!"
echo ""
echo "📦 Running: npm install"
npm install

echo ""
echo "✨ Setup complete!"
echo ""
echo "🚀 Start development server:"
echo "   npm run dev"
echo ""
echo "🌐 Open: http://localhost:3000"
echo ""
echo "⌨️  Shortcuts: F (Flash), S (Settings), Ctrl+D (Debug)"
